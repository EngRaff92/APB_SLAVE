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

###############################################################################
# Hardware
###############################################################################
CURRENT_DIR 			= $(shell pwd)
COCOTB_REDUCED_LOG_FMT 	= True
SIM 					?= icarus
#VERILOG_SOURCES 		= $(wildcard ./*.sv)
VERILOG_SOURCES 		= $(wildcard ${CURRENT_DIR}/../../Design/*.sv)
MODULE 					:= tb_apb_top
TOPLEVEL 				:= apb_controller
TOPLEVEL_LANG			=verilog
COCOTB_HDL_TIMEUNIT		= 1ns
COCOTB_HDL_TIMEPRECISION= 1ns
include $(shell cocotb-config --makefiles)/Makefile.sim

cleanall: clean
	@rm -rf __pycache__
	@rm -rf results.xml