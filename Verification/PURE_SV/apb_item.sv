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

class apb_item;
    // Random Variable
    rand reg_data_t address;
    rand reg_data_t data_wr;
    rand access_t   access_part;
    rand apb_cmd_t  cmd;
    rand bit        exptected_err;
    reg_data_t      data_rd;
    string          item_name;

    // set of constraints
    constraint address_before { solve address before exptected_err;};

    constraint error_exp_memory_rif {
        if((address inside {[`memory_adress_start:`memory_adress_end]}))
               exptected_err == 0;           
        else if((address inside {[`regfile_apb_rif:`register_data_status_3]}))
               exptected_err == 0;
        else 
               exptected_err == 1;

    };

    // constructor
    function new(input string n);
        this.item_name = n;
    endfunction // new
    
    // Function used to print out the Transaction
    function void apb_item_print();
       apb_print($sformatf("Print TRX -> Name           %0s: ",item_name),LOW,INFO);
       apb_print($sformatf("Print TRX -> Address        %0h: ",address),LOW,INFO);
       apb_print($sformatf("Print TRX -> Data Write     %0h: ",data_wr),LOW,INFO);
       apb_print($sformatf("Print TRX -> Access Part    %0s: ",access_part.name()),LOW,INFO);
       apb_print($sformatf("Print TRX -> CMD type       %0s: ",cmd.name()),LOW,INFO);
       apb_print($sformatf("Print TRX -> EXP_ERR        %0d: ",exptected_err),LOW,INFO);
    endfunction // apb_item_print
    
    // Post randomize
    // postrandomize function, displaying randomized values of items 
    function void post_randomize();
        this.apb_item_print();
    endfunction
  
    // Deep copy method
    function apb_item do_copy();
        apb_item _t     = new("copy_apb_item");
        _t.address      = this.address;
        _t.data_wr      = this.data_wr;
        _t.access_part  = this.access_part;
        _t.cmd          = this.cmd;
        _t.data_rd      = this.data_rd;
        return _t;
  endfunction
endclass