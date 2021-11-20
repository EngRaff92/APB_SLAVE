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

// Interface
interface apb_interface#(
        // Parameters declaration
        parameter REG_WIDTH = 32
    ) 
    (
        // Input output ports
        input bit apb_clock
    );

    // Local signals
    bit                     prst;
    bit                     pclk_en;
    bit                     penable;
    bit                     pwrite;
    bit                     psel;
    bit [REG_WIDTH-1:0]     paddr;
    bit [REG_WIDTH-1:0]     pwdata;
    logic [REG_WIDTH-1:0]   prdata, d;
    logic                   pslverror;
    logic                   pready;

    // local event
    event rst_done; 
    event sim_done;  
  
    // Clocking Blocks
    // Clocking block for master
    clocking master_cb @(posedge apb_clock);
    endclocking

    // Clocking block for slave
    clocking slave_cb @(posedge apb_clock);
    endclocking

    // Clocking block for Monitor
    clocking monitor_cb @(posedge apb_clock);
    endclocking

    // Modports
    modport master_mp (clocking master_cb);
    // TODO: provide the reversed direction for the driver_cb
    modport slave_mp (clocking slave_cb);

    // task to drive the reset
    task drive_reset_state();
        pclk_en = 1;
        prst    = 0;
        #10;
        prst    = 1;
        #5;
        prst    = 0;
        ->> rst_done;
    endtask // drive_reset_state
      
    // Useful tasks to be used everywhere
    // Task for WR APB operation
    task apb_wr(input bit [31:0] addr, bit [31:0] wdata);
        if(~pready)
            @(posedge pready);
        apb_print($sformatf("Start WR TRX at address: %0h with Data: %0h",addr,wdata),HIGH,INFO);
        psel        = 1;
        paddr       = addr;
        pwrite      = 1;
        pwdata      = wdata;
        @(posedge apb_clock);
        penable     = 1;
        // Transfer END
        @(posedge apb_clock);
        psel        = 0;
        penable     = 0;
        pwrite      = 0;
        // RIF access END
        @(posedge apb_clock);
        if(~pready)
            @(posedge pready);
    endtask
    
    // Task for RD APB operation
    task apb_rd(input bit [31:0] addr, output bit [31:0] rdata);
        if(~pready)
            @(posedge pready);
        apb_print($sformatf("Start RD TRX at address: %0h",addr),HIGH,INFO);
        psel        = 1;
        paddr       = addr;
        pwrite      = 'h0;
        pwdata      = 'h0;
        @(posedge apb_clock);
        penable     = 1;
        // Transfer END
        @(posedge apb_clock);
        psel        = 0;
        penable     = 0;
        @(posedge apb_clock);
        // RIF access END
        rdata       = prdata;
        if(~pready)
            @(posedge pready);
        apb_print($sformatf("Data read at addr: %0h is: %0h", addr,rdata),HIGH,INFO);
    endtask

endinterface : apb_interface