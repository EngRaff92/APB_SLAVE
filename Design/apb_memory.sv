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
	APB memory with the CYCLED option, this slave usually return the read data or store the write data within 1 clock cycle unless the 
	CYCLED_MEM is set, the latter will be resolved in 1 cycle only regardless of the operation requested.
	It runs at the same frequency as the other block to avoid CDC and SYNC blocks in between. There is no gating procedure since we do not
	want to switch off the memory. Anyway to avoid increasing power consumption nothing is zeroed and CS will be gated in case of power gating
	or in case of CLOCK gating.
	The memory is initialized with incremantal values, unless ZERO_MEM is set to 1 then all zero will be loaded at wake up time
*/

`ifndef COCOTB_SIM
// Main Inclusion
`include "./apb_design_includes.sv"
`else 
// Main Inclusion
`include "/Volumes/My_Data/MY_SYSTEMVERILOG_UVM_PROJECTS/APB_PROTOCOL/APB_SLAVE/Design/apb_design_includes.sv"
`endif

// Main Module
module apb_memory
	#(
		parameter MEMORY_DEPTH 	= 256,	// Number of memory slots
		parameter REG_WIDTH  	= 32,	// Data width
		parameter ZERO_MEM		= 0   	// If set to 1 then it will zero out the entire memory at the beginning of the SIM
	)
	(
`ifdef CYCLED_MEM
		input logic 							mem_clk,	// memory clock running at same master frequency to avoid SYNC
`endif
		input logic 							mem_ares,	// memory async reset used not only if memoery clocked is enabled
		input logic 							mem_wr_en,	// write enable
		input logic 							mem_cs,		// memory slave chip select to enable the memory functionality
		input logic [REG_WIDTH-1:0] 			mwdata,		// memory write data
		input logic [$clog2(MEMORY_DEPTH)-1:0] 	maddr,		// memory address
		output logic [REG_WIDTH-1:0] 			mrdata,		// memory read data
		output logic 							mem_ready	// memory ready tied to 1 if memory not clocked
		);

	// Main memory
	logic [REG_WIDTH-1:0] mem_apb [MEMORY_DEPTH-1:0];
	
	// Memory RD/WR main process resolved in no cycle
`ifdef CYCLED_MEM
	// Init
	initial begin: memory_init
		for(int i = 0; i<MEMORY_DEPTH; i++) begin
			if(ZERO_MEM == 1)
				mem_apb[i] = 0;
			else 
				mem_apb[i] = i;
		end
	end
  
	always_ff @(posedge mem_clk or posedge mem_ares) begin: mem_rd_wr_logic
		if(mem_cs & ~mem_ares) begin
			if(mem_wr_en)
				mem_apb[maddr] <= mwdata;
			else
				mrdata <= mem_apb[maddr];
		end
		else begin
			mrdata <= 'hx;
		end
	end 
`else 
	always_comb begin: mem_rd_wr_logic      
		if(mem_ares) begin: init_memory 
			for(int i = 0; i<MEMORY_DEPTH; i++) begin
				if(ZERO_MEM == 1)
					mem_apb[i] = 0;
				else 
					mem_apb[i] = i;
			end
		end 
		else begin 
			if(mem_cs) begin
				if(mem_wr_en)
					mem_apb[maddr] = mwdata;
				else
					mrdata = mem_apb[maddr];
			end
		end
	end 
`endif 

`ifdef CYCLED_MEM
	// Since the memory fulfils the RD/WR operation in 1 clock we can delay the ready by one clock
	logic [1:0] reg_ready;
	// The memory will not be ready when the CS is high and 1 operation is requested (WR or RD)
	always_ff @(posedge mem_clk or posedge mem_ares) begin : ready_registering
		if(mem_ares) begin
			reg_ready <= 2'b00;
		end 
		else begin
			// Check if a write or read then delay
			if(mem_wr_en)
				reg_ready[0] <= mem_cs & mem_wr_en;
			else
				reg_ready[0] <= mem_cs & (~mem_wr_en);
			// Final delayed version
			reg_ready[1] <= reg_ready[0];
		end
	end
	// Assign teh output ready
	assign mem_ready = reg_ready;
`else 
	// Since memory will not consume cycles unless a parameter is set will be always ready
	assign mem_ready = 1;
`endif
endmodule