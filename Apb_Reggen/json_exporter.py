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
from typing import Union
import json
import numpy as np
from systemrdl import RDLCompiler, RDLCompileError
from systemrdl import node
import sys

############################################################################
#### Classes and functions
############################################################################

def DecimalToBinary(num,out):
    pos = 0
    while(num>=1):
        out[pos]=num%2
        num = num//2
        pos = pos +1

def convert_field(rdlc: RDLCompiler, obj: node.FieldNode) -> dict:
    json_obj                = dict()
    json_obj['type']        = 'field'
    json_obj['inst_name']   = obj.inst_name
    json_obj['lsb']         = obj.lsb
    json_obj['msb']         = obj.msb
    json_obj['reset']       = obj.get_property('reset')
    json_obj['sw_access']   = obj.get_property('sw').name
    json_obj['hw_access']   = obj.get_property('hw').name
    return json_obj


def convert_reg(rdlc: RDLCompiler, obj: node.RegNode) -> dict:
    # Convert information about the register
    json_obj                    = dict()
    json_obj['type']            = 'reg'
    json_obj['inst_name']       = obj.inst_name
    json_obj['address_offset']  = hex(obj.raw_absolute_address)
    ## Check the direction according to the following tabel
    #|---------------------------------------------|
    #| HAS_HW_READ |   HAS_HW_WRITE  | DIRECTION   |
    #|---------------------------------------------|
    #| FALSE       |   FALSE         | RuntimeError|  
    #|---------------------------------------------|
    #| TRUE        |   FALSE         | OUTPUT      |
    #|---------------------------------------------|
    #| FALSE       |   TRUE          | INPUT       |
    #|---------------------------------------------|
    #| TRUE        |   TRUE          | ChFPolicy   |
    #|---------------------------------------------|
    if obj.has_hw_readable == True:
        json_obj['direction'] = 'output'
    elif obj.has_hw_writable == True:
        json_obj['direction'] = 'input'
    #elif obj.has_hw_readable == True & obj.has_hw_writable == True:   
    else:
        raise RuntimeError
    # Iterate over all the fields in this reg and convert them
    json_obj['children'] = []
    ## Get reset value and insert into the JSON object
    reset          = np.zeros(32,dtype=np.uint8)
    ## Get the write read SW mask according to this table
    #|----------------------------------------------------------|
    #| HAS_HW_READ |   WRITE_MASK   | READ_MASK   | READ_MASK   |
    #|----------------------------------------------------------|
    #| FALSE       |   FALSE        | RuntimeError|             |
    #|----------------------------------------------------------|
    #| TRUE        |   FALSE        | OUTPUT      |             |
    #|----------------------------------------------------------|
    #| FALSE       |   TRUE         | INPUT       |             |
    #|----------------------------------------------------------|
    #| TRUE        |   TRUE         | ChFPolicy   |             |
    #|----------------------------------------------------------|
    sw_read_mask   = np.zeros(32,dtype=np.uint8)
    sw_write_mask  = np.zeros(32,dtype=np.uint8)
    ## Get the write read HW mask according to this table
    #|----------------------------------------------------------|
    #| HAS_HW_READ |   WRITE_MASK   | READ_MASK   | READ_MASK   |
    #|----------------------------------------------------------|
    #| FALSE       |   FALSE        | RuntimeError|             |
    #|----------------------------------------------------------|
    #| TRUE        |   FALSE        | OUTPUT      |             |
    #|----------------------------------------------------------|
    #| FALSE       |   TRUE         | INPUT       |             |
    #|----------------------------------------------------------|
    #| TRUE        |   TRUE         | ChFPolicy   |             |
    #|----------------------------------------------------------|
    hw_read_mask   = np.zeros(32,dtype=np.uint8)
    hw_write_mask  = np.zeros(32,dtype=np.uint8)
    ## Iterate
    for field in obj.fields():
        json_field = convert_field(rdlc, field)
        json_obj['children'].append(json_field)
        ## Get the reset value
        DecimalToBinary(json_field['reset'],reset[json_field['lsb']:json_field['msb']+1])
        ## Get the SW ACCESS MASK
        sw_read_mask[json_field['lsb']:json_field['msb']+1]  = (json_field['sw_access'] in ['rw','r','ro'])
        sw_write_mask[json_field['lsb']:json_field['msb']+1] = (json_field['sw_access'] in ['rw','w','wo'])
        ## Get the HW ACCESS MASK
        hw_read_mask[json_field['lsb']:json_field['msb']+1]  = (json_field['hw_access'] in ['rw','r','ro'])
        hw_write_mask[json_field['lsb']:json_field['msb']+1] = (json_field['hw_access'] in ['rw','w','wo'])
    ## Convert to Decimal Integere unsigned and after to hex string type
    json_obj['global_reset_value']  = hex(reset.dot(1<<np.arange(reset.size)[::]))
    ## Convert to Decimal Integere unsigned and after to hex string type
    json_obj['sw_write_mask']       = hex(sw_write_mask.dot(1<<np.arange(sw_write_mask.size)[::]))
    json_obj['sw_read_mask']        = hex(sw_read_mask.dot(1<<np.arange(sw_read_mask.size)[::]))
    json_obj['hw_write_mask']       = hex(hw_write_mask.dot(1<<np.arange(sw_write_mask.size)[::]))
    json_obj['hw_read_mask']        = hex(hw_read_mask.dot(1<<np.arange(hw_read_mask.size)[::]))
    return json_obj

