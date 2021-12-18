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

""" Main APB Test Base used as base class for all the other tests"""

#######################################################################################
## Import Files
#######################################################################################
from pyuvm import *
import random
import cocotb
import sys
import pyuvm_apb_global_defines_params as param_file
import pyuvm_apb_env as env
import pyvum_apb_sequence as seq
## Include the Autoreg output files the path insert works the same way as include works
sys.path.insert(1,"/Volumes/My_Data/MY_SYSTEMVERILOG_UVM_PROJECTS/APB_PROTOCOL/APB_SLAVE/Apb_Reggen/output_all")
import apb_reg_python_const as reg_const

## Main Test Class
class apb_base_test(uvm_test):
    """ APB Main Base Test Class """
    def build_phase(self):
        self.apb_environment    = env.apb_env.create("env", self)
        self.apb_first_seq      = seq.apb_sequence.create("apb_first_seq")
        ## Set the randomize item to false t avoid additional randomization
        self.apb_first_seq.randomize_items  = False
        ## Set the do_not_print to true in order to not print the item fields
        self.apb_first_seq.do_not_print     = False  

    async def run_phase(self):
        self.raise_objection()
        for at in range(reg_const.memory_adress_start,reg_const.memory_adress_end,4):
            self.apb_first_seq.apb_trx.address = at
            self.apb_first_seq.apb_trx.cmd     = param_file.apb_cmd_t.WRITE
            self.apb_first_seq.apb_trx.data_wr = at
            await self.apb_first_seq.start(self.apb_environment.apb_sequencer)
            self.apb_first_seq.apb_trx.address = at
            self.apb_first_seq.apb_trx.cmd     = param_file.apb_cmd_t.READ
            await self.apb_first_seq.start(self.apb_environment.apb_sequencer)
            if self.apb_first_seq.data_rd != at:
                uvm_root().logger.error("Value read {} and written {} at address {} are different".format(hex(elf.apb_first_seq.data_rd),hex(at),hex(at)))
        self.drop_objection()