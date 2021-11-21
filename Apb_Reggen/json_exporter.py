#! /opt/homebrew/bin/python3.9

from typing import Union
import json

from systemrdl import RDLCompiler, RDLCompileError
from systemrdl import node


def convert_field(rdlc: RDLCompiler, obj: node.FieldNode) -> dict:
    json_obj = dict()
    json_obj['type'] = 'field'
    json_obj['inst_name'] = obj.inst_name
    json_obj['lsb'] = obj.lsb
    json_obj['msb'] = obj.msb
    json_obj['reset'] = obj.get_property('reset')
    json_obj['sw_access'] = obj.get_property('sw').name
    return json_obj


def convert_reg(rdlc: RDLCompiler, obj: node.RegNode) -> dict:
    # Convert information about the register
    json_obj = dict()
    json_obj['type'] = 'reg'
    json_obj['inst_name'] = obj.inst_name
    json_obj['address_offset'] = hex(obj.raw_absolute_address)

    # Iterate over all the fields in this reg and convert them
    json_obj['children'] = []
    for field in obj.fields():
        json_field = convert_field(rdlc, field)
        json_obj['children'].append(json_field)

    return json_obj

def convert_reg_in_memory(rdlc: RDLCompiler, obj: node.RegNode, absolute_adress, position) -> dict:
    # Convert information about the register
    json_obj = dict()
    json_obj['type'] = 'reg'
    json_obj['inst_name'] = obj.inst_name + "_{}".format(position)
    json_obj['address_offset'] = hex(absolute_adress + (position* int(obj.total_size/8)))
    json_obj['size'] = obj.total_size

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
        json_obj['absolute_adress'] = hex(obj.raw_absolute_address)
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

#-------------------------------------------------------------------------------

if __name__ == "__main__":
    import sys

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
    convert_to_json(rdlc, root, "./output_all/apb_reg.json")
