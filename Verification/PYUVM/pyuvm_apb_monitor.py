class apb_monitor(uvm_component):
    def __init__(self, name, parent, method_name):
        super().__init__(name, parent)
        self.method_name = method_name

    def build_phase(self):
        self.ap = uvm_analysis_port("ap", self)

    def connect_phase(self):
        self.proxy = self.cdb_get("PROXY")

    async def run_phase(self):
        while True:
            get_method = getattr(self.proxy, self.method_name)
            datum = await get_method()
            self.ap.write(datum)