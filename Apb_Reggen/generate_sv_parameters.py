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

def parse_json():
    global data
    with open("./out.json", "r") as f:
        data = j.load(f)
    f.close()

def gen_lists_and_csv():
    name    = []
    t_reg   = []
    address = []
    sub_data = data['children']
    for reg in sub_data:
        t_reg.append(reg['type'])
        name.append(reg['inst_name'])
        address.append(reg['addr_offset'])
        for x in reg['children']:
                t_reg.append(x['type'])
                name.append(x['inst_name'])
                address.append(reg['addr_offset'])
    df = pd.DataFrame(data={"TYPE": t_reg, "NAME": name, "ADDRESS": address})
    with open ('./file.csv', 'x') as f:
        df.to_csv("./file.csv", sep=',',index=False)
    f.close()
    t = Template(temp.param_template+'\n')
    with open('./reg_param.svh', 'x') as f:
        for x in name:
            a=t.substitute({'name' : x, 'value' : 0})
            f.write(a)
    f.close()

def main():
    parse_json()
    gen_lists_and_csv()

if __name__ == '__main__':
	main()