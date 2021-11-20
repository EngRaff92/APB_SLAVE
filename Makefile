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
CURRENT_DIR 	= $(shell pwd)
VERIF_DIR		= $(shell realpath ./Verification)
DESIGN_DIR		= $(shell realpath ./Design)
DESIGN_SRC  	= $(wildcard ${DESIGN_DIR}/*.sv)
TESTBENCH_SRC	= $(wildcard ${VERIF_DIR}/*.sv)
GTKW_FILE 		= ${VERIF_DIR}/*.gtkw

###############################################################################
# IO SERIAL TERMINAL
###############################################################################
SERIALPORT = /dev/ttyUSB1
SERIALBAUD = 9600

###############################################################################
# DEFAULT FPGA DEINES
###############################################################################
TARGET 			= 5k
SRC 			+= ./top/hx1k.v
PNRFLAGS 		= --hx1k
ICETIMEFLAGS 	= -d hx1k
FPGA_PINMAP 	= ./pinmap/hx1k.pcf	

###############################################################################
# Output Synthesis
###############################################################################
SIM_DIR 		= $(shell realpath ./Simulation)
SYNTH_DIR 		= $(shell realpath ./Synthesis)
REGDIR 			= $(shell realpath ./Reg_Gen)
VCD_OUT 		= $(SIM_DIR)/_test.vcd
VVP_OUT		 	= $(SIM_DIR)/_compiler.out
SYNTH_JSON_OUT 	= $(SYNTH_DIR)/_synth_output.json
SYNTH_BLIF_OUT 	= $(SYNTH_DIR)/_synth_output.json
FPGA_ASC_OUT 	= $(SYNTH_DIR)/_fpga.asc
FPGA_BIN_OUT 	= $(SYNTH_DIR)/_fpga.bin
FPGA_SYNTH_OUT 	= $(SYNTH_DIR)/_fpga.sv
SYNTH_LOG		= $(SYNTH_DIR)/_fpga_synth.log

###############################################################################
# SIMULATION SETUP 
###############################################################################
# This variable defines the test type meaning which files should be included 
# By defualt it runs without any problem with icarus since we do not use the
# Full SV set of features (UVM as well is excluded)
SIM_TYPE 	= ICARUS
FORMAL_TYPE	= SBY
ifndef SIM_TYPE
	$(error SIM_TYPE is not set)
	$(info LISTING VALUES: set properly and rerun)
	$(info ICARUS	: for limited ICARUS verilog SV supported features)
	$(info SV 		: for a PURE SV testbench not running on ICARUS)	
	$(info UVM		: for a UVM testbench not supported by open source tools)	
	$(info PYUVM	: for a PYUVM testbench and cocotb with ICARUS)	
	$(info FORMAL 	: for FORMAL verification run)			
endif
ifeq ($(SIM_TYPE),ICARUS)
$(info SIM_TYPE is set to ICARUS)
DFLAGS 		= -DICARUS
SIM_DIR		:= $(SIM_DIR)
else ifeq ($(SIM_TYPE),SV)
$(info SIM_TYPE is set to SV)
DFLAGS 		= -DPURE_SV
SIM_DIR		:= $(SIM_DIR)/PURE_SV
else ifeq ($(SIM_TYPE),UVM)	
$(info SIM_TYPE is set to UVM)
DFLAGS 		= -DAPB_UVM
SIM_DIR		:= $(SIM_DIR)/UVM
else ifeq ($(SIM_TYPE),PYUVM)
$(info SIM_TYPE is set to PYUVM)
DFLAGS 		= -DAPB_PYUVM
SIM_DIR		:= $(SIM_DIR)/PYUVM
else ifeq ($(SIM_TYPE),FORMAL)
$(info SIM_TYPE is set to FORMAL)
ifeq ($(FORMAL_TYPE), SBY)
	$(info SIM_TYPE is set to SBY)
	DFLAGS 		= -DSBY
	SIM_DIR		:= $(SIM_DIR)/FORMAL/SBY
else ifeq ($(FORMAL_TYPE), SVA)
	$(info SIM_TYPE is set to SVA)
	DFLAGS 		= -DSVA
	SIM_DIR		:= $(SIM_DIR)/FORMAL/SVA	
else
	$(error FORMAL_TYPE is not set)
	$(info LISTING VALUES: set properly and rerun)
	$(info SVA: for SVA only)
	$(info SBY: for Symbyosys supported Assertions)
endif
else
$(error SIM_TYPE is not set properly)
endif

###############################################################################
# TOOLS 
###############################################################################
COMPILER 	= iverilog
SIMULATOR 	= vvp
VIEWER 		= gtkwave
YOSYS 		= yosys
NEXTPNR 	= nextpnr-ice40
ICEBOXVLOG 	= icebox_vlog
ICEPACK 	= icepack
ICESPROG 	= sudo icesprog
ICETIME 	= icetime
REGTOOL		?= regtool

###############################################################################
# TOOL FLAGS
###############################################################################
#YOSYSFLAGS 	= -f "verilog -D__def_fw_img=\"$(FIRMWARE_DIR)/$(FIRMWARE_IMG).vhex\"" -p "synth_ice40 -json $(SYNTH_JSON_OUT);"
YOSYSFLAGS	= -ql $(SYNTH_LOG) -sv read_verilog $(DESIGN_SRC) -p "synth_ice40 -top $(FPGA_SYNTH_OUT) -json $(SYNTH_JSON_OUT) -blif $(SYNTH_BLIF_OUT)"
COFLAGS 	= -g2012 
SFLAGS 		= -v
SOUTPUT 	= -lxt

###############################################################################
# Setup Environment
###############################################################################
.PHONY: all clean

proj_dir:
	@mkdir -p ./Reg_Gen
	@mkdir -p ./Simulation
	@mkdir -p ./Verification
	@mkdir -p ./Verification/PURE_SV
	@mkdir -p ./Verification/PYUVM
	@mkdir -p ./Verification/UVM
	@mkdir -p ./Verification/FORMAL
	@mkdir -p ./Verification/FORMAL/SBY
	@mkdir -p ./Verification/FORMAL/SVA
	@mkdir -p ./Synthesis
	@mkdir -p ./Design
	@mkdir -p ./Report

###############################################################################
# Firmware
###############################################################################
firmware:
	$(MAKE) -C $(FIRMWARE_DIR) FIRMWARE_IMG=$(FIRMWARE_IMG) CODE_LOCATION=$(CODE_LOCATION) DATA_LOCATION=$(DATA_LOCATION)

###############################################################################
# Simulation
###############################################################################
compile: proj_dir
	@mkdir -p $(SIM_DIR)
	@$(COMPILER) $(COFLAGS) $(DFLAGS) -o $(VVP_OUT) $(TESTBENCH_SRC) $(DESIGN_SRC)

simulate: compile
	@if [ -d "${SIM_DIR}" ]; then vvp $(VVP_OUT); fi

genpll:
	@echo "Gen pll is empty"

###############################################################################
# Synthesis
###############################################################################
synth: 
	$(YOSYS) $(YOSYSFLAGS)

pandr:
	$(NEXTPNR) $(PNRFLAGS) --json $(SYNTH_JSON_OUT) --pcf $(FPGA_PINMAP) --asc $(FPGA_ASC_OUT)

program:
	$(ICEPACK) $(FPGA_ASC_OUT) $(FPGA_BIN_OUT)
	$(ICEPROG) $(ICEPROG_PARAM) $(FPGA_BIN_OUT)

###############################################################################
# Register Generation
###############################################################################
gen_reg_rtl: 
	@echo "gen_reg_rtl not implemented"

gen_reg_dv: 
	@echo "gen_reg_dv not implemented"

gen_reg_fpv: 
	@echo "gen_reg_fpv not implemented"

###############################################################################
# Serial and Clean Rules
###############################################################################
serial_connection:
	@echo "To end the session, press Ctrl+a followed by k."
	screen $(SERIALPORT) $(SERIALBAUD)

clean:
	@rm -rf ./$(SIM_DIR)
	@rm -rf ./$(SYNTH_DIR)

###############################################################################
# HELP
###############################################################################
help:
	@echo "	IceSugar or Icebreaker Project Environment:"
	@echo "	Firmware make commands avaliable:"
	@echo " make firmware          	->	Empry"
	@echo " make firmware-test     	-> 	Empty"	
	@echo " make firmware-load     	-> 	Empty"	
	@echo " make firmware-flash    	-> 	Empty"	
	@echo " make firmware-connect  	-> 	Empty"	
	@echo " make firmware-clear 	-> 	Empty"
	@echo ""
	@echo "	Other Make commands avaliable:"
	@echo " make gen_reg_rtl		- "
	@echo " make gen_reg_dv			- "
	@echo " make gen_reg_fpv		- "
	@echo " make simulate			- Run a simple Systemverilog test supported by Icarus"
	@echo " make pysim				- Run a PyUvm tests supported by Icarus"
	@echo " make regression 		- Run all PyUvm tests supported by Icarus"
	@echo " make formal				- Run Formal tests supported by SymbYosys"
	@echo " make compile            - Run compilation TB top and DUT"
	@echo " make time              	- Run the STA tests"
	@echo " make program            - Run the Icesugar or Icebreaker programming"
	@echo " make synth              - Run all tests"
	@echo " make clean             	- Clean all "