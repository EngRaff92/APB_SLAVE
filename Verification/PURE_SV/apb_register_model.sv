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

/* This file contains the main class used for the apb register model
    1. Each register is configured and declared as register_elem
    2. Memory is configured and declared as memory_elem
    3. This file is Autogenerated using the RDL
*/

class apb_register_map();
    // Main register array
    register_elem reg_array[$];

    // Single register array
    register_elem sv_reg_data1;
    register_elem sv_reg_data2;
    register_elem sv_reg_data3;
    register_elem sv_reg_write_enable;
    register_elem sv_reg_data_status_1;
    register_elem sv_reg_data_status_2;
    register_elem sv_reg_data_status_3;

    // Target
    register_elem target;

    // Memory
    memory_elem apb_memory;

    // Constructor
    function new();
        // call every new from each register
        sv_reg_data1            = new("sv_reg_data1");
        sv_reg_data2            = new("sv_reg_data2");
        sv_reg_data3            = new("sv_reg_data3");
        sv_reg_write_enable     = new("sv_reg_write_enable ");
        sv_reg_data_status_1    = new("sv_reg_data_status_1");
        sv_reg_data_status_2    = new("sv_reg_data_status_2");
        sv_reg_data_status_3    = new("sv_reg_data_status_3");
        // Call new from memory
        apb_memory              = new("apb_memory");
    endfunction

    // register map map_build
    function void map_build();
        // Call each reg_build
        sv_reg_data1            = reg_build(RW,32,'h0,`register_data1,1);      
        sv_reg_data2            = reg_build(RW,32,'h0,`register_data2,1);
        sv_reg_data3            = reg_build(RW,32,'h0,`register_data3,1); 
        sv_reg_write_enable     = reg_build(RW,3,'h0,`register_write_enable,1); 
        sv_reg_data_status_1    = reg_build(RO,1,'h0,`register_data_status_1,1); 
        sv_reg_data_status_2    = reg_build(RO,1,'h0,`register_data_status_2,1); 
        sv_reg_data_status_3    = reg_build(RO,1,'h0,`register_data_status_3,1); 
        // After add all the register into the queue
        reg_array.push_back(sv_reg_data1);
        reg_array.push_back(sv_reg_data2);
        reg_array.push_back(sv_reg_data3);
        reg_array.push_back(sv_reg_write_enable);
        reg_array.push_back(sv_reg_data_status_1);
        reg_array.push_back(sv_reg_data_status_2);
        reg_array.push_back(sv_reg_data_status_3);
        // Call the memory build function
        apb_memory.memory_build(PROG,((`memory_adress_end-`memory_adress_start)/4)+1,ZERO,`memory_adress_start,1);
    endfunction // map_build

    // function used to lock each register element
    function map_lock();
        // call the lock in register
        foreach (reg_array[ii]) begin
            reg_array[ii].lock();
        end
        // call the lock in memory
        apb_memory.memory_lock();
    endfunction // map_lock

    // Reset function
    function map_reset();
        // call reset for every register
        foreach (reg_array[ll]) begin
            reg_array[ll].reg_reset();
        end
        // call reset for the memory
        apb_memory.memory_reset();
    endfunction // map_reset    

    // function used to predict the value according to the register
    function bit predict_register_by_address(reg_data_t address);
    endfunction // predict_register_by_address

    // function used to return the specific register based on the address
    function register_elem get_reg_by_addr(reg_data_t address);
    endfunction // get_reg_by_addr

    // function used to reset the value according to the register
    function bit reset_register_by_address(reg_data_t address);
    endfunction // reset_register_by_address    
endclass

