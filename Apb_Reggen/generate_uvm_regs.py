import sys
from systemrdl import RDLCompiler, RDLCompileError
from peakrdl.uvm import UVMExporter

rdlc = RDLCompiler()

try:
    rdlc.compile_file("/Volumes/My_Data/MY_SYSTEMVERILOG_UVM_PROJECTS/APB_PROTOCOL/APB_SLAVE/Apb_Reggen/basic.rdl")
    root = rdlc.elaborate()
except RDLCompileError:
    sys.exit(1)

exporter = UVMExporter()
exporter.export(root, "test.sv")
