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

""" Main TB top entity used to run tests and generate clocks and reset sequences"""

#######################################################################################
## Import Files
#######################################################################################
## Import From
from cocotb.triggers    import FallingEdge, RisingEdge, ReadOnly
from cocotb.triggers    import Timer
from cocotb.triggers    import Event
from cocotb.triggers    import Join, First, Combine
from cocotb.clock       import Clock
from cocotb.result      import TestFailure, ReturnValue
from pyuvm              import *
## Single import
import cocotb
import pyuvm_apb_base_test
import sys

## Main interface
class apb_interface:
    ## Init
    def __init__(self, dut):
        self.dut        = dut
        self.reset_done = Event("apb_reset_done")

    ## clock generation
    async def wait_clock(self,cycles):
        """wait for clock pulses"""
        for cycle in range(cycles):
            await RisingEdge(self.dut.pclk)

    ## Task used to set a known state (only used over reset)
    async def set_known_state(self):
        self.dut.psel.value     = 0
        self.dut.paddr.value    = 0
        self.dut.pwrite.value   = 0
        self.dut.pwdata.value   = 0
        self.dut.penable.value  = 0

    ## task to drive the reset
    async def apb_reset(self):
        ## clear out the event
        self.reset_done.clear()
        ## set the RTL to a known state
        await self.set_known_state()
        ## Issue a reset routine
        self.dut.pclk_en.value  = 1
        self.dut.prst.value     = 0
        await Timer(5, units='ns')
        self.dut.pclk_en.value  = 1
        self.dut.prst.value     = 0
        await Timer(5, units='ns')
        self.dut.prst.value     = 1
        await Timer(5, units='ns')
        self.dut.prst.value     = 0
        ## Set the event
        self.reset_done.set()
    
    ## Task used to wait for reset completion
    async def wait_for_reset(self):
        self.reset_done.wait()

    ## Task used to read from specific address
    async def apb_rd(self, address):
        if self.dut.pready.value != 1:
            await RisingEdge(self.dut.pready)
        self.dut.psel.value     = 1
        self.dut.paddr.value    = address
        self.dut.pwrite.value   = 0
        self.dut.pwdata.value   = 0
        await RisingEdge(self.dut.pclk)
        self.dut.penable.value  = 1
        ## Transfer END
        await RisingEdge(self.dut.pclk)
        self.dut.psel.value     = 0
        self.dut.penable.value  = 0
        await RisingEdge(self.dut.pclk)
        ## Make sure all signals are stable enough before reading
        ReadOnly() ## (POSTPONED region for SV scheduler)
        ## APB access END
        data_read               = self.dut.prdata.value
        if self.dut.pready.value != 1:
            await RisingEdge(self.dut.pready)
        return data_read

    ## Task used to write at specific address
    async def apb_wr(self, address, data_write):
        if self.dut.pready.value != 1:
            await RisingEdge(self.dut.pready)
        self.dut.psel.value     = 1
        self.dut.paddr.value    = address
        self.dut.pwrite.value   = 1
        self.dut.pwdata.value   = data_write
        await RisingEdge(self.dut.pclk)
        self.dut.penable.value  = 1
        ## Transfer END
        await RisingEdge(self.dut.pclk)
        self.dut.psel.value     = 0
        self.dut.penable .value = 0
        self.dut.pwrite.value   = 0
        ## APB access END
        await RisingEdge(self.dut.pclk)
        if self.dut.pready.value != 1:
            await RisingEdge(self.dut.pready)

## Main TOP class
@cocotb.test()
async def apb_tb_top_entity(dut):
    ## Remember cocotb.top points to the DUT
    apb_if = apb_interface(cocotb.top)
    ## Set the interface trhough the configuration database
    ConfigDB().set(None, "*", "apb_if", apb_if)
    dut._log.info("Running Reset")
    cocotb.start_soon(apb_if.apb_reset())
    dut._log.info("Running Clock")
    cocotb.start_soon(Clock(dut.pclk, 2, units='ns').start())
    ## Start Test
    await uvm_root().run_test("apb_base_test")
