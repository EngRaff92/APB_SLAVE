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

class apb_memory_only_RAR extends apb_base_test;
    // Local name
    string n = "apb_memory_only_RAR";

    // constructor
    function new(virtual apb_interface#(REG_WIDTH) test_if_h);
        // Invoke the super class
        super.new(n,test_if_h);
    endfunction // new

    // Test run extend this one in order to customize the test to be ran
    virtual task test_run();
        // this will print the name and invoke the environment
        super.test_run();
        // Info
        apb_print({n, " Running"},LOW,INFO);              
        // Run walking through the memory and write values
        for(bit [REG_WIDTH-1:0] at = `memory_adress_start; at <=`memory_adress_end; at+=4) begin
            u_gen.addr      = at;
            u_gen.wdata     = at;
            u_gen.access    = MEM;
            u_gen.kind      = WRITE;
            u_gen.apb_gen_trx(1);
        end
        // Run walking through the memory and read values      
        for(bit [REG_WIDTH-1:0] at = `memory_adress_start; at <=`memory_adress_end; at+=4) begin
            u_gen.addr      = at;
            u_gen.access    = MEM;
            u_gen.kind      = READ;
            u_gen.apb_gen_trx(1);
        end
        // if(environment.generator.trx_cnt == 20)
        ->>apb_test_if.sim_done;
    endtask // test_run
endclass // apb_base_test