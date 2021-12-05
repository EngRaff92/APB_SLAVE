## RIF template
# rif = """// Main Module
# module $rif_name #(
#     // Parameter Declaration
#     parameter REG_WIDTH             = 32,
#     parameter ERROUT_IF_NOT_ACCESS  = 1
#   )
# (
#     // Port Declaration
#     input logic                   rif_clk,            // Clock
#     input logic                   rif_arst,           // Asynchronous reset active high
#     input logic                   rif_write,          // If 0 -> Read if 1 -> Write
#     input logic                   rif_cs,             // States if the slave has been properly selected 
#     input logic [REG_WIDTH-1:0]   rif_addr,           // Address coming into the bus
#     input logic [REG_WIDTH-1:0]   rif_wdata,          // Write Data coming into the bus
#     // Sets of input ports for HW write access
#     input logic [REG_WIDTH-1:0]   $hw_input_port,
#     // Sets of output ports for HW read access
#     output logic [REG_WIDTH-1:0]  $hw__port,
#     output logic [REG_WIDTH-1:0]  rif_rdata,          // Read Data coming out the bus
#     output logic                  rif_error,          // Give error in few specific conditions only 
#     output logic                  rif_ready           // Is controlled by the slave and claims if the specifc slave is busy or not
# );

#     // Sets of DEC flags
#     logic data_status_1_dec; 
#     logic data_status_2_dec;
#     logic data_status_3_dec;
#     logic data_1_dec;
#     logic data_2_dec;
#     logic data_3_dec;
#     logic write_enable_dec;

#     // DESC: Sets of registers Access Policy is RW if RO according to the enable then it should be gated externally
#     logic [REG_WIDTH-1:0] data_1;
#     logic [REG_WIDTH-1:0] data_2;
#     logic [REG_WIDTH-1:0] data_3;

#     // DESC: write enable signal
#     logic [2:0] write_enable;

#     // Register Access Process
#     logic error_handler;
#     logic wr_rq, rd_rq;

#     // Register decoder we are addressing 1Word at time so remove the first 2 bits
#     logic [REG_WIDTH-1:0] reg_dec, reg_dec_dly;
    
#     assign reg_dec = rif_addr >> 2;
#     always_ff@(posedge rif_clk or posedge rif_arst) begin
#       if(rif_arst)  reg_dec_dly <= 'h0;
#       else          reg_dec_dly <= reg_dec;
#     end
    
#     // Assign the WR_REQUEST and RD_REQUEST
#     assign wr_rq = rif_write & rif_cs;
#     assign rd_rq = ~rif_write & rif_cs;

#     // Register the request to be used for the READY signal
#     logic [1:0] regsistered_request;
#     always_ff @(posedge rif_clk or posedge rif_arst) begin : request_reg
#       if(rif_arst) begin
#         regsistered_request <= 2'b11;
#       end else begin
#         // Regardless of the read of write request we have to register the CS
#         regsistered_request[0] <= (~rif_cs);
#         regsistered_request[1] <= regsistered_request[0];
#       end
#     end

#     // Address decoding with full combo logic
#     always_comb begin: addres_decoding
#       // Initialize
#       data_1_dec        = 0;  
#       data_2_dec        = 0;
#       data_3_dec        = 0;
#       write_enable_dec  = 0;
#       data_status_1_dec = 0;
#       data_status_2_dec = 0;
#       data_status_3_dec = 0;
#       // Select using the address
#       case (rif_addr) begin
#         `register_data1:          begin data_1_dec = 1; end
#         `register_data2:          begin data_1_dec = 1; end
#         `register_data3:          begin data_1_dec = 1; end
#         `register_write_enable:   begin data_1_dec = 1; end
#         `register_data_status_1:  begin data_1_dec = 1; end
#         `register_data_status_1:  begin data_1_dec = 1; end
#         `register_data_status_1:  begin data_1_dec = 1; end
#         default: begin 
#           if(ERROUT_IF_NOT_ACCESS)  rif_error = 1;
#           else                      rif_error = 0;
#         end
#       end
#     end

