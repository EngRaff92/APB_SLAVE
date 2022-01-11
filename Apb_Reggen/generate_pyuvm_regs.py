#!/opt/homebrew/bin/python3.9

## 
## Icebreaker and IceSugar RSMB5 project - RV32I for Lattice iCE40
## With complete open-source toolchain flow using:
## -> yosys 
## -> icarus verilog
## -> icestorm project
## 
## Tests are written in several languages
## -> Systemverilog Pure Testbench (Vivado)
## -> UVM testbench (Vivado)
## -> PyUvm (Icarus)
## -> Formal either using SVA and PSL (Vivado) or cuncurrent assertions with Yosys
## 
## Copyright (c) 2021 Raffaele Signoriello (raff.signoriello92@gmail.com)
## 
## Permission is hereby granted, free of charge, to any person obtaining a 
## copy of this software and associated documentation files (the "Software"), 
## to deal in the Software without restriction, including without limitation 
## the rights to use, copy, modify, merge, publish, distribute, sublicense, 
## and/or sell copies of the Software, and to permit persons to whom the 
## Software is furnished to do so, subject to the following conditions:
## 
## The above copyright notice and this permission notice shall be included 
## in all copies or substantial portions of the Software.
## 
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
## EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
## IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
## CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
## TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
## SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

############################################################################
#### import main packages
############################################################################
import json
import os
import sys
import logging
import jinja2
import template

############################################################################
############################################################################
#### Classes and functions
############################################################################

class pyuvm_reg_generator(object):
    def __init__(self):
        self.main_root		= {}
        self.ral_txt  		= ""
        self.reg_txt        = ""

        # TODO check directory exists
        self.jinja_env = jinja2.Environment(loader=jinja2.FileSystemLoader("./"))

    # Use to open the JSON file and get the dictionary back
    def parse_json(self):
    	with open("./output_all/reg.json", "r") as f:
    		self.main_root = json.load(f)
    		f.close()

    def build(self):
    	# Open file
    	f = open("./output_all/pyvum_register_model.py", "a")
    	# Fristly write the header
    	f.write(template.header_imports_needed)
    	# Extract Information
    	mmap_context = {}
    	mmap_context["name"] = self.main_root["inst_name"]
    	# Start
    	for addressBlock in self.main_root["children"]:
    		if addressBlock["type"] != "regfile":
    			logging.warning("[pyuvm_reg_generator]: Found memory in the MAIN map Memory type are not yetr supported by the script.")
    		else:
    			block_context 					= {}
    			block_context["name"] 			= addressBlock["inst_name"]
    			block_context["baseAddress"] 	= addressBlock["absolute_adress"]
    			block_context["registers"] 		= []
    			for reg in addressBlock["children"]:
    				reg_context = {}
    				block_context["registers"].append(reg_context)
    				reg_context["name"] 			= reg["inst_name"]
    				reg_context["addressOffset"] 	= reg["address_offset"]
    				reg_context["reset"] 			= reg["global_reset_value"]
    				reg_context["reset"] 			= reg["global_reset_value"]
    				reg_context["sw_write_mask"] 	= reg["sw_write_mask"]
    				reg_context["sw_read_mask"] 	= reg["sw_read_mask"]
    				reg_context["fields"] 			= []
    				for field in reg["children"]:
    					field_context = {}
    					reg_context["fields"].append(field_context)
    					field_context["name"] 			= field["inst_name"]
    					## TODO: add scription element
    					##field_context["description"] 	= field["desc"]
    					field_context["bitOffset"]    	= field["lsb"]
    					field_context["bitWidth"] 		= field["msb"]+1-field["lsb"]
    					field_context["access"] 		= field["sw_access"].capitalize()
    					field_context["reset"] 			= field["reset"]
    					reg_template = self.jinja_env.get_template("pyuvm_reg_template.py.jinja")
    				self.reg_txt = reg_template.render(context=reg_context)
    				# Write into file appending conent
    				f.write(self.reg_txt)
    			block_template = self.jinja_env.get_template("pyuvm_reg_block_template.py.jinja")
    			self.ral_txt = block_template.render(context=block_context)
    			# Then write the register block
    			f.write(self.ral_txt)
    			f.close()

	## This will invoke the context generation
    def generate_pyuvm_reg(self):
    	self.build()

    ## RUN all
    def run(self):
    	self.parse_json()
    	self.generate_pyuvm_reg()

#######################################################################################################
def main():
    # Create
    genObj = pyuvm_reg_generator()
    genObj.run()

if __name__ == "__main__":
    main()