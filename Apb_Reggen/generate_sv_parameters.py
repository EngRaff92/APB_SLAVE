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
import pandas as pd
import sys
import template as temp
from string import Template

############################################################################
############################################################################
#### Classes and functions
############################################################################
regfile_type = "regfile"
memory_type  = "memory"

# Use to open the JSON file and get the dictionary back
def parse_json() -> dict:
    data = {}
    with open("./output_all/reg.json", "r") as f:
        data = j.load(f)
    f.close()
    return data

def gen_lists_and_csv(data):
    name        = []
    t_reg       = []
    address     = []
    sub_data    = data['children']
    sw_rd_mask  = []
    hw_rd_mask  = []
    sw_wr_mask  = []
    hw_wr_mask  = []
    reset_p     = []
    res         = {}
    res2        = {}
    global is_regfile 
    global is_memory
    for reg in sub_data:
        # Check the register aggregation type
        if reg['type'] == regfile_type:
            is_regfile = True
            is_memory  = False
        elif reg['type'] == memory_type:
            is_regfile = False
            is_memory  = True
        # according to the result we create the parameters
        t_reg.append(reg['type'])
        ## check if Memory so that we can print the start and end 
        if ((not is_regfile) & is_memory):
            address.append(reg['memory_adress_start'])
            name.append("memory_adress_start")
        else:
            address.append(reg['absolute_adress'])
            name.append(reg['inst_name'])
        ## Look Inside for children
        for x in reg['children']:
            t_reg.append(x['type'])
            name.append(x['inst_name'])
            if ((not is_memory) & is_regfile):
                ## Get the masks
                sw_rd_mask.append(x['sw_read_mask'])
                hw_rd_mask.append(x['hw_read_mask'])
                sw_wr_mask.append(x['sw_write_mask'])
                hw_wr_mask.append(x['hw_write_mask'])
                reset_p.append(x['global_reset_value'])            
            if (x['type'] != "field"):
                address.append(x['address_offset'])
        if ((not is_regfile) & is_memory):
            t_reg.append(memory_type)
            name.append("memory_adress_end")
            address.append(reg['memory_adress_end'])
    ## Generate the final dicationary
    res         = dict(zip(name, address))
    res2        = dict(zip(name, t_reg))
    rest_dict   = dict(zip(name, reset_p))
    hwwr_dict   = dict(zip(name, hw_wr_mask))
    hwrd_dict   = dict(zip(name, hw_rd_mask))
    swwr_dict   = dict(zip(name, sw_wr_mask))
    swrd_dict   = dict(zip(name, sw_rd_mask))
    df = pd.DataFrame(data={"TYPE": t_reg, "NAME": name, "ADDRESS": address})
    with open ('./output_all/reg.csv', 'x') as f:
        df.to_csv("./output_all/reg.csv", sep=',',index=False)
    f.close()
    t = Template(temp.param_template+'\n')
    d = Template(temp.define_template+'\n')
    p = Template(temp.python_const_template+'\n')
    with open('./output_all/reg_param.svh', 'x') as f:
        ## Fristly write the header
        f.write(temp.header)
        ## Start with Params
        for x in res.keys():
            if res2[x] == regfile_type:
                a=t.substitute({'name' : "{}_{}".format(res2[x],x), 'value' : res[x].replace('0x',"32'h")})
            elif res2[x] == memory_type:
                a=t.substitute({'name' : "{}".format(x), 'value' : res[x].replace('0x',"32'h")})
            else:
                a=t.substitute({'name' : "register_{}".format(x), 'value' : res[x].replace('0x',"32'h")})
            f.write(a)
        ## Start with Defines
        for x in res.keys():
            if res2[x] == regfile_type:
                b=d.substitute({'name' : "{}_{}".format(res2[x],x), 'value' : res[x].replace('0x',"32'h")})
            elif res2[x] == memory_type:
                b=d.substitute({'name' : "{}".format(x), 'value' : res[x].replace('0x',"32'h")})
            else:
                b=d.substitute({'name' : "register_{}".format(x), 'value' : res[x].replace('0x',"32'h")})
            f.write(b)
        ## Start for the Mask
        for x in hwwr_dict.keys():
            b=d.substitute({'name' : "mask_hwwr_{}".format(x), 'value' : hwwr_dict[x].replace('0x',"32'h")})
            f.write(b)
        for x in hwrd_dict.keys():
            b=d.substitute({'name' : "mask_hwrd_{}".format(x), 'value' : hwrd_dict[x].replace('0x',"32'h")})
            f.write(b)
        for x in swwr_dict.keys():
            b=d.substitute({'name' : "mask_swwr_{}".format(x), 'value' : swwr_dict[x].replace('0x',"32'h")})
            f.write(b)
        for x in swrd_dict.keys():
            b=d.substitute({'name' : "mask_swrd_{}".format(x), 'value' : swrd_dict[x].replace('0x',"32'h")})
            f.write(b)
        ## Start for Resert
        for x in rest_dict.keys():
            b=d.substitute({'name' : "{}_POR_VALUE".format(x), 'value' : rest_dict[x].replace('0x',"32'h")})
            f.write(b)     

    f.close()
    with open('./output_all/reg_python_const.py', 'x') as f:
        ## Fristly write the header
        f.write(temp.header_python)
        for x in res.keys():
            if res2[x] == regfile_type:
                c=p.substitute({'name' : "{}_{}".format(res2[x],x), 'value' : res[x]})
            elif res2[x] == memory_type:
                c=p.substitute({'name' : "{}".format(x), 'value' : res[x]})
            else:
                c=p.substitute({'name' : "register_{}".format(x), 'value' : res[x]})
            f.write(c)
        ## Start for the Mask
        for x in hwwr_dict.keys():
            c=p.substitute({'name' : "mask_hwwr_{}".format(x), 'value' : hwwr_dict[x]})
            f.write(c)
        for x in hwrd_dict.keys():
            c=p.substitute({'name' : "mask_hwrd_{}".format(x), 'value' : hwrd_dict[x]})
            f.write(c)
        for x in swwr_dict.keys():
            c=p.substitute({'name' : "mask_swwr_{}".format(x), 'value' : swwr_dict[x]})
            f.write(c)
        for x in swrd_dict.keys():
            c=p.substitute({'name' : "mask_swrd_{}".format(x), 'value' : swrd_dict[x]})
            f.write(c)
        ## Start for Resert
        for x in rest_dict.keys():
            c=p.substitute({'name' : "{}_POR_VALUE".format(x), 'value' : rest_dict[x]})
            f.write(c)              
    f.close()

def main():
    data_f = parse_json()
    gen_lists_and_csv(data_f)

if __name__ == '__main__':
	main()
