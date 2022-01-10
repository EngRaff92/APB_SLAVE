#!/opt/homebrew/bin/python3.9

import sys
import os

from systemrdl import RDLCompiler, RDLCompileError
from peakrdl.html import HTMLExporter

#===============================================================================
input_files = sys.argv[1:]

rdlc = RDLCompiler()

try:
    for input_file in input_files:
        rdlc.compile_file(input_file)
    root = rdlc.elaborate()
except RDLCompileError:
    sys.exit(1)

html = HTMLExporter()
html.export(
    root,
    os.path.join("./output_all/reg.html"),
)