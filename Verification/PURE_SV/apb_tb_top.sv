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

// Main Include
`include "./apb_verif_includes.svh"

// Main TB module
module apb_tb_top;
	// Clock and Reset
	bit pclk;

	// local test
	apb_base_test test_base;

	// Interface declaration
	apb_interface#(.REG_WIDTH(REG_WIDTH)) apb_if(.apb_clock(pclk));

	// DUT
	apb_slave_controller#(
		.N_OF_SLAVES (2),
    	.REG_WIDTH   (32),
      	.ZERO_MEM    (0),
      	.DEC_WIDTH   (32),
      	.MEMORY_DATA (32),
      	.MEMORY_DEPTH(256),
      	.WAIT_STATE  (0)
		) uut(
        .prst     (apb_if.prst),
        .pclk_en  (apb_if.pclk_en),
		.pclk     (pclk),
		.psel     (apb_if.psel),
		.paddr    (apb_if.paddr),
		.prdata   (apb_if.prdata),
		.pwdata   (apb_if.pwdata),
		.pwrite   (apb_if.pwrite),
		.penable  (apb_if.penable),
		.pready   (apb_if.pready),
		.pslverror(apb_if.pslverror));
  	
  	// Initial state
	initial begin  
		// create the test
        test_base = new("First_test",apb_if);
		// run the reset
		apb_if.drive_reset_state();
	end
  
  	// CLock
  	always #5 pclk = ~pclk;

  	// WR/RD
  	initial begin: sim_run
  		test_base.test_run();
  	end
  
	// SIM controller
	initial begin
		$dumpfile("dump.vcd");
		$dumpvars();
        wait(apb_if.sim_done.triggered);
	    apb_print("SIM done",LOW,INFO);
		$finish();
	end
endmodule: apb_tb_top