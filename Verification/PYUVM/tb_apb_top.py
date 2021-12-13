#
# Icebreaker and IceSugar RSMB5 project - RV32I for Lattice iCE40
# With complete open-source toolchain flow using:
# -> yosys 
# -> icarus verilog
# -> icestorm project
#
# Tests are written in several languages
# -> Systemverilog Pure Testbench (Vivado)
# -> UVM testbench (Vivado)
# -> PyUvm (Icarus)
# -> Formal either using SVA and PSL (Vivado) or cuncurrent assertions with Yosys
#
# Copyright (c) 2021 Raffaele Signoriello (raff.signoriello92@gmail.com)
#
# Permission is hereby granted, free of charge, to any person obtaining a 
# copy of this software and associated documentation files (the "Software"), 
# to deal in the Software without restriction, including without limitation 
# the rights to use, copy, modify, merge, publish, distribute, sublicense, 
# and/or sell copies of the Software, and to permit persons to whom the 
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included 
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

from cocotb.triggers import FallingEdge, RisingEdge
from cocotb.triggers import Timer
from cocotb.triggers import Event
import cocotb

## Main interface
class apb_interface:
    def __init__(self, dut):
        self.dut        = dut
        self.reset_done = Event("apb_reset_done")

    ## task to drive the reset
    async def apb_reset(self):
        self.reset_done.clear()
        await Timer(10, units='ns')
        self.pclk_en    <= 1;
        self.dut.prst   <= 0;
        await Timer(10, units='ns')
        self.dut.prst   <= 1;
        await Timer(5, units='ns')
        self.dut.prst   <= 0;
        self.reset_done.set()

    ## Task used to read from specific address
    async def apb_rd(self, address, data_read):
        if self.dut.pready not 1:
            await RisingEdge(self.dut.pready)
        apb_print($sformatf("Start RD TRX at address: %0h",addr),HIGH,INFO);
        self.dut.psel        <= 1;
        self.dut.paddr       <= address;
        self.dut.pwrite      <= 0;
        self.dut.pwdata      <= 0;
        await RisingEdge(self.dut.pclk)
        self.dut.penable     <= 1;
        ## Transfer END
        await RisingEdge(self.dut.pclk)
        self.dut.psel        <= 0;
        self.dut.penable     <= 0;
        await RisingEdge(self.dut.pclk)
        ## RIF access END
        data_read            <= self.dut.prdata;
        if self.dut.pready not 1:
            await RisingEdge(self.dut.pready)
        apb_print($sformatf("Data read at addr: %0h is: %0h", addr,rdata),HIGH,INFO);

    ## Task used to write at specific address
    async def apb_wr(self, address, data_write):
        if self.dut.pready not 1:
            await RisingEdge(self.dut.pready)
        apb_print($sformatf("Start WR TRX at address: %0h with Data: %0h",addr,wdata),HIGH,INFO);
        self.dut.psel        <= 1;
        self.dut.paddr       <= address;
        self.dut.pwrite      <= 1;
        self.dut.pwdata      <= data_write;
        await RisingEdge(self.dut.pclk)
        self.dut.penable     <= 1;
        ## Transfer END
        await RisingEdge(self.dut.pclk)
        self.dut.psel        <= 0;
        self.dut.penable     <= 0;
        self.dut.pwrite      <= 0;
        ## RIF access END
        await RisingEdge(self.dut.pclk)
        if self.dut.pready not 1:
            await RisingEdge(self.dut.pready)

## Main Test
@cocotb.test()
async def test_apb_general_read_write(dut):
    apb_if = apb_interface(dut)
##    ConfigDB().set(None, "*", "apb_if", apb_interface)
##    ConfigDB().set(None, "*", "dut", dut)
    await apb_interface.apb_reset()
    #await uvm_root().run_test("apb_test_memory_rd")