#     // Status Register Process
#     always_ff @(posedge rif_clk or posedge rif_arst) begin : proc_status
#       if(rif_arst) begin
#         Status_1    <= 'h0; 
#         Status_2    <= 'h0;
#         Status_3    <= 'h0;
#       end 
#       else begin
#         Status_1[0]   <= (reg_dec_dly == 'd4) ? (~(wr_rq & Write_Reg_En[0]) ? 'b1 : Status_1) : Status_1; 
#         Status_2[0]   <= (reg_dec_dly == 'd5) ? (~(wr_rq & Write_Reg_En[1]) ? 'b1 : Status_2) : Status_2;
#         Status_3[0]   <= (reg_dec_dly == 'd6) ? (~(wr_rq & Write_Reg_En[2]) ? 'b1 : Status_3) : Status_3;
#       end
#     end

#     // Register posedge and Access
#     always_ff @(posedge rif_clk or posedge rif_arst) begin : proc_reg
#       if(rif_arst) begin
#         Data_1          <= '0;
#         Data_2          <= '0;
#         Data_3          <= '0;
#         Write_Reg_En    <= '0;
#         error_handler   <= '0;
#       end 
#       else begin: reg_decoder
#         case(reg_dec)
#           // Wr ite modifier register
#           'd0:  begin 
#                   if(wr_rq) begin
#                     Write_Reg_En  <= rif_wdata;
#                     error_handler   <= 1'b0;
#                   end
#                   else if(rd_rq) begin
#                       rif_rdata     <= Write_Reg_En;
#                       error_handler   <= 1'b0;
#                   end
#                 end 
#           // Status Register
#           'd1:    begin 
#                 if(rd_rq) begin 
#                   rif_rdata     <= Status_1; 
#                   error_handler   <= 1'b0;
#                 end
#                 else if(wr_rq) begin
#                   error_handler   <= 1'b1;
#                   rif_rdata     <= 'h0;
#                 end   
#               end
#           'd2:    begin 
#                 if(rd_rq) begin
#                   error_handler   <= 1'b0;
#                   rif_rdata     <= Status_2; 
#                 end
#                 else if(wr_rq) begin
#                   error_handler   <= 1'b1;
#                   rif_rdata     <= 'h0;
#                 end             
#               end
#           'd3:    begin 
#                 if(rd_rq) begin
#                   rif_rdata     <= Status_3;
#                   error_handler   <= 1'b0;
#                 end  
#                 else if(wr_rq) begin
#                   error_handler   <= 1'b1;
#                   rif_rdata     <= 'h0;
#                 end           
#               end
#           // Data Register
#           `register_data1:    begin 
#                 if(wr_rq & Write_Reg_En[0]) begin
#                   Data_1      <= rif_wdata;
#                   error_handler   <= 1'b0;
#                 end
#                 else if(wr_rq & ~Write_Reg_En[0]) begin
#                     error_handler <= 1'b1;
#                 end
#                 else if(rd_rq) begin
#                     rif_rdata     <= Data_1; 
#                     error_handler   <= 1'b0;
#                 end
#                   end
#           `register_data2:    begin 
#                     if(wr_rq & Write_Reg_En[1]) begin
#                         Data_2      <= rif_wdata;
#                         error_handler   <= 1'b0;
#                     end
#                     else if(wr_rq & ~Write_Reg_En[1]) begin
#                         error_handler <= 1'b1;
#                     end
#                     else if(rd_rq) begin
#                         rif_rdata     <= Data_2; 
#                         error_handler   <= 1'b0;
#                     end
#                 end
#           `register_data3:    begin 
#                   if(wr_rq & Write_Reg_En[2]) begin
#                         Data_3      <= rif_wdata;
#                         error_handler   <= 1'b0;
#                     end
#                     else if(wr_rq & ~Write_Reg_En[2]) begin
#                         error_handler <= 1'b1;
#                     end
#                     else if(rd_rq) begin
#                         rif_rdata     <= Data_3; 
#                         error_handler   <= 1'b0;
#                     end
#                 end
#           // Registers not mapped
#           default:  begin error_handler <= 1'b1; end
#         endcase // reg_dec
#       end
#     end

#     // assign the Error
#     assign rif_error = error_handler;

#     // Assign the ready signal
#     assign rif_ready = &(regsistered_request);

# endmodule : apb_rif"""