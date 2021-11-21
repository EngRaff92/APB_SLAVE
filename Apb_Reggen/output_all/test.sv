
// This file was autogenerated by PeakRDL-uvm
package test;
    `include "uvm_macros.svh"
    import uvm_pkg::*;
    
    // Reg - basic::foo::reg_t
    class basic__foo__reg_t extends uvm_reg;
        rand uvm_reg_field f1;
        rand uvm_reg_field f2;
        rand uvm_reg_field f3;
        rand uvm_reg_field f5;
        rand uvm_reg_field f4;

        function new(string name = "basic__foo__reg_t");
            super.new(name, 32, UVM_NO_COVERAGE);
        endfunction : new

        virtual function void build();
            this.f1 = new("f1");
            this.f1.configure(this, 16, 0, "RW", 0, 'h4d2, 1, 1, 0);
            this.f2 = new("f2");
            this.f2.configure(this, 1, 16, "RW", 0, 'h0, 1, 1, 0);
            this.f3 = new("f3");
            this.f3.configure(this, 1, 17, "RW", 0, 'h0, 1, 1, 0);
            this.f5 = new("f5");
            this.f5.configure(this, 2, 28, "RW", 0, 'h0, 1, 1, 0);
            this.f4 = new("f4");
            this.f4.configure(this, 2, 30, "RW", 0, 'h0, 1, 1, 0);
        endfunction : build
    endclass : basic__foo__reg_t

    // Reg - basic::foo::reg_t_f1_10de76a8
    class basic__foo__reg_t_f1_10de76a8 extends uvm_reg;
        rand uvm_reg_field f1;
        rand uvm_reg_field f2;
        rand uvm_reg_field f3;
        rand uvm_reg_field f5;
        rand uvm_reg_field f4;

        function new(string name = "basic__foo__reg_t_f1_10de76a8");
            super.new(name, 32, UVM_NO_COVERAGE);
        endfunction : new

        virtual function void build();
            this.f1 = new("f1");
            this.f1.configure(this, 16, 0, "WO", 0, 'hc8, 1, 1, 0);
            this.f2 = new("f2");
            this.f2.configure(this, 1, 16, "RW", 0, 'h0, 1, 1, 0);
            this.f3 = new("f3");
            this.f3.configure(this, 1, 17, "RW", 0, 'h0, 1, 1, 0);
            this.f5 = new("f5");
            this.f5.configure(this, 2, 28, "RW", 0, 'h0, 1, 1, 0);
            this.f4 = new("f4");
            this.f4.configure(this, 2, 30, "RW", 0, 'h0, 1, 1, 0);
        endfunction : build
    endclass : basic__foo__reg_t_f1_10de76a8

    // Regfile - basic::foo
    class basic__foo extends uvm_reg_block;
        rand basic__foo__reg_t r1;
        rand basic__foo__reg_t r2;
        rand basic__foo__reg_t_f1_10de76a8 r3;

        function new(string name = "basic__foo");
            super.new(name);
        endfunction : new

        virtual function void build();
            this.default_map = create_map("reg_map", 0, 4, UVM_NO_ENDIAN);
            this.r1 = new("r1");
            this.r1.configure(this);
            r1.add_hdl_path_slice("f5_29", 29, 1);
            r1.add_hdl_path_slice("f5_28", 28, 1);
            r1.add_hdl_path_slice("f4", 30, 2);
            r1.add_hdl_path_slice("f5_gate", 28, 2, 0, "GATE");
            r1.add_hdl_path_slice("f4_31_gate", 31, 1, 0, "GATE");
            r1.add_hdl_path_slice("f4_30_gate", 30, 1, 0, "GATE");
            this.r1.build();
            this.default_map.add_reg(this.r1, 'h0);
            this.r2 = new("r2");
            this.r2.configure(this);
            r2.add_hdl_path_slice("f5_29", 29, 1);
            r2.add_hdl_path_slice("f5_28", 28, 1);
            r2.add_hdl_path_slice("f4", 30, 2);
            r2.add_hdl_path_slice("f5_gate", 28, 2, 0, "GATE");
            r2.add_hdl_path_slice("f4_31_gate", 31, 1, 0, "GATE");
            r2.add_hdl_path_slice("f4_30_gate", 30, 1, 0, "GATE");
            this.r2.build();
            this.default_map.add_reg(this.r2, 'h4);
            this.r3 = new("r3");
            this.r3.configure(this);
            r3.add_hdl_path_slice("f5_29", 29, 1);
            r3.add_hdl_path_slice("f5_28", 28, 1);
            r3.add_hdl_path_slice("f4", 30, 2);
            r3.add_hdl_path_slice("f5_gate", 28, 2, 0, "GATE");
            r3.add_hdl_path_slice("f4_31_gate", 31, 1, 0, "GATE");
            r3.add_hdl_path_slice("f4_30_gate", 30, 1, 0, "GATE");
            this.r3.build();
            this.default_map.add_reg(this.r3, 'h8);
        endfunction : build
    endclass : basic__foo

    // Reg - basic::bar_t::r1
    class basic__bar_t__r1 extends uvm_reg;
        rand uvm_reg_field f;

        function new(string name = "basic__bar_t__r1");
            super.new(name, 32, UVM_NO_COVERAGE);
        endfunction : new

        virtual function void build();
            this.f = new("f");
            this.f.configure(this, 16, 0, "RW", 0, 'h4d2, 1, 1, 0);
        endfunction : build
    endclass : basic__bar_t__r1

    // Regfile - basic::bar_t
    class basic__bar_t extends uvm_reg_block;
        rand basic__bar_t__r1 r1[4];

        function new(string name = "basic__bar_t");
            super.new(name);
        endfunction : new

        virtual function void build();
            this.default_map = create_map("reg_map", 0, 4, UVM_NO_ENDIAN);
            foreach(this.r1[i0]) begin
                this.r1[i0] = new($sformatf("r1[%0d]", i0));
                this.r1[i0].configure(this);
                r1[i0].add_hdl_path_slice("r1", -1, -1);
                r1[i0].add_hdl_path_slice("r1_gate", -1, -1, 0, "GATE");
                this.r1[i0].build();
                this.default_map.add_reg(this.r1[i0], 'h0 + i0*'h4);
            end
        endfunction : build
    endclass : basic__bar_t

    // Reg - basic::bar_t_r1_27b54106::r1_f_955b7f88
    class basic__bar_t_r1_27b54106__r1_f_955b7f88 extends uvm_reg;
        rand uvm_reg_field f;

        function new(string name = "basic__bar_t_r1_27b54106__r1_f_955b7f88");
            super.new(name, 32, UVM_NO_COVERAGE);
        endfunction : new

        virtual function void build();
            this.f = new("f");
            this.f.configure(this, 16, 0, "WO", 0, 'hc8, 1, 1, 0);
        endfunction : build
    endclass : basic__bar_t_r1_27b54106__r1_f_955b7f88

    // Regfile - basic::bar_t_r1_27b54106
    class basic__bar_t_r1_27b54106 extends uvm_reg_block;
        rand basic__bar_t_r1_27b54106__r1_f_955b7f88 r1[4];

        function new(string name = "basic__bar_t_r1_27b54106");
            super.new(name);
        endfunction : new

        virtual function void build();
            this.default_map = create_map("reg_map", 0, 4, UVM_NO_ENDIAN);
            foreach(this.r1[i0]) begin
                this.r1[i0] = new($sformatf("r1[%0d]", i0));
                this.r1[i0].configure(this);
                r1[i0].add_hdl_path_slice("r1", -1, -1);
                r1[i0].add_hdl_path_slice("r1_gate", -1, -1, 0, "GATE");
                this.r1[i0].build();
                this.default_map.add_reg(this.r1[i0], 'h0 + i0*'h4);
            end
        endfunction : build
    endclass : basic__bar_t_r1_27b54106

    // Reg - basic::xxx::r1
    class basic__xxx__r1 extends uvm_vreg;
        rand uvm_vreg_field f;

        function new(string name = "basic__xxx__r1");
            super.new(name, 32);
        endfunction : new

        virtual function void build();
            this.f = new("f");
            this.f.configure(this, 16, 0);
        endfunction : build
    endclass : basic__xxx__r1

    // Mem - basic::xxx
    class basic__xxx extends uvm_reg_block;
        rand uvm_mem m_mem;
        rand basic__xxx__r1 r1;

        function new(string name = "basic__xxx");
            super.new(name);
        endfunction : new

        virtual function void build();
            this.default_map = create_map("reg_map", 0, 4.0, UVM_NO_ENDIAN);
            this.m_mem = new("m_mem", 256, 32, "RW");
            this.m_mem.configure(this);
            this.default_map.add_mem(this.m_mem, 0);
            this.r1 = new("r1");
            this.r1.configure(this, this.m_mem, 8);
            this.r1.build();
        endfunction : build
    endclass : basic__xxx

    // Addrmap - basic
    class basic extends uvm_reg_block;
        rand basic__foo foo;
        rand basic__bar_t bar[4][3];
        rand basic__bar_t_r1_27b54106 bar2;
        rand basic__xxx xxx;

        function new(string name = "basic");
            super.new(name);
        endfunction : new

        virtual function void build();
            this.default_map = create_map("reg_map", 0, 4, UVM_NO_ENDIAN);
            this.foo = new("foo");
            this.foo.configure(this);
            this.foo.build();
            this.default_map.add_submap(this.foo.default_map, 'h0);
            foreach(this.bar[i0, i1]) begin
                this.bar[i0][i1] = new($sformatf("bar[%0d][%0d]", i0, i1));
                this.bar[i0][i1].configure(this, "bar");
                this.bar[i0][i1].add_hdl_path("bar_gate", "GATE");
                this.bar[i0][i1].build();
                this.default_map.add_submap(this.bar[i0][i1].default_map, 'h1000 + i0*'h300 + i1*'h100);
            end
            this.bar2 = new("bar2");
            this.bar2.configure(this, "bar");
            this.bar2.add_hdl_path("bar_gate", "GATE");
            this.bar2.build();
            this.default_map.add_submap(this.bar2.default_map, 'h8000);
            this.xxx = new("xxx");
            this.xxx.configure(this);
            this.xxx.build();
            this.default_map.add_submap(this.xxx.default_map, 'h10000);
        endfunction : build
    endclass : basic

endpackage: test