def convert_reg_in_memory(rdlc: RDLCompiler, obj: node.RegNode, absolute_adress, position) -> dict:
    # Convert information about the register
    json_obj                    = dict()
    json_obj['type']            = 'reg'
    json_obj['inst_name']       = obj.inst_name + "_{}".format(position)
    json_obj['address_offset']  = hex(absolute_adress + (position * obj.size))
    json_obj['size']            = obj.total_size

    # Iterate over all the fields in this reg and convert them
    json_obj['children'] = []
    for field in obj.fields():
        json_field = convert_field(rdlc, field)
        json_obj['children'].append(json_field)

    return json_obj

def convert_addrmap_or_regfile(rdlc: RDLCompiler, obj: Union[node.AddrmapNode, node.RegfileNode, node.MemNode]) -> dict:
    json_obj = dict()
    if isinstance(obj, node.AddrmapNode):
        json_obj['type'] = 'addrmap'
        json_obj['absolute_adress'] = hex(obj.raw_absolute_address)
    elif isinstance(obj, node.RegfileNode):
        json_obj['type'] = 'regfile'
        json_obj['absolute_adress'] = hex(obj.raw_absolute_address)
    elif isinstance(obj, node.MemNode):
        json_obj['type'] = 'memory'
        json_obj['memory_adress_start'] = hex(obj.raw_absolute_address)
    else:
        raise RuntimeError

    json_obj['inst_name'] = obj.inst_name

    json_obj['children'] = []
    for child in obj.children():
        if isinstance(child, (node.AddrmapNode, node.RegfileNode, node.MemNode)):
            json_child = convert_addrmap_or_regfile(rdlc, child)
            json_obj['children'].append(json_child)
        elif isinstance(child, node.RegNode):
            if isinstance(obj, node.MemNode):
                for el in range(len(child.array_dimensions)):
                    for index in range(child.array_dimensions[el]):
                        json_child = convert_reg_in_memory(rdlc, child, obj.address_offset,index)
                        json_obj['children'].append(json_child)
                json_obj['memory_adress_end'] = hex(obj.raw_absolute_address + ((child.array_dimensions[0]-1)* int(child.size)))
            else:
                json_child = convert_reg(rdlc, child)
                json_obj['children'].append(json_child)
    return json_obj


def convert_to_json(rdlc: RDLCompiler, obj: node.RootNode, path: str):
    # Convert entire register model to primitive datatypes (a dict/list tree)
    json_obj = convert_addrmap_or_regfile(rdlc, obj.top)

    # Write to a JSON file
    with open(path, "w") as f:
        json.dump(json_obj, f, indent=4)

## MAIN
if __name__ == "__main__":
    # Compile and elaborate files provided from the command line
    input_files = sys.argv[1:]
    rdlc = RDLCompiler()
    try:
        for input_file in input_files:
            rdlc.compile_file(input_file)
        root = rdlc.elaborate()
    except RDLCompileError:
        sys.exit(1)

    # Dump the register model to a JSON file
    convert_to_json(rdlc, root, "./output_all/reg.json")
