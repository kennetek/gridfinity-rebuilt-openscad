from openscadtestframework import ScadTestCase, Module, ModuleTest


class cutter_weight(ScadTestCase):

    def test_cutter_weight(self) -> None:
        module = Module.from_file(
            "cutter_weight", "gridfinity-rebuilt-baseplate.scad")

        module_test = ModuleTest(module)
        module_test.add_constants_file("gridfinity-constants.scad")
        module_test.add_dependency(Module.from_file(
            "pattern_circular", "gridfinity-rebuilt-utility.scad"))
        self.scad_module_test(module_test)
