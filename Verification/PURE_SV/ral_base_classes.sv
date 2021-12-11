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

/* This file contains the main classes used for the register model
    1. register_elem equivalent to the uvm_reg
    2. memory_elem equivalent to uvm_mem
    3. the write read based on sequencer or special predictors are not supported
    4. the register model is not equivalent to the RAL UVM model is way less efficient
    5. there is no concept of fields or equivalent
*/

// Single register class model
class register_elem;
    // Local Variables marked as protected so that 
    // will be accessible by derived class but only by
    // those methods
    protected policy_t      access_policy;
    protected int unsigned  length;
    string                  name;
    protected reg_data_t    m_reset, m_pre_reset;
    protected reg_data_t    m_mirrored;
    protected reg_data_t    m_address;
    protected bit           m_has_reset;
    protected bit           locked;
    protected string        backdoor_path;

    // Contructor
    function new(input string lname);
        this.name   = lname;
        this.locked = 0;
    endfunction // new

    // Register build function (allows to customize the register class)
    function void reg_build(input policy_t access, int len, reg_data_t reset, address, bit has_reset);
        if(~locked) begin
            this.access_policy  = access;
            this.length         = len;
            this.m_pre_reset    = reset;
            this.m_has_reset    = has_reset;
            this.m_address      = address;
        end
        else begin
            $error("Register: %0s has been locked previously reg_build cannot be called on locked register",this.name);
        end
    endfunction : reg_build
    
    // Register prediction
    function void reg_predict(input reg_data_t value);
        this.m_mirrored = value;
    endfunction : reg_predict
    
    // Register reset just to set the reset internal vaue
    function bit reg_reset();
        if(~this.m_has_reset)
            $error("Register: %0s is not resettable cannot be reset",this.name);
        else
            this.m_reset = m_pre_reset;
    endfunction : reg_reset

    // Set reset will override whatever we set using the standard build
    function void set_reset(input reg_data_t reset_value);
        if(this.m_has_reset)
            this.m_reset = reset_value;
        else
            $error("Cannot set a reset for a register not supposed to have a reset");
    endfunction // set_reset

    // Get policy value 
    function policy_t get_policy();
        return this.access_policy;
    endfunction // get_policy   

    // Register lock
    function void lock();
        this.locked = 1;
    endfunction // lock  

    // Get mirrored value
    function reg_data_t get_mirrored();
        return m_mirrored;
    endfunction // get_mirrored

    // Get reset value
    function reg_data_t get_reset();
        return m_reset;
    endfunction // get_reset

    // Get register address
    function reg_data_t get_address();
        return m_address;
    endfunction : get_address

    // Add the backdoor path to the local string
    function void add_backdoor(input string path);
        if(path == "")
            $error("Calling Add backdoor for register with empty Path is not valid");
        else
            this.backdoor_path = {path};
    endfunction // add_backdoor

    // Get the backdoor path string
    function string get_backdoor();
        return backdoor_path;
    endfunction // get_backdoor

    // Compare method which returns 1 if mirrored mathces the value provided otherwise 0
    function bit reg_compare(input reg_data_t val);
        return (this.m_mirrored === val);
    endfunction // reg_compare
endclass // register_elem    

