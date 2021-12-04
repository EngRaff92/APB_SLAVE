from pyuvm import *
from cocotb.triggers import ClockCycles
import enum
import random


class apb_env(uvm_env):

    def build_phase(self):
        self.cmd_mon = Monitor("cmd_mon", self, "get_cmd")
        self.result_mon = Monitor("result_mon", self, "get_result")
        self.scoreboard = Scoreboard("scoreboard", self)
        self.coverage = Coverage("coverage", self)
        self.driver = Driver("driver", self)
        self.seqr = uvm_sequencer("seqr", self)
        ConfigDB().set(None, "*", "SEQR", self.seqr)

    def connect_phase(self):
        self.cmd_mon.ap.connect(self.scoreboard.cmd_export)
        self.cmd_mon.ap.connect(self.coverage)
        self.result_mon.ap.connect(self.scoreboard.result_export)
        self.driver.seq_item_port.connect(self.seqr.seq_item_export)
