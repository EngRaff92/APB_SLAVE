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
# Local Variable
###############################################################################
current_dir =  $(shell pwd)
output_dir 	= $(current_dir)/output_all
rdl_file 	 = $(current_dir)/apb_register_descriptor.rdl

###############################################################################
# Local Rules
###############################################################################
.PHONY: clean rdb_gen test_variable

clean:
	@rm -rf $(output_dir)

test_variable:
	@test rdl_file

check_and_remove:
	@rm -rf $(output_dir)

rdb_gen: clean test_variable
	@if [ ! -d $(output_dir) ]; then mkdir -p $(output_dir); fi
	@$(current_dir)/json_exporter.py $(rdl_file)
	@$(current_dir)/generate_uvm_regs.py $(rdl_file)
	@$(current_dir)/generate_sv_parameters.py
	@$(current_dir)/generate_rif.py
	@$(current_dir)/generate_pyuvm_regs.py
	@$(current_dir)/generate_html.py $(rdl_file)
	@$(info Register Data Base generation DONE")