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
// SLV checker
`define SLV0 	2'b01
`define SLV1 	2'b10
`define NSLV 	2'b00
`define ILLEGAL 2'b11

// Address with names
`define wren	'd0
`define status1	'd4
`define status2	'd8
`define status3	'd12
`define data1	'd16
`define data2	'd20
`define data3	'd24

// Decoder cutshort
`define dec_wren	`wren >> 2
`define dec_status1	`status1 >> 2
`define dec_status2	`status2 >> 2     
`define dec_status3	`status3 >> 2
`define dec_data1	`data1 >> 2
`define dec_data2	`data2 >> 2
`define dec_data3	`data3 >> 2

// RIF ADDRESS SPACE
`define RIF_ADDR_START	'h0
`define RIF_ADDR_END	'h3C

// MEMORY ADDRESS SPACE
`define MEM_ADDR_START	'h40
`define MEM_ADDR_END	'h43C

// SLAVES
`define NUMBER_OF_SLVS 	2