// Single memory class model
class memory_elem;
    // Local Variables marked as protected so that 
    // will be accessible by dericed class but only by
    // hsing methods
    protected memory_type_t m_memory_type;
    protected int unsigned  m_depth;
    string                  m_name;
    protected mem_reset_t   m_reset_type;
    protected reg_data_t    m_mirrored;
    protected reg_data_t    m_offset;
    protected bit           m_has_reset;
    protected bit           m_locked;
    protected string        m_backdoor_path;
    protected reg_data_t    m_memory_inst[];
    protected int unsigned  m_index;
    protected int unsigned  m_align;
    protected int unsigned  m_otp_countermeasure;

    // Contructor
    function new(input string lname);
        this.m_name                 = lname;
        this.m_locked               = 0;
        this.m_align                = 2; // This will be part of the build in future
        this.m_otp_countermeasure   = 0;
    endfunction // new

    // Memory build function (allows to customize the register class)
    function void memory_build(input memory_type_t mem_type, int d, mem_reset_t res_type, reg_data_t mem_offset, bit has_reset);
        if(~m_locked) begin
            this.m_memory_type      = mem_type;
            this.m_depth            = d;
            this.m_reset_type       = res_type;
            this.m_offset           = mem_offset;
            // Use [] the dynamic array is not a clss or object
            this.m_memory_inst      = new[d];
        end
        else begin
            $error("Memory: %0s has been locked previously memory_build cannot be called on locked memory",this.m_name);
        end
    endfunction // memory_build
    
    // Memory prediction
    function void memory_predict(reg_data_t value = 0, address = 0);
        // We assume the memory is word alligned (will add a typdef later to distinguish)
        this.m_index                = (address - m_offset) >> 2;
        this.m_memory_inst[m_index] = value;
    endfunction // memory_predict
    
    // Memory reset
    function void memory_reset(input string path = "");
        if(~this.m_has_reset) begin
            $error("Memory: %0s is not resettable cannot be reset",this.m_name);
            this.zeroing_memory();
        end
        else begin 
            case(m_reset_type)
                ZERO:       begin this.zeroing_memory();        end
                RANDOM:     begin this.randomizing_memory();     end
                ONES:       begin this.ones_memory();            end 
                IMAGE:      begin this.load_memory_image(path);  end
                default:    begin this.zeroing_memory();        end
            endcase
        end
    endfunction // memory_reset

    // Function used to mask out the data avoid overprogramming the OTP memory
    function reg_data_t get_mask(input reg_data_t in = 0);
        automatic reg_data_t mask = ~in; 
        return mask;
    endfunction // get_mask

    // Function used to zero out the memory
    function void zeroing_memory();
        $display("Zero type selected zeroing memory");
        foreach (this.m_memory_inst[kk])
          this.m_memory_inst[kk] = {$bits(reg_data_t){1'b0}};
    endfunction // zeroing_memory

    // Function used to randomize each element of the memory
    function void randomizing_memory();
        $display("Random type selected randomizing memory");
        foreach (this.m_memory_inst[ll]) begin 
            if((this.m_memory_type == OTP) && (this.m_otp_countermeasure > 1))
               m_memory_inst[ll] = $urandom() && get_mask(m_memory_inst[ll]);
            else    
               this.m_memory_inst[ll] = $urandom();
        end
        this.m_otp_countermeasure +=1;
    endfunction // randomizing_memory

    // Function used to randomize each element of the memory
    function void ones_memory();
        $display("Ones type selected setting memory to all ones");
        if((this.m_memory_type == OTP) && (this.m_otp_countermeasure > 1))
            $error("Calling ones_memory for an OTP memory more then once");
        else
          foreach (this.m_memory_inst[kk])
            this.m_memory_inst[kk] = {$bits(reg_data_t){1'b1}};
          // Unkown size the assign pattern cannot be used
          // this.m_memory_inst = '{default: {$bits(reg_data_t){1'b1}}};
        this.m_otp_countermeasure +=1;
    endfunction // ones_memory

    // Task used to randomize each element of the memory
    task load_memory_image(input string image_path = "");
        $display("Image type selected laoding memory iamghe from path: %0s",image_path);
        if(image_path == "") begin
            $error("No image has been provided while calling the load_memory_image");
        end
        else if(this.m_backdoor_path == "") begin
            $error("The m_backdoor_path is not set image cannot be loeaded please provide memory location");
        end
        else begin
            $readmemb(image_path,this.m_memory_inst);
        end
        this.m_otp_countermeasure +=1;
    endtask // load_memory_image

    // Task used to peek the memory through the Backdoor
    task memory_peek(input reg_data_t address = 0, input reg_data_t value_to_peek = 0);
        this.m_index = (address - m_offset) >> 2;
        this.m_memory_inst[m_index] = value_to_peek;
        // use the deposit to the hier
    endtask // memory_peek

    // Task used to poke the memory through the backdoor
    task memory_poke(input reg_data_t address = 0, output reg_data_t data_to_poke);
        this.m_index = (address - m_offset) >> 2;
        // Use the access through the hier
    endtask // memory_poke

    // Get memory type
    function memory_type_t get_mem_type();
        return this.m_memory_type;
    endfunction // get_mem_type   

    // Memory lock
    function void memory_lock();
        this.m_locked = 1;
    endfunction // lock  

    // Get mirrored value
    function reg_data_t get_mirrored(input reg_data_t address = 0);
        // We assume the memory is word alligned (will add a typdef later to distinguish)
        this.m_index = (address - m_offset) >> 2;
        return this.m_memory_inst[m_index];
    endfunction // get_mirrored

    // Get memory address index address
    function reg_data_t get_memory_index(input reg_data_t address = 0);
        return (address - m_offset) >> 2;
    endfunction // get_memory_index

    // Add the backdoor path to the local string
    function void add_backdoor(input string path = "");
        if(path == "")
            $error("Calling Add backdoor for memory with empty Path is not valid");
        else
            this.m_backdoor_path = path;
    endfunction // add_backdoor

    function string get_backdoor();
        return m_backdoor_path;
    endfunction // get_backdoor
endclass // memory_elem  