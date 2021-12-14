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
`ifndef ICARUS
`include "/Volumes/My_Data/MY_SYSTEMVERILOG_UVM_PROJECTS/APB_PROTOCOL/APB_SLAVE/Design/apb_design_includes.sv"
`endif

// Main Module
module apb_decoder
	#(
		parameter N_OF_SLAVES 		= 'h8,
		parameter SLV0_START_ADDR = 'h0,
		parameter SLV0_END_ADDR 	= 'h0,
		parameter SLV1_START_ADDR = 'h0,
		parameter SLV1_END_ADDR 	= 'h0,
		parameter SLV2_START_ADDR = 'h0,
		parameter SLV2_END_ADDR 	= 'h0,
		parameter SLV3_START_ADDR = 'h0,
		parameter SLV3_END_ADDR 	= 'h0,
		parameter SLV4_START_ADDR = 'h0,
		parameter SLV4_END_ADDR 	= 'h0,
		parameter SLV5_START_ADDR = 'h0,
		parameter SLV5_END_ADDR 	= 'h0,
		parameter SLV6_START_ADDR = 'h0,
		parameter SLV6_END_ADDR 	= 'h0,
		parameter SLV7_START_ADDR = 'h0,
		parameter SLV7_END_ADDR 	= 'h0,
		parameter DEC_WIDTH 		  = 32
	)
	(
		input logic [DEC_WIDTH-1:0] 		dec_mst_addr,												// Address from Master (PADDR)
		input logic 										dec_mst_wr_rd_en,										// write or read operation from Master (PWRITE)
		input logic 										dec_mst_cs,													// chip select from Master (PENABLE)
		input logic 										dec_slvx_ready[N_OF_SLAVES:0],		  // ready signal from slave 0
    input logic [DEC_WIDTH-1:0] 		dec_slvx_rd_data[N_OF_SLAVES:0],		// read data from slave 0
		output logic [N_OF_SLAVES-1:0] 	dec_slv_cs,													// chip select which identifies the slave selected (ONE HOT)
		output logic [DEC_WIDTH-1:0] 		dec_mst_rdata,											// valid read data from selected slave
		output logic 										dec_slv_ready,											// valid ready from selected slave
		output logic 										dec_slv_wr_rd_en										// Write or read enable to be rooted to the proper slave
		);
  
	// Local parameters and checks
	localparam MAX_N_OF_SLVS = 8;
	initial begin
		assert(N_OF_SLAVES <= MAX_N_OF_SLVS) else $error("Number of slaves used is greater the supported number");
	end

	// Main decoder logic the decode is made by 1 bit more to detect no SLV selected
	logic [MAX_N_OF_SLVS:0] internal_decode;
	always_comb begin: decoder_logic
		if((dec_mst_addr >= SLV0_START_ADDR) && (dec_mst_addr <= SLV0_END_ADDR)) 
			internal_decode = `SLV0;
		else if((dec_mst_addr >= SLV1_START_ADDR) && (dec_mst_addr <= SLV1_END_ADDR))
			internal_decode = `SLV1;
		else if((dec_mst_addr >= SLV2_START_ADDR) && (dec_mst_addr <= SLV2_END_ADDR))
			internal_decode = `SLV2;
		else if((dec_mst_addr >= SLV3_START_ADDR) && (dec_mst_addr <= SLV3_END_ADDR))
			internal_decode = `SLV3;
		else if((dec_mst_addr >= SLV4_START_ADDR) && (dec_mst_addr <= SLV4_END_ADDR))
			internal_decode = `SLV4;
		else if((dec_mst_addr >= SLV5_START_ADDR) && (dec_mst_addr <= SLV5_END_ADDR))
			internal_decode = `SLV5;
		else if((dec_mst_addr >= SLV6_START_ADDR) && (dec_mst_addr <= SLV6_END_ADDR))
			internal_decode = `SLV6;
		else if((dec_mst_addr >= SLV7_START_ADDR) && (dec_mst_addr <= SLV7_END_ADDR))
			internal_decode = `SLV7;
		else 
			internal_decode = `NSLV; 
	end

	// Assign the internal decode value to the chip select only and only if the MASTER is selecting 
	// the decoder, essentially when the PENABLE is hight so that the TRX can start 
	genvar i;
	generate
		for(i=0; i<N_OF_SLAVES; i++)
			assign dec_slv_cs[i] = internal_decode[i] & dec_mst_cs;
	endgenerate

	// Propagate the PWRITE to the slaves (dec_mst_wr_rd_en is out PWRITE)
	assign dec_slv_wr_rd_en = dec_mst_wr_rd_en;
  	
  	// set the RD_DATA according to the slave selection make sure to not use the MSB of internal decode
  	always_comb begin
      if(internal_decode[MAX_N_OF_SLVS]) 
        dec_mst_rdata = '0;
      else if(internal_decode[0])
        dec_mst_rdata = dec_slvx_rd_data[0];
      else if(internal_decode[1])
        dec_mst_rdata = dec_slvx_rd_data[1];
      else if(internal_decode[2])
        dec_mst_rdata = dec_slvx_rd_data[2];
      else if(internal_decode[3])
        dec_mst_rdata = dec_slvx_rd_data[3];
      else if(internal_decode[4])
        dec_mst_rdata = dec_slvx_rd_data[4];
      else if(internal_decode[5])
        dec_mst_rdata = dec_slvx_rd_data[5];
      else if(internal_decode[6])
        dec_mst_rdata = dec_slvx_rd_data[6];
      else if(internal_decode[7])
        dec_mst_rdata = dec_slvx_rd_data[7];
    end
  	
  	always_comb begin
      if(internal_decode[MAX_N_OF_SLVS]) 
        dec_slv_ready = '0;
      else if(internal_decode[0])
        dec_slv_ready = dec_slvx_ready[0];
      else if(internal_decode[1])
        dec_slv_ready = dec_slvx_ready[1];
      else if(internal_decode[2])
        dec_slv_ready = dec_slvx_ready[2];
      else if(internal_decode[3])
        dec_slv_ready = dec_slvx_ready[3];
      else if(internal_decode[4])
        dec_slv_ready = dec_slvx_ready[4];
      else if(internal_decode[5])
        dec_slv_ready = dec_slvx_ready[5];
      else if(internal_decode[6])
        dec_slv_ready = dec_slvx_ready[6];
      else if(internal_decode[7])
        dec_slv_ready = dec_slvx_ready[7];
    end

