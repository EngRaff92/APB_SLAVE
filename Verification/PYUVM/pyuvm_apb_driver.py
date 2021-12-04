class apb_driver(uvm_driver):
    def connect_phase(self):
        self.proxy = self.cdb_get("PROXY")

    async def run_phase(self):
        while True:
            command = await self.seq_item_port.get_next_item()
            await self.proxy.send_op(command.A, command.B, command.op)
            self.logger.debug(f"Sent command: {command}")
            self.seq_item_port.item_done()