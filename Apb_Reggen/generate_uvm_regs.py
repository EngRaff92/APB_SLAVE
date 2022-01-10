#!/opt/homebrew/bin/python3.9

import sys
from systemrdl import RDLCompiler, RDLCompileError
from peakrdl.uvm import UVMExporter

def export_uvm(obj):
    exporter = UVMExporter()
    exporter.export(root, "./output_all/reg_pkg.sv")

if __name__ == "__main__":
    import sys
    # Compile and elaborate files provided from the command line
    input_files = sys.argv[1:]
    rdlc = RDLCompiler()
    try:
        for input_file in input_files:
            rdlc.compile_file(input_file)
        root = rdlc.elaborate()
        export_uvm(root)
    except RDLCompileError:
        sys.exit(1)
