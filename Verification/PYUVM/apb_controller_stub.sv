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
  This file contains the APB slave implementation used to access 7 different registers and a memory

*/

module apb_controller #(
    // Parameter Declaration and propagation
    parameter N_OF_SLAVES   = 2,
    parameter REG_WIDTH     = 32,   // Single register WIDTH (single WORD alligned acces)
    parameter WAIT_STATE    = 0,    // this will basically used in case of Slower sub-slaves
    parameter MEMORY_DEPTH  = 256,  // Number of memory slots   
    parameter ZERO_MEM      = 0,    // If set to 1 then it will zero out the entire memory at the beginning of the SIM
    parameter DEC_WIDTH     = 32    // Decoder Parameter
  )
(
    // Port Declaration
    input logic                 pclk,       // Clock
    input logic                 pclk_en,    // Clock Enable
    input logic                 prst,       // Asynchronous reset active high
    input logic                 penable,    // Enable signal Similar to HTRANS  
    input logic                 pwrite,     // If 0 -> Read if 1 -> Write
    input logic                 psel,       // States if the slave has been properly selected 
    input logic [REG_WIDTH-1:0] paddr,      // Address coming into the bus
    input logic [REG_WIDTH-1:0] pwdata,     // Write Data coming into the bus
    output logic[REG_WIDTH-1:0] prdata,     // Read Data coming out the bus
    output logic                pslverror,  // Give error in few specific conditions only 
    output logic                pready      // Is controlled by the slave and claims if the specifc slave is busy or not
);

  //
  initial begin
    $dumpfile ("first.vcd");
    $dumpvars ();
  end

  assign pready = 1;
  assign pslverror = 1;
  assign prdata = 'hdeadbeef;
endmodule : apb_controller