`ifdef DEBUG_XVALUES
		logic dbl;
		logic [31:0] db;
		assign dbl 	= dec_slvx_ready[2];
		assign db 	= dec_slvx_rd_data[2];
`endif
endmodule: apb_decoder

/*
	// lect the RD_DATA according to the slave selection make sure to not use the MSB of internal decode
  	always_comb begin
      if(internal_decode[MAX_N_OF_SLVS])
        dec_mst_rdata = '0;
      else begin
        dec_mst_rdata = '0;
        for(int j=1;j<=N_OF_SLAVES;j++) begin
          if(internal_decode[MAX_N_OF_SLVS-1:0] == j)
            dec_mst_rdata = dec_slvx_rd_data[j];
//           else
//             dec_mst_rdata = '0;
        end
      end
    end
  
//   	genvar j;
//     generate 
//       for(j=1;j<=N_OF_SLAVES;j++) begin
//         assign dec_mst_rdata = (internal_decode[MAX_N_OF_SLVS] ? '0 : ((internal_decode[MAX_N_OF_SLVS-1:0] == j) ? dec_slvx_rd_data[j] : '0));
//       end
//     endgenerate 
  	
  	always_comb begin
      if(internal_decode[MAX_N_OF_SLVS])
        dec_slv_ready = '0;
      else begin
        dec_slv_ready = '0;
        for(int h=1;h<=N_OF_SLAVES;h++) begin
          if(internal_decode[MAX_N_OF_SLVS-1:0] == h)
            dec_slv_ready = dec_slvx_ready[h];
//           else
//             dec_slv_ready = '0;
        end
      end
    end
  
	// PREADY combo logic according to the CS (RIF is slower then the Memory by 1 clock cycle)
//     genvar h;
//     generate 
//       for(h=1;h<=N_OF_SLAVES;h++) begin
//         assign dec_slv_ready = (internal_decode[MAX_N_OF_SLVS] ? '0 : ((internal_decode[N_OF_SLAVES:0] == h) ? dec_slvx_ready[h] : '0));
//       end
//     endgenerate 
*/