from unittest import TestCase
from openscadtestframework import Module, ModuleTest, OutputType


class cutter_weight(TestCase):

    def test_cutter_weight(self) -> None:
        module = Module.from_file(
            "cutter_weight", "gridfinity-rebuilt-baseplate.scad")

        module_test = ModuleTest(module, OutputType.STL)
        module_test.add_constants_file("gridfinity-constants.scad")
        module_test.add_dependency(Module.from_file(
            "pattern_circular", "gridfinity-rebuilt-utility.scad"))
        module_test.run(self.id())
