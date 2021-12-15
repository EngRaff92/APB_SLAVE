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

""" Main Sequence Item used to send any TRX to the APB"""

#######################################################################################
## Import Files
#######################################################################################
from pyuvm import *
import random
import cocotb
import sys
import pyuvm_apb_global_defines_params as param_file

## Main Class
class apb_seq_item(uvm_sequence_item):
    """ Apb Sequence Item """
    def __init__(self,name):
        super().__init__(name)
        self.item_name      = name
        self.address        = 0
        self.data_wr        = 0
        self.access_part    = param_file.access_t
        self.cmd            = param_file.apb_cmd_t
        self.resp           = param_file.apb_resp_t
        self.data_rd        = 0

    def randomize(self):
        self.access_part    = random.choice(list(param_file.access_t))
        self.cmd            = random.choice(list(param_file.apb_cmd_t))
        self.address        = random.randint(0,10)
        self.data_wr        = random.randint(0,10)
        self.post_randomize()

    def post_randomize(self):
        self.apb_item_print()

    def apb_item_print(self):
        uvm_root().logger.info("Printing General APB Item Content")
        uvm_root().logger.info("Print TRX -> Name           : {}".format(self.item_name))
        uvm_root().logger.info("Print TRX -> Address        : {}".format(hex(self.address)))
        uvm_root().logger.info("Print TRX -> Data Write     : {}".format(hex(self.data_wr)))
        uvm_root().logger.info("Print TRX -> Access Part    : {}".format(self.access_part.name))
        uvm_root().logger.info("Print TRX -> CMD type       : {}".format(self.cmd.name))

    def apb_item_print_on_read(self):
        uvm_root().logger.info("Print TRX -> Read_data : {}".format(hex(self.data_rd)))
        if self.resp == param_file.apb_resp_t.APB_ERR:
            uvm_root().logger.info("Print TRX -> Response  : {}".format(self.resp.APB_ERR.name))
        else:
            uvm_root().logger.info("Print TRX -> Response  : {}".format(self.resp.APB_OK.name))

    def do_copy(self):
        self._t             = apb_item("copied_item")
        self._t.address     = self.address  
        self._t.data_wr     = self.data_wr    
        self._t.access_part = self.access_part
        self._t.cmd         = self.cmd        
        self._t.data_rd     = self.data_rd    
        self._t.resp        = self.resp
        return _t