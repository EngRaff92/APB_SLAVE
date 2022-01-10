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
import json as j
import sys
import rif_template as rif
import numpy as np
from string import Template

############################################################################
#### TODO LIST
############################################################################
'''
------------------------------------------------------------------------|
|   TASK NAME                                       |     RESULT        |
------------------------------------------------------------------------|
1.  Add support for fields rather then registers    |                   |
------------------------------------------------------------------------|
2.  Add support for Wonce and Ronce registers       |                   |
------------------------------------------------------------------------|
3.  Add support for RD error for WO registers       |                   |
------------------------------------------------------------------------|
4.  Add runtime errors in case of inconsistency     |                   |
------------------------------------------------------------------------|
5.  Add support for memory initialized value        |                   |
------------------------------------------------------------------------|
6.  Generate POR defines                            |       DONE        |
------------------------------------------------------------------------|
7.  Generate Mask for registers                     |       DONE        |
------------------------------------------------------------------------|
8.  Add context using jinja wrapper                 |                   |
------------------------------------------------------------------------|


'''

############################################################################
#### Classes and functions
############################################################################
regfile_type = "regfile"

# Use to open the JSON file and get the dictionary back
def parse_json() -> dict:
    address_map = {}
    with open("./output_all/reg.json", "r") as f:
        address_map = j.load(f)
    f.close()
    return address_map

