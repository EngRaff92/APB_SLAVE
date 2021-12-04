class apb_base_test(uvm_test):
    def build_phase(self):
        self.env = AluEnv.create("env", self)

    async def run_phase(self):
        self.raise_objection()
        seqr = ConfigDB().get(self, "", "SEQR")
        dut = ConfigDB().get(self, "", "DUT")
        seq = AluSeq("seq")
        await seq.start(seqr)
        await ClockCycles(dut.clk, 50)  # to do last transaction
        self.drop_objection()

    def end_of_elaboration_phase(self):
        self.set_logging_level_hier(logging.DEBUG)