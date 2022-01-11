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
import pyuvm_apb_global_defines_params as param_file

# Main Class
class apb_scoreboard(uvm_component):
    """ Apb Scoreboard """
    def build_phase(self):
        self.apb_fifo           = uvm_tlm_analysis_fifo("apb_fifo", self)
        self.apb_fifo_export    = self.apb_fifo.analysis_export
        self.get_port           = uvm_get_port("get_port", self)

    ## Connect phase used to connect the analysis export to the blocking get port
    def connect_phase(self):
        self.get_port.connect(self.apb_fifo.get_export)

    async def run_phase(self):
        while True:
            self.apb_trx = await self.get_port.get()
            uvm_root().logger.debug("APB Scoreboard item ready")
            self.raise_objection()
            ## Compare and check
            self.apb_trx_checker(self.apb_trx)
            self.drop_objection()

    def apb_trx_checker(self,input_trx):
        uvm_root().logger.debug("Starting APB Scoreboard checking")

    def check_phase(self):
        if self.apb_fifo.is_empty():
            uvm_root().logger.info("Finish checking with no remaining TRX in the FIFO queue")
        else:
            uvm_root().logger.error("Finish checking with {} remaining TRX in the FIFO queue".format(self.apb_fifo.size()))            