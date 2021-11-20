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

`include "/Volumes/My_Data/MY_SYSTEMVERILOG_UVM_PROJECTS/APB_PROTOCOL/APB_SLAVE/Design/apb_design_includes.sv"

module apb_slave_controller #(
  // Parameter Declaration and propagation
  parameter N_OF_SLAVES   = 2,
  parameter REG_WIDTH     = 32,   // Single register WIDTH (single WORD alligned acces)
  parameter WAIT_STATE    = 0,    // this will basically used in case of Slower sub-slaves
  parameter MEMORY_DEPTH  = 256,  // Number of memory slots   
  parameter MEMORY_DATA   = 32,   // Data width
  parameter ZERO_MEM      = 0,    // If set to 1 then it will zero out the entire memory at the beginning of the SIM
  parameter DEC_WIDTH     = 32  // Decoder Parameter
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
    // Internal signals
    logic [WAIT_STATE-1:0] cnt;
    logic g_clk;
      
    // FSM state
    typedef enum bit [1:0] {
      IDLE          = 2'd0,
      SETUP_PHASE   = 2'd1,
      WRITE_PHASE   = 2'd2,
      READ_PHASE    = 2'd3
    }apb_state_t;
    // Declare current2state and Next state
    apb_state_t cstate, nstate;

    // Internal Clock gating
    assign g_clk = pclk & pclk_en;
    
    // Wait State Logic
    always_ff @(posedge g_clk or posedge prst) begin
      if(prst)  cnt <= 0;
      else      cnt <= cnt + 1'b1;
    end

    // State Change Clocked
    always_ff @(posedge g_clk or posedge prst) begin: state_change
      if(prst)
        cstate <= IDLE;
      else
        cstate <= nstate;
    end
    
    // Main FSM state change process
    always_comb begin : proc_fsm
      if(cstate == IDLE) begin: idle_state
        if(psel) nstate   = SETUP_PHASE;
        else     nstate  = IDLE;
      end
      else if(cstate == SETUP_PHASE) begin: setup_phase
        // Tell the Master we accepted the TRX sent over
        if(penable ) begin
          // With not Wait state Transfer is accomodated in 1 cycle
          if(WAIT_STATE == 0) begin: no_count
            // Write phase
            if(pwrite)  nstate  = WRITE_PHASE;
            // Read Phase
            else        nstate  = READ_PHASE;
          end
          // With wait state pready remain low untill the counter reaches the Wait states
          else begin: count_wait
            if(cnt == WAIT_STATE) begin
              // Write phase
              if(pwrite)  nstate  = WRITE_PHASE;
              // Read Phase
              else        nstate  = READ_PHASE;
            end
            else begin
              nstate  = SETUP_PHASE;
            end
          end
        end
        else begin
          nstate    = SETUP_PHASE;
        end
      end
      else if(cstate == READ_PHASE) begin: read_phase
        if(~penable) nstate   = IDLE;
        else         nstate   = READ_PHASE;
      end
      else begin: write_phase
        if(~penable) nstate   =  IDLE;
        else         nstate   = WRITE_PHASE;
      end
    end

    // Additional Signals for DECODER to sub_slaves connection
    logic slv0_ready, slv1_ready, slv_wr_rd_en;
    logic [N_OF_SLAVES-1:0] slv_cs;
    logic [MEMORY_DATA-1:0] mem_data_out;
    logic [REG_WIDTH-1:0]   rif_data_out;
    logic [$clog2(MEMORY_DEPTH)-1:0] mem_int_addr;

    // The memory should be single word alligned
    assign mem_int_addr = ((paddr-`MEM_ADDR_START) >> 2);

    // APB DECODER
    apb_decoder#(
      .DEC_WIDTH      (REG_WIDTH),
      .N_OF_SLAVES    (`NUMBER_OF_SLVS),
      .SLV0_START_ADDR(`RIF_ADDR_START),
      .SLV0_END_ADDR  (`RIF_ADDR_END),
      .SLV1_START_ADDR(`MEM_ADDR_START),
      .SLV1_END_ADDR  (`MEM_ADDR_END)
      ) u_apb_decoder(
        .dec_mst_addr    (paddr),
        .dec_mst_wr_rd_en(pwrite),
        .dec_mst_cs      (penable),
        .dec_slv0_ready  (slv0_ready),
        .dec_slv1_ready  (slv1_ready),
        .dec_slv0_rd_data(rif_data_out),
        .dec_slv1_rd_data(mem_data_out),
        .dec_slv_cs      (slv_cs),
        .dec_mst_rdata   (prdata),
        .dec_slv_ready   (pready),
        .dec_slv_wr_rd_en(slv_wr_rd_en)
      );  

    // MEMORY AND RIF INSTANCES
    // APB MMEMORY (WORD ALLIGNED ACCESS)
    apb_memory#(
      .ZERO_MEM     (ZERO_MEM),
      .MEMORY_DATA  (MEMORY_DATA),
      .MEMORY_DEPTH (MEMORY_DEPTH)
      ) u_apb_mem(
`ifdef CYCLED_MEM
        .mem_clk  (pclk),
`endif
        .mem_ares (prst),
        .mem_wr_en(slv_wr_rd_en),
        .mem_cs   (slv_cs[1]),
        .mwdata   (pwdata),
        .maddr    (mem_int_addr),
        .mrdata   (mem_data_out),
        .mem_ready(slv0_ready)
      );

    // APB RIF
    apb_rif#(
      .REG_WIDTH(REG_WIDTH)
      ) u_apb_rif(
        .rif_clk  (pclk),
        .rif_arst (prst),
        .rif_write(slv_wr_rd_en),
        .rif_cs   (slv_cs[0]),
        .rif_addr (paddr),
        .rif_wdata(pwdata),
        .rif_rdata(rif_data_out),
        .rif_error(pslverror),
        .rif_ready(slv1_ready)
      );

endmodule : apb_slave_controller