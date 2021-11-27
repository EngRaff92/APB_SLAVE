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

class apb_trx_driver#(type T = apb_item);
    // Type propagation
    T driv_apb_trx, monitor_apb_trx;

    // local variables
    int trx_cnt;
    string driver_name;

    // Mailbox
    mailbox#(T) driver_mbox;

    // Interface
    virtual apb_interface#(REG_WIDTH) driver_apb_if;

    // Constructor
    function new(input string n, mailbox#(T) mbox, virtual apb_interface#(REG_WIDTH) if_handler);
        // Assign
        this.driver_name    = n;
        this.driver_mbox    = mbox;
        this.driver_apb_if  = if_handler;
    endfunction // new

    // task run (randomize the item and send it to the item)
    task apb_drive_trx();
        // Info
        apb_print("Driver Running",LOW,INFO);
        // forever running thread
        forever begin
            // Send the item through the Mailbox
            driver_mbox.get(driv_apb_trx);
            // Check the TRX and drive signals
            if(driv_apb_trx.cmd == WRITE)
                driver_apb_if.apb_wr(driv_apb_trx.address,driv_apb_trx.data_wr);
            else if(driv_apb_trx.cmd == READ)
                driver_apb_if.apb_rd(driv_apb_trx.address,driv_apb_trx.data_rd);
            // Print Read Data
            apb_print($sformatf("Print TRX -> Data read      %0h: ",driv_apb_trx.data_rd),LOW,INFO);
            // Copy TRX to a new one and sed it to the monitor's
            monitor_apb_trx = driv_apb_trx.do_copy();
            // Send the item to the monitor
            //driver_mbox.put(monitor_apb_trx);
        end
    endtask // apb_drive_trx
endclass // apb_trx_driver