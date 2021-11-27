/*
 Icebreaker and IceSugar RSMB5 project - RV32I for Lattice iCE40
 With complete open-source toolchain flow using:
 -> yosys 
 -> icarus verilog
 -> icestorm project

 Tests are written in several languages
 -> Systemverilog Pure Testbench (Vivado)
 -> UVM testbench (Vivado)
 -> PyUvm (Icarus)
 -> Formal either using SVA and PSL (Vivado) or cuncurrent assertions with Yosys

 Copyright (c) 2021 Raffaele Signoriello (raff.signoriello92@gmail.com)

 Permission is hereby granted, free of charge, to any person obtaining a 
 copy of this software and associated documentation files (the "Software"), 
 to deal in the Software without restriction, including without limitation 
 the rights to use, copy, modify, merge, publish, distribute, sublicense, 
 and/or sell copies of the Software, and to permit persons to whom the 
 Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included 
 in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
 CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
 TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*
*/

// ########################################################################################################
// Defines and Parameters for DESIGN
// ########################################################################################################
// Include the Auto generated sets of parameters
`include "/Volumes/My_Data/MY_SYSTEMVERILOG_UVM_PROJECTS/APB_PROTOCOL/APB_SLAVE/Apb_Reggen/output_all/apb_reg_param.svh"

// SLV checker
`define SLV0  1<<0
`define SLV1  1<<1
`define SLV2  1<<2
`define SLV3  1<<3
`define SLV4  1<<4
`define SLV5  1<<5
`define SLV6  1<<6
`define SLV7  1<<7
`define NSLV  1<<8

// SLAVES
`define NUMBER_OF_SLVS  2
`define MAX_N_OF_SLVS   8