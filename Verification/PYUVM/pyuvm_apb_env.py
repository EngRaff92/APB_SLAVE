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

""" Main APB Environment connection and creation of UVM components """

#######################################################################################
## Import Files
#######################################################################################
from pyuvm import *
import random
import cocotb
import sys
import pyuvm_apb_global_defines_params as param_file
import pyuvm_apb_driver as driver
import pyuvm_apb_scoreboard as scbd

## Main Class
class apb_env(uvm_env):
    """ Apb Environment """
    def build_phase(self):
        ## Declaration of Main Components and Creation
        self.apb_sequencer  = uvm_sequencer.create("apb_sequencer", self)
        self.apb_driver     = driver.apb_driver.create("apb_driver", self)
        self.apb_score      = scbd.apb_scoreboard.create("apb_score",self)

    def connect_phase(self):
        self.apb_driver.seq_item_port.connect(self.apb_sequencer.seq_item_export)
        self.apb_driver.driver_to_scoreboard_ap.connect(self.apb_score.apb_fifo_export)