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

class apb_env#(type T = apb_item);
  
    // local virtual interface
    virtual apb_interface#(REG_WIDTH) env_main_if;

    // local variables
    string env_name;

    // local driver
    apb_trx_driver#(T) driver;

    // local monitor
    // apb_monitor#(apb_item) monitor;

    // local scoreboard
    // apb_scoreboard#(apb_item) scoreboard;
    
    // Local generator 
    apb_trx_generator#(apb_item) generator;
  
    // local mailbox
    mailbox#(T) gen2driver_mbox;
    mailbox#(T) monitor2scbd_mbox;

    // constructor
    function new (input string name, virtual apb_interface#(REG_WIDTH) env_if_handler);
        // Create mailboxes
        this.gen2driver_mbox     = new(1);
        this.monitor2scbd_mbox   = new(1);
        this.env_name            = name;

        // Create the driver
        driver = new("apb_driver",gen2driver_mbox,env_if_handler);
        
        // Create the generator
        generator = new("apb_generator",gen2driver_mbox);
      
        // Create the monitor
        // monitor = new("apb_monitor",monitor2scbd_mbox,env_if_handler);
    endfunction // new

    // Run
    task env_run();
        // Info
        apb_print("Environment Running",LOW,INFO);
        fork
            // driver start
            driver.apb_drive_trx();
            // monitor start
            //monitor.apb_monitor_trx();
            // Scoreboard to start collecting data from monitor
        join_none // join_any
    endtask // env_run
endclass // apb_env