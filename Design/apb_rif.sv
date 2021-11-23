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

/* This file contains the APB slave implementation used to access 7 different registers
 * 
 *
 * 
*/

`include "/Volumes/My_Data/MY_SYSTEMVERILOG_UVM_PROJECTS/APB_PROTOCOL/APB_SLAVE/Design/apb_design_includes.sv"

// Main Module
module apb_rif #(
  // Parameter Declaration
  parameter REG_WIDTH 	= 32
  )
(
	// Port Declaration
  	input logic 					rif_clk,    // Clock
  	input logic 					rif_arst,   // Asynchronous reset active high
  	input logic 					rif_write,  // If 0 -> Read if 1 -> Write
  	input logic 					rif_cs,     // States if the slave has been properly selected 
  	input logic [REG_WIDTH-1:0] 	rif_addr, 	// Address coming into the bus
  	input logic [REG_WIDTH-1:0] 	rif_wdata,  // Write Data coming into the bus
  	output logic[REG_WIDTH-1:0] 	rif_rdata,  // Read Data coming out the bus
  	output logic 					rif_error,  // Give error in few specific conditions only 
  	output logic 					rif_ready   // Is controlled by the slave and claims if the specifc slave is busy or not
);

    // Sets of registers (Status register only) Access Policy is RO
    logic [REG_WIDTH-1:0] Status_1, Status_2, Status_3;
    // Sets of registers (Data Register) Access Policy is RW as long as the EN is 1 otherwise is WO
    logic [REG_WIDTH-1:0] Data_1, Data_2, Data_3;
    // Write enable if set to 0 makes the Register as W0 otherwise the policy is RW
    logic [2:0] Write_Reg_En;
    // Register Access Process
    logic error_handler;
    logic wr_rq, rd_rq;

    // Register decoder we are addressing 1Word at time so remove the first 2 bits
    logic [REG_WIDTH-1:0] reg_dec, reg_dec_dly;
    
    assign reg_dec = rif_addr >> 2;
    always_ff@(posedge rif_clk or posedge rif_arst) begin
      if(rif_arst)  reg_dec_dly <= 'h0;
      else      	reg_dec_dly <= reg_dec;
    end
  	
  	// Assign the WR_REQUEST and RD_REQUEST
  	assign wr_rq = rif_write & rif_cs;
  	assign rd_rq = ~rif_write & rif_cs;

  	// Register the request to be used for the READY signal
  	logic [1:0] regsistered_request;
  	always_ff @(posedge rif_clk or posedge rif_arst) begin : request_reg
  		if(rif_arst) begin
  			regsistered_request <= 2'b11;
  		end else begin
  			// Regardless of the read of write request we have to register the CS
  			regsistered_request[0] <= (~rif_cs);
  			regsistered_request[1] <= regsistered_request[0];
  		end
  	end
    // Status Register Process
    always_ff @(posedge rif_clk or posedge rif_arst) begin : proc_status
      if(rif_arst) begin
        Status_1    <= 'h0; 
        Status_2    <= 'h0;
        Status_3    <= 'h0;
      end 
      else begin
        Status_1[0]   <= (reg_dec_dly == 'd4) ? (~(wr_rq & Write_Reg_En[0]) ? 'b1 : Status_1) : Status_1; 
        Status_2[0]   <= (reg_dec_dly == 'd5) ? (~(wr_rq & Write_Reg_En[1]) ? 'b1 : Status_2) : Status_2;
        Status_3[0]   <= (reg_dec_dly == 'd6) ? (~(wr_rq & Write_Reg_En[2]) ? 'b1 : Status_3) : Status_3;
      end
    end

    // Register posedge and Access
    always_ff @(posedge rif_clk or posedge rif_arst) begin : proc_reg
      if(rif_arst) begin
        Data_1         	<= '0;
        Data_2         	<= '0;
        Data_3         	<= '0;
        Write_Reg_En   	<= '0;
        error_handler  	<= '0;
      end 
      else begin: reg_decoder
      	case(reg_dec)
          // Wr	ite modifier register
		    	'd0:	begin 
			            if(wr_rq) begin
			            	Write_Reg_En 	<= rif_wdata;
			            	error_handler 	<= 1'b0;
			            end
			            else if(rd_rq) begin
			              	rif_rdata    	<= Write_Reg_En;
			              	error_handler 	<= 1'b0;
			            end
		      			end 
					// Status Register
					'd1:  	begin 
								if(rd_rq) begin	
									rif_rdata  		<= Status_1; 
									error_handler 	<= 1'b0;
								end
								else if(wr_rq) begin
									error_handler 	<= 1'b1;
									rif_rdata 		<= 'h0;
								end		
							end
					'd2:  	begin 
								if(rd_rq) begin
									error_handler 	<= 1'b0;
									rif_rdata  		<= Status_2; 
								end
								else if(wr_rq) begin
									error_handler 	<= 1'b1;
									rif_rdata 		<= 'h0;
								end							
							end
					'd3:  	begin 
								if(rd_rq) begin
									rif_rdata  		<= Status_3;
									error_handler 	<= 1'b0;
								end	 
								else if(wr_rq) begin
									error_handler 	<= 1'b1;
									rif_rdata 		<= 'h0;
								end						
							end
					// Data Register
					'd4:  	begin 
								if(wr_rq & Write_Reg_En[0]) begin
									Data_1 			<= rif_wdata;
									error_handler 	<= 1'b0;
								end
								else if(wr_rq & ~Write_Reg_En[0]) begin
								  	error_handler <= 1'b1;
								end
								else if(rd_rq) begin
								  	rif_rdata 		<= Data_1; 
								  	error_handler 	<= 1'b0;
								end
						    	end
					'd5:  	begin 
						        if(wr_rq & Write_Reg_En[1]) begin
						          	Data_2 			<= rif_wdata;
						          	error_handler 	<= 1'b0;
						        end
						        else if(wr_rq & ~Write_Reg_En[1]) begin
						          	error_handler <= 1'b1;
						        end
						        else if(rd_rq) begin
						          	rif_rdata 		<= Data_2; 
						          	error_handler 	<= 1'b0;
						        end
					    	end
					'd6:  	begin 
						    	if(wr_rq & Write_Reg_En[2]) begin
						          	Data_3 			<= rif_wdata;
						          	error_handler 	<= 1'b0;
						        end
						        else if(wr_rq & ~Write_Reg_En[2]) begin
						          	error_handler <= 1'b1;
						        end
						        else if(rd_rq) begin
						          	rif_rdata 		<= Data_3; 
						          	error_handler 	<= 1'b0;
						        end
					    	end
					// Registers not mapped
					default:  begin error_handler <= 1'b1; end
        endcase // reg_dec
      end
    end

    // assign the Error
    assign rif_error = error_handler;

    // Assign the ready signal
    assign rif_ready = &(regsistered_request);

endmodule : apb_rif