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

class apb_trx_generator#(type T = apb_item);
    // Type propagation
    rand T apb_trx;

    // local variables
    int                 trx_cnt;
    string              gen_name;
    rand reg_data_t     addr;
    rand reg_data_t     wdata;
    rand access_t       access;
    rand apb_cmd_t      kind;

    // Mailbox
    mailbox#(T) gen_mbox;

    // Constructor
    function new(input string n, input mailbox#(T) mbox);
        // Assign
        this.gen_name = n;
        this.gen_mbox = mbox;
    endfunction // new

    // task run (randomize the item and send it to the item)
    task apb_gen_trx(input bit rand_with_user_values = 0);
        // Info
        apb_print($sformatf("Generator Running Transaction: %0d",trx_cnt),LOW,INFO);
        // create a TRX
        apb_trx = new($sformatf("apb_trx_%0d",trx_cnt));
        if(rand_with_user_values) begin
            // Print out
            apb_print($sformatf("Use randomization selected in: %0s",gen_name),LOW,INFO);
            // Randomize    
            if(!apb_trx.randomize() with {
                apb_trx.address     == local::addr;
                apb_trx.data_wr     == local::wdata;
                apb_trx.access_part == local::access;
                apb_trx.cmd         == local::kind;})
                apb_print("Not able to randomize TRX",LOW,FATAL);
        end
        else begin
            // Randomize
            if(!apb_trx.randomize())
                apb_print("Not able to randomize TRX",LOW,FATAL);
        end
        // Send the item through the Mailbox
        gen_mbox.put(apb_trx);
        // Increment the counter
        trx_cnt++;
    endtask // apb_gen_trx
endclass // apb_trx_generator