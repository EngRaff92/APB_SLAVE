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

// ########################################################################################################
// Defines and Parameters for Testbench
// ########################################################################################################
`include "/Volumes/My_Data/MY_SYSTEMVERILOG_UVM_PROJECTS/APB_PROTOCOL/APB_SLAVE/Apb_Reggen/output_all/apb_reg_param.svh"

// Parameters
parameter REG_WIDTH = 32;

// ########################################################################################################
// Macros and Types
// ########################################################################################################

//
typedef enum int {
    WO  = 0,
    RO  = 1,
    RW  = 2,
    WOC = 3,
    ROC = 4
} policy_t;

// 
typedef enum bit {
    RIF  = 0,
    MEM  = 1
} access_t;

//
typedef enum bit [1:0] {
    ZERO    = 0,
    RANDOM  = 1,
    ONES    = 2,
    IMAGE   = 3
} mem_reset_t;

//
typedef enum bit {
    PROG  = 0,
    OTP   = 1
} memory_type_t;

//
typedef enum bit {
    WRITE  = 0,
    READ   = 1
} apb_cmd_t;

//
typedef enum bit {
    APB_OK  = 0,
    APB_ERR = 1
} apb_resp_t;

//
typedef bit [31:0] reg_data_t;

// Print Severity
typedef enum int {
    LOW     = 0,
    HIGH    = 1,
    DEBUG   = 2
} debug_print_t;

typedef enum int {
    INFO    = 0,
    ERROR   = 1,
    FATAL   = 2
} severity_print_t;

// If no verbosity is set by outside then we set it as LOW
// General global level set by using defines
`ifdef VERB_LOW
debug_print_t global_verbosity  = LOW;
`elsif VERB_HIGH
debug_print_t global_verbosity  = HIGH;
`elsif VERB_DEBUG
debug_print_t global_verbosity  = DEBUG;
`else 
 debug_print_t global_verbosity = LOW;
`endif

// Global Header used
string header = "APB_TEST: -- ";
// ########################################################################################################
// Setting Up the ENV according to the Define used in the ENV
// ########################################################################################################
// General Print used by the whole Environment except the UVM or PYUVM testbench
function void apb_print(input string Message, input debug_print_t verbosity, input severity_print_t sev);
    // Set the internal message
    string mex;
    mex = {header,sev.name()," ",Message};
    if(sev == INFO) begin
        case(verbosity)
            LOW:        begin if(global_verbosity >= LOW)   $display(mex); end
            HIGH:       begin if(global_verbosity >= HIGH)  $display(mex); end
            DEBUG:      begin if(global_verbosity >= DEBUG) $display(mex); end
            default:    $display(mex);
        endcase
    end
    else if(sev == ERROR) begin
        $error(mex);
    end
    else begin 
        $fatal(1,mex);
    end
endfunction
    
// ########################################################################################################
// Includes
// ########################################################################################################
`include "./apb_interface.sv"
`include "./apb_register_model.sv"
`include "./apb_item.sv"
`include "./apb_generator.sv"
`include "./apb_monitor.sv"
`include "./apb_driver.sv"
`include "./apb_scoreboard.sv"
`include "./apb_env.sv"
`include "./apb_base_test.sv"
`include "./apb_rif_only_RAR.sv"
`include "./apb_rif_only_WAR_RAW.sv"
`include "./apb_rif_only_RANDOM.sv"
`include "./apb_rif_only_STATUS_CHECK.sv"
`include "./apb_rif_only_ERROR_CHECK.sv"
`include "./apb_memory_only_RAR.sv"
`include "./apb_memory_only_WAR_RAW.sv"
`include "./apb_memory_only_RANDOM.sv