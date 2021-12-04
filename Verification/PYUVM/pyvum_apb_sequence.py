class apb_sequence(uvm_sequence):
    async def body(self):
        for op in list(Ops):
            cmd_tr = AluSeqItem("cmd_tr")
            await self.start_item(cmd_tr)
            cmd_tr.randomize()
            cmd_tr.op = op
            await self.finish_item(cmd_tr)