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

""" Main Sequence used to create and send any TRX to the APB Driver"""

#######################################################################################
## Import Files
#######################################################################################
from pyuvm import *
import random
import cocotb
import sys
import pyuvm_apb_global_defines_params as param_file
import pyuvm_apb_seq_item as item

## Main Class
class apb_sequence(uvm_sequence):
    """ Apb Sequence """   
    def __init__(self,name,randomize_items):
        self.randomize_items    = randomize_items
        self.sequence_name      = name
        self.sequence_id        = 0

    async def body(self):
        self.apb_trx = item.apb_seq_item("Apb_Trx")
        await self.start_item(self.apb_trx)
        if self.randomize_items == True:
            self.apb_trx.randomize()
        await self.finish_item(self.apb_trx)
        if self.apb_trx.cmd == param_file.apb_cmd_t.WRITE:
            self.data_rd = self.apb_trx.data_rd
        else:
            self.data_rd = 0