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
	The APB decoder allows to select the sub slave according to the address, it does not perform any additional operation
	except the SLV selection based on the address provided. It then provides the VALID read data and ready signal according
	to the selector.

	The parametrized version of such design would get the number of slaves as input and the start and end address value
	then it generates the proper decode signal (making sure is one hot to avoid muliple erroneous slave selection)
*/
`include "/Volumes/My_Data/MY_SYSTEMVERILOG_UVM_PROJECTS/APB_PROTOCOL/APB_SLAVE/Design/apb_design_includes.sv"

// Main Module
module apb_decoder
	#(
		parameter N_OF_SLAVES 		= 'h2,
		parameter SLV0_START_ADDR 	= 'h0,
		parameter SLV0_END_ADDR 	= 'h3C,
		parameter SLV1_START_ADDR 	= 'h40,
		parameter SLV1_END_ADDR 	= 'hFF,
		parameter DEC_WIDTH 		= 32
	)
	(
		input logic [DEC_WIDTH-1:0] 			dec_mst_addr,		// Address from Master (PADDR)
		input logic 							dec_mst_wr_rd_en,	// write or read operation from Master (PWRITE)
		input logic 							dec_mst_cs,			// chip select from Master (PENABLE)
		input logic 							dec_slv0_ready,		// ready signal from slave 0
		input logic 							dec_slv1_ready,		// ready signal from slave 1
		input logic [DEC_WIDTH-1:0] 			dec_slv0_rd_data,	// read data from slave 0
		input logic [DEC_WIDTH-1:0] 			dec_slv1_rd_data,	// read data from slave 1
		output logic [N_OF_SLAVES-1:0] 			dec_slv_cs,			// chip select which identifies the slave selected (ONE HOT)
		output logic [DEC_WIDTH-1:0] 			dec_mst_rdata,		// valid read data from selected slave
		output logic 							dec_slv_ready,		// valid ready from selected slave
		output logic 							dec_slv_wr_rd_en	// Write or read enable to be rooted to the proper slave
		);

	// Main decoder logic
	logic [N_OF_SLAVES-1:0] internal_decode;
	always_comb begin: decoder_logic
		if((dec_mst_addr >= SLV0_START_ADDR) && (dec_mst_addr <= SLV0_END_ADDR)) 
			internal_decode = `SLV0;
		else if((dec_mst_addr >= SLV1_START_ADDR) && (dec_mst_addr <= SLV1_END_ADDR))
			internal_decode = `SLV1;
		else 
			internal_decode = `NSLV; 
	end

	// Assign the internal decode value to the chip select only and only if the MASTER is selecting 
	// the decoder, essentially when the PENABLE is hight so that the TRX can start 
	assign dec_slv_cs[0] = internal_decode[0] & dec_mst_cs;
	assign dec_slv_cs[1] = internal_decode[1] & dec_mst_cs;

	// Propagate the PWRITE to the slaves (dec_mst_wr_rd_en is out PWRITE)
	assign dec_slv_wr_rd_en = dec_mst_wr_rd_en;

	// Select the RD_DATA according to the slave selection
	always_comb begin: rd_data_selector
		if(internal_decode == `SLV0) 		// SLV0
			dec_mst_rdata = dec_slv0_rd_data;
		else if(internal_decode == `SLV1)  	// SLV1
			dec_mst_rdata = dec_slv1_rd_data;
	end

	// PREADY combo logic according to the CS (RIF is slower then the Memory by 1 clock cycle)
	always_comb begin: ready_selector
		if(internal_decode == `SLV0) 		// SLV0
			dec_slv_ready = dec_slv0_ready;
		else if(internal_decode == `SLV1)  	// SLV1
			dec_slv_ready = dec_slv1_ready;
	end
endmodule: apb_decoder