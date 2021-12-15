#
# Icebreaker and IceSugar RSMB5 project - RV32I for Lattice iCE40
# With complete open-source toolchain flow using:
# -> yosys 
# -> icarus verilog
# -> icestorm project
#
# Tests are written in several languages
# -> Systemverilog Pure Testbench (Vivado)
# -> UVM testbench (Vivado)
# -> PyUvm (Icarus)
# -> Formal either using SVA and PSL (Vivado) or cuncurrent assertions with Yosys
#
# Copyright (c) 2021 Raffaele Signoriello (raff.signoriello92@gmail.com)
#
# Permission is hereby granted, free of charge, to any person obtaining a 
# copy of this software and associated documentation files (the "Software"), 
# to deal in the Software without restriction, including without limitation 
# the rights to use, copy, modify, merge, publish, distribute, sublicense, 
# and/or sell copies of the Software, and to permit persons to whom the 
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included 
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

""" Main APB Driver used to send stimulus over the interface"""

#######################################################################################
## Import Files
#######################################################################################
from pyuvm import *
import random
import cocotb
import sys
import pyuvm_apb_global_defines_params as param_file

## Main Class
class apb_driver(uvm_driver):
    """ Apb Driver """
    def build_phase(self):
        self.driver_to_monitor_ap = uvm_analysis_port("driver_to_monitor_ap", self)

    def start_of_simulation_phase(self):
        self.apb_if = ConfigDB().get(self, "", "apb_if")

    async def wait_for_reset_done(self):
        await self.apb_if.wait_for_reset()

    async def run_phase(self):
        await self.wait_for_reset_done()
        while True:
            self.apb_trx = await self.seq_item_port.get_next_item()
            self.raise_objection()
            ## Select according to the command used
            if self.apb_trx.cmd.value == param_file.apb_cmd_t.WRITE:
                await self.apb_if.apb_wr(apb_trx.address, apb_trx.data_wr)
            else:
                self.data_out = await self.apb_if.apb_rd(apb_trx.address)
            self.seq_item_port.item_done()
            self.drop_objection()