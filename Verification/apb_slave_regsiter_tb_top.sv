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

`ifdef ICARUS
`include "/Volumes/My_Data/MY_SYSTEMVERILOG_UVM_PROJECTS/APB_PROTOCOL/APB_SLAVE/Verification/apb_verif_includes.sv"
`else 
`include "./apb_verif_includes.sv"
`endif

// Main TB module
module tb_top;
	// Local Parameters
	parameter REG_WIDTH = 32;
	// Variables
	bit pclk;
	bit pclk_en;
	bit prst;
	bit penable;
	bit pwrite;
	bit psel;
	bit [REG_WIDTH-1:0]	paddr;
	bit [REG_WIDTH-1:0]	pwdata;
	logic [REG_WIDTH-1:0] prdata, d;
	logic pslverror;
	logic pready;
    
    `ifdef ICARUS
    // Icarus does not support events so replaced with logic
	bit rst_done;
    bit sim_done;
    `else
	// local event
	event rst_done;
	event sim_done;
    `endif

    // TB memory to inspect the Internal memory
	logic [31:0] tb_mem_apb [255:0];

	// DUT
	apb_slave_controller#(
		.N_OF_SLAVES (2),
    	.REG_WIDTH   (32),
      	.ZERO_MEM    (0),
      	.DEC_WIDTH   (32),
      	.MEMORY_DATA (32),
      	.MEMORY_DEPTH(256),
      	.WAIT_STATE  (0)
		) uut(.*);
  	
  	// Initial state
	initial begin  
	    pclk_en = 1;
	    prst 	= 0;
	    #10;
	    prst 	= 1;
	    #5;
	    prst 	= 0;
	    `ifdef ICARUS		
	    rst_done = 1;
	    `else
	    ->> rst_done;
	    `endif
	end
  
  	// CLock
  	always #5 pclk = ~pclk;

`ifdef ICARUS
	// Print Severity
	typedef enum int {
		LOW 	= 0,
		HIGH	= 1,
		DEBUG 	= 2
	} debug_print_t;

	typedef enum int {
		INFO 	= 0,
		ERROR	= 1,
		FATAL 	= 2
	} severity_print_t;

	// If no verbosity is set by outside then we set it as LOW
	// General global level set by using defines
	`ifdef VERB_LOW
	debug_print_t global_verbosity	= LOW;
	`elsif VERB_HIGH
	debug_print_t global_verbosity	= HIGH;
	`elsif VERB_DEBUG
	debug_print_t global_verbosity	= DEBUG;
	`else 
	 debug_print_t global_verbosity = LOW;
	`endif

	// Global Header used
	string header = "APB_TEST: -- ";
	// ########################################################################################################
	// Setting Up the ENV according to the Define used in the ENV
	// ########################################################################################################
	// General Print used by the whole Environment except the UVM or PYUVM testbench
	function void apb_print(input string Message, input debug_print_t verbosity, input severity_print_t sev);
		// Set the internal message
		string mex;
		case(verbosity)
			LOW:	mex = {header,"INFO"," ",Message};
			HIGH:	mex = {header,"HIGH"," ",Message};
			DEBUG:	mex = {header,"DEBUG"," ",Message};
			default:mex = {header,"INFO"," ",Message};
		endcase
		if(sev == INFO) begin
			case(verbosity)
				LOW:		begin if(global_verbosity >= LOW) 	$display(mex); end
				HIGH:		begin if(global_verbosity >= HIGH)	$display(mex); end
				DEBUG:		begin if(global_verbosity >= DEBUG)	$display(mex); end
				default:	$display(mex);
			endcase
		end
		else if(sev == ERROR) begin
			$error(mex);
		end
		else begin 
			$fatal(1,mex);
		end
	endfunction

  	// Task for RD and WR
  	task apb_wr(input bit [31:0] addr, bit [31:0] wdata);
	    if(~pready)
	    	@(posedge pready);
        apb_print($sformatf("Start WR TRX at address: %0h with Data: %0h",addr,wdata),HIGH,INFO);
	    psel 		= 1;
	    paddr		= addr;
	    pwrite		= 1;
	    pwdata		= wdata;
	    @(posedge pclk);
	    penable 	= 1;
      	// Transfer END
        @(posedge pclk);
      	psel		= 0;
	    penable 	= 0;
        pwrite		= 0;
	    // RIF access END
        @(posedge pclk);
	    if(~pready)
	    	@(posedge pready);
  	endtask
  
  	task apb_rd(input bit [31:0] addr, output bit [31:0] rdata);
	    if(~pready)
	     	@(posedge pready);
        apb_print($sformatf("Start RD TRX at address: %0h",addr),HIGH,INFO);
	    psel 		= 1;
	    paddr		= addr;
	    pwrite		= 'h0;
	    pwdata		= 'h0;
	    @(posedge pclk);
	    penable 	= 1;
        // Transfer END
        @(posedge pclk);
	    psel		= 0;
	    penable 	= 0;
        @(posedge pclk);
        // RIF access END
	    rdata 		= prdata;
	    if(~pready)
	    	@(posedge pready);
	    apb_print($sformatf("Data read at addr: %0h is: %0h", addr,rdata),HIGH,INFO);
  	endtask
 `endif

  	// WR/RD
  	initial begin
  		`ifdef ICARUS
  		if(rst_done == 0)
	    	@(posedge rst_done);
	    `else
	    wait(rst_done.triggered);
	    `endif
	    apb_print("RST done",LOW,INFO);
        apb_wr(`wren,'b100);
        apb_rd(`wren, d);
        apb_wr(`data3,'hA);
        apb_rd(`data3, d);
        apb_rd(`status1, d);
        apb_wr(`data1,'hA);
        apb_rd(`data1, d);
      	for(int i = `MEM_ADDR_START; i < `MEM_ADDR_END; i+=4) begin
        	apb_wr(i,i+'hA);
        	apb_rd(i,d);
        	if(d != (i+'hA))
        		apb_print($sformatf("Value: %0h at Addres in Memory: %0h is not equal to the expected %0h",d,i,(i+'hA)),LOW,FATAL);
      	end
      	`ifdef ICARUS		
	    sim_done = 1;
	    `else
	    ->> sim_done;
	    `endif
  	end
  
	// SIM controller
	initial begin
		$dumpfile("dump.vcd");
		$dumpvars();
  		`ifdef ICARUS
  		if(rst_done == 0)
          @(posedge sim_done);
	    `else
        wait(sim_done.triggered);
	    `endif
	    apb_print("SIM done",LOW,INFO);
		$finish();
	end
  
  	assign tb_mem_apb = uut.u_apb_mem.mem_apb;
endmodule: tb_top