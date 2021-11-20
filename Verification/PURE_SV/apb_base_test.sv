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

class apb_base_test;
    // local variables
    string test_name;

    // local transaction
    rand apb_item test_trx;

    // declare the environment
    apb_env#(apb_item) environment;
    
    // local interface
    virtual apb_interface#(REG_WIDTH) apb_test_if;
  
    // constructor
    function new(input string name, virtual apb_interface#(REG_WIDTH) test_if_h);
        // Create the Environment
        environment         = new("apb_env",test_if_h);
        // link the interface
        this.apb_test_if    = test_if_h;
    endfunction // new

    // Randomize
    task randomize_trx();
        // create
        test_trx = new("test_trx");
        // Randomize
        if(!test_trx.randomize())
            apb_print("Not able to randomize TRX",LOW,FATAL);
    endtask // randomize_trx

    // Invoke the generator
    task invoke_gen(input bit randomize_from_test = 0);
        // randomize first
        if(randomize_from_test) randomize_trx();
        // generate the TRX
        environment.generator.apb_gen_trx();
    endtask // invoke_gen

    // Test run
    task test_run();
        // Info
        apb_print("Test Base Running",LOW,INFO);
        // wait for reset 
        wait(apb_test_if.rst_done.triggered);
        apb_print("RESET done",LOW,INFO);
        // Run everything
        environment.env_run();
        repeat(20) invoke_gen();
        if(environment.generator.trx_cnt == 20)
            ->>apb_test_if.sim_done;
    endtask // test_run
endclass // apb_base_test