def gen_rif(data):
    ## Register list
    sub_maps    = data['children']
    ## Sub lists used to distunguish registers
    reg_name    = []
    out_name    = []
    inp_name    = []
    access_i    = []
    access_o    = []
    reset_p     = []
    sw_rd_mask  = []
    hw_rd_mask  = []
    sw_wr_mask  = []
    hw_wr_mask  = []
    sw_rd_name  = []
    sw_wr_name  = []
    ## Start
    for element in sub_maps:
        # Check the register aggregation type
        if element['type'] == regfile_type:
            is_regfile = True
        else: 
            is_regfile = False
        ## if is a reg file type then we load all the registers in it
        if is_regfile:
            for reg in element['children']:
                ## loop through the registers to get the name
                reg_name.append(reg['inst_name'])
                ## loop through the registers to get the reset value
                reset_p.append(reg['global_reset_value'])
                ## loop through the registers to get the HW and SW masks
                sw_rd_mask.append(reg['sw_read_mask'])
                hw_rd_mask.append(reg['hw_read_mask'])
                sw_wr_mask.append(reg['sw_write_mask'])
                hw_wr_mask.append(reg['hw_write_mask'])
                ## loop through the registers to get the direction
                if reg['direction'] == "output":
                    access_o.append(reg['direction'])
                    out_name.append(reg['inst_name'])
                else:
                    access_i.append(reg['direction'])
                    inp_name.append(reg['inst_name'])
    ## Generate the final dicationaries
    out_dict    = dict(zip(out_name, access_o))
    inp_dict    = dict(zip(inp_name, access_i))
    rest_dict   = dict(zip(reg_name, reset_p))
    hwwr_dict   = dict(zip(reg_name, hw_wr_mask))
    hwrd_dict   = dict(zip(reg_name, hw_rd_mask))
    swwr_dict   = dict(zip(reg_name, sw_wr_mask))
    swrd_dict   = dict(zip(reg_name, sw_rd_mask))
    ## Step through the direction to get the module ports
    with open('./output_all/rif.sv', 'x') as f:
        ## Fristly write the header
        f.write(rif.header)
        f.write(rif.sv_inclusion)
        f.write(rif.module_name_param)
        f.write(rif.standard_rif_input_ports)
        f.write("\n  // Sets of input ports for HW write access")
        inp = Template(rif.hw_write_template_port)
        out = Template(rif.hw_read_template_port)
        for name in inp_dict.keys():   
            rif_replace = inp.substitute({'input_port_hw_rw_access_name' : "{}_in".format(name)})
            f.write(rif_replace)
        f.write("\n  // Sets of output ports for HW read access")
        for name in out_dict.keys():
            rif_replace = out.substitute({'output_port_hw_rw_access_name' : "{}_out".format(name)})
            f.write(rif_replace)
        f.write(rif.standard_rif_output_ports)
        ## Step through the names of registers to dump the decoder signals
        dec = Template(rif.set_of_decoder_flags)
        f.write("\n    // Sets of DEC flags")
        for name in reg_name:
            rif_replace = dec.substitute({'dec_val' : "{}_dec".format(name)})
            f.write(rif_replace)
        ## Step through the register define the register variables inside the module
        register = Template(rif.set_register)
        f.write("\n")
        f.write("\n    // DESC: Sets of registers Access Policy is RW or RO")
        for name in reg_name:
            rif_replace = register.substitute({'reg_rw' : "{}".format(name)})
            f.write(rif_replace)
        ## Dump internal standard not changable logic`
        f.write(rif.internal_additional_signals)
        f.write(rif.internal_decoder_signals_generation)
        f.write(rif.internal_wr_rd_request)
        f.write(rif.initialize_decoder_state)
        dec = Template(rif.init_dec_access)
        for name in reg_name:
            rif_replace = dec.substitute({'dec_val' : "{}_dec".format(name)})
            f.write(rif_replace)
        f.write(rif.case_switch_over_address)
        case = Template(rif.selection)
        for name in reg_name:
            rif_replace = case.substitute({'define_name' : "`register_{}".format(name) , 'dec_val' : "{}_dec".format(name)})
            f.write(rif_replace)
        f.write(rif.defualt_end_case)
        f.write(rif.initialize_write_decoder_std)
        f.write("\n        // Init only HW = R registers")
        register = Template(rif.initialize_write_decoder_init_start)
        for name in out_dict.keys():
            rif_replace = register.substitute({'reg_name' : "{}".format(name), 'reset_val' : "'h{}".format(rest_dict[name].replace("0x",""))})
            f.write(rif_replace)
        f.write(rif.initialize_write_decoder_init_end)
        register = Template(rif.register_write_decoder_start)
        for name in reg_name:
            rif_replace = register.substitute({'dec_val' : "{}_dec".format(name), 'reg_name' : "{}".format(name), 'sw_write_mask' : "{}".format(swwr_dict[name].replace("0x","'h"))})
            f.write(rif_replace)
        f.write(rif.register_write_decoder_end)
        f.write(rif.errorr_handler_logic_start)
        register = Template(rif.errorr_handler_logic)
        for name in inp_dict.keys():
            rif_replace = register.substitute({'dec_val' : "{}_dec".format(name), 'read_reg' : "{}".format(name), 'sw_read_mask': "{}".format(swrd_dict[name].replace("0x","'h"))})
            f.write(rif_replace)
        f.write(rif.errorr_handler_logic_end)
        # f.write(rif.errorr_handler_write_logic_start)
        # register = Template(rif.errorr_handler_write_logic)
        # for name in out_dict.keys():
        #     rif_replace = register.substitute({'dec_val' : "{}_dec".format(name), 'read_reg' : "{}".format(name)})
        #     f.write(rif_replace)
        # f.write(rif.errorr_handler_write_logic_end)
        f.write(rif.internal_latest_assignement)
        f.write("\n    // Assignements for HW = R policy")
        register = Template(rif.assign_for_hw_read_policy_reg)
        for name in out_dict.keys():
            rif_replace = register.substitute({'out_port' : "{}_out".format(name), 'reg_name' : "{}".format(name), 'hw_read_mask' : "{}".format(hwrd_dict[name].replace("0x","'h"))})
            f.write(rif_replace) 
        f.write("\n\n    // Assignements for HW = W policy")
        register = Template(rif.assign_for_hw_write_policy_reg)   
        for name in inp_dict.keys():
            rif_replace = register.substitute({'reg_name' : "{}".format(name),'in_port' : "{}_in".format(name), 'hw_write_mask' : "{}".format(hwwr_dict[name].replace("0x","'h"))})
            f.write(rif_replace)  
        f.write(rif.end_module_rif)     
    f.close()

def main():
    data_f = parse_json()
    gen_rif(data_f)

if __name__ == '__main__':
	main()
