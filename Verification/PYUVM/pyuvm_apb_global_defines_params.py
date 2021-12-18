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
##

""" This is a list of Enumerations and Parameters used across the Testbench """

########################################################################################################
## Import Modules
########################################################################################################
from enum import Enum, unique

########################################################################################################
## Defines and Parameters for Testbench
########################################################################################################

## Parameters
REG_WIDTH = 32

########################################################################################################
## Macros and Types
########################################################################################################

##
@unique
class policy_t(Enum):
    WO  = 0
    RO  = 1
    RW  = 2
    WOC = 3
    ROC = 4

##
@unique
class access_t(Enum):
    RIF  = 0
    MEM  = 1

##
@unique
class mem_reset_t(Enum):
    ZERO    = 0
    RANDOM  = 1
    ONES    = 2
    IMAGE   = 3

##
@unique
class memory_type_t(Enum):
    PROG  = 0
    OTP   = 1

##
@unique
class apb_cmd_t(Enum):
    WRITE  = 0
    READ   = 1

##
@unique
class apb_resp_t(Enum):
    APB_OK  = 0
    APB_ERR = 1

##
@unique
class debug_print_t(Enum):
    LOW     = 0
    HIGH    = 1
    DEBUG   = 2

## 
@unique
class severity_print_t(Enum):
    INFO    = 0
    ERROR   = 1
    FATAL   = 2