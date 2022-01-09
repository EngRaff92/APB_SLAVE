#!/opt/homebrew/bin/python3.9

## 
## Icebreaker and IceSugar RSMB5 project - RV32I for Lattice iCE40
## With complete open-source toolchain flow using:
## -> yosys 
## -> icarus verilog
## -> icestorm project
## 
## Tests are written in several languages
## -> Systemverilog Pure Testbench (Vivado)
## -> UVM testbench (Vivado)
## -> PyUvm (Icarus)
## -> Formal either using SVA and PSL (Vivado) or cuncurrent assertions with Yosys
## 
## Copyright (c) 2021 Raffaele Signoriello (raff.signoriello92@gmail.com)
## 
## Permission is hereby granted, free of charge, to any person obtaining a 
## copy of this software and associated documentation files (the "Software"), 
## to deal in the Software without restriction, including without limitation 
## the rights to use, copy, modify, merge, publish, distribute, sublicense, 
## and/or sell copies of the Software, and to permit persons to whom the 
## Software is furnished to do so, subject to the following conditions:
## 
## The above copyright notice and this permission notice shall be included 
## in all copies or substantial portions of the Software.
## 
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
## EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
## IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
## CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
## TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
## SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Description here for class DATA1
class data1(uvm_reg):
    def __init__(self, name):
        super().__init__(name)
        self.dt = uvm_reg_field('DT')
        self.dt.configure(self, 32, 0, 'RW', 0, 0)

## Description here for class DATA2
class data2(uvm_reg):
    def __init__(self, name):
        super().__init__(name)
        self.dt = uvm_reg_field('DT')
        self.dt.configure(self, 32, 0, 'RW', 0, 0)

## Description here for class DATA3
class data2(uvm_reg):
    def __init__(self, name):
        super().__init__(name)
        self.dt = uvm_reg_field('DT')
        self.dt.configure(self, 32, 0, 'RW', 0, 0)

## Description here for class WRITE_ENABLE
class write_enable(uvm_reg):
    def __init__(self, name):
        super().__init__(name)
        self.data1_wren = uvm_reg_field('DATA1_WREN')
        self.data1_wren.configure(self, 1, 0, 'W', 0, 0)
        self.data2_wren = uvm_reg_field('DATA2_WREN')
        self.data2_wren.configure(self, 1, 1, 'W', 0, 0)
        self.data3_wren = uvm_reg_field('DATA3_WREN')
        self.data3_wren.configure(self, 1, 2, 'W', 0, 0)

## Description here for class DATA_STATUS_1
class data_status_1(uvm_reg):
    def __init__(self, name):
        super().__init__(name)
        self.status = uvm_reg_field('STATUS')
        self.status.configure(self, 1, 0, 'R', 0, 0)

## Description here for class DATA_STATUS_2
class data_status_2(uvm_reg):
    def __init__(self, name):
        super().__init__(name)
        self.status = uvm_reg_field('STATUS')
        self.status.configure(self, 1, 0, 'R', 0, 0)

## Description here for class DATA_STATUS_3
class data_status_3(uvm_reg):
    def __init__(self, name):
        super().__init__(name)
        self.status = uvm_reg_field('STATUS')
        self.status.configure(self, 1, 0, 'R', 0, 0)

## Description here for class APB_RIF
class apb_rif(uvm_reg_block):
    def __init__(self, name):
        super().__init__(name)
        self.default_map = uvm_reg_map('default_map')
        self.default_map.configure(self, 0)
        self.DATA1 = data1('DATA1')
        self.DATA1.configure(self)
        self.default_map.add_reg(self.DATA1, int('0x0', 0))
        self.DATA2 = data1('DATA2')
        self.DATA2.configure(self)
        self.default_map.add_reg(self.DATA2, int('0x4', 0))
        self.DATA3 = data1('DATA3') 
        self.DATA3.configure(self)
        self.default_map.add_reg(self.DATA3, int('0x8', 0))
        self.WRITE_ENABLE = data1('WRITE_ENABLE')
        self.WRITE_ENABLE.configure(self)
        self.default_map.add_reg(self.WRITE_ENABLE, int('0xC', 0))   
        self.DATA_STATUS_1 = data1('DATA_STATUS_1')
        self.DATA_STATUS_1.configure(self)
        self.default_map.add_reg(self.DATA_STATUS_1, int('0x10', 0))  
        self.DATA_STATUS_2 = data1('DATA_STATUS_2')
        self.DATA_STATUS_2.configure(self)
        self.default_map.add_reg(self.DATA_STATUS_1, int('0x14', 0))  
        self.DATA_STATUS_3 = data1('DATA_STATUS_3')
        self.DATA_STATUS_3.configure(self)
        self.default_map.add_reg(self.DATA_STATUS_3, int('0x18', 0))   