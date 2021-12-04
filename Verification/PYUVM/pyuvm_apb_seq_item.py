from pyuvm import *
from cocotb.triggers import ClockCycles
import enum
import random

class apb_seq_item(uvm_sequence_item):

    def __init__(self, name, aa=0, bb=0, op=Ops.ADD):
        super().__init__(name)
        self.A = aa
        self.B = bb
        self.op = Ops(op)

    def __eq__(self, other):
        same = self.A == other.A and self.B == other.B and self.op == other.op
        return same

    def __str__(self):
        return f"{self.get_name()} : A: 0x{self.A:02x} "
        f"OP: {self.op.name} ({self.op.value}) B: 0x{self.B:02x}"

    def randomize(self):
        self.A = random.randint(0, 255)
        self.B = random.randint(0, 255)
        self.op = random.choice(list(Ops))