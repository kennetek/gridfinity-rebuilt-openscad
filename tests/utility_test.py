from pathlib import Path
from openscadtestrunner import ScadModule, OpenscadTestCase


class UtilityTesttest(OpenscadTestCase):

    def test_block_base_hole_style_0(self) -> None:
        self.scad_module_test(
            ScadModule(Path("gridfinity-rebuilt-utility.scad"),
                       "block_base_hole",
                       style_hole=1), Path("tests/expected/test_block_base_hole_style_1.stl"))


class UtilityTest(OpenscadTestCase):
    def test_block_base_hole_style_0(self) -> None:
        module = ScadModule(Path("gridfinity-rebuilt-utility.scad"),
                            "block_base_hole",
                            style_hole=1)
        self.scad_module_test(
            module, Path("tests/expected/test_block_base_hole_style_1.stl"))

    def test_block_base_hole_style_1(self) -> None:
        module = ScadModule(Path("gridfinity-rebuilt-utility.scad"),
                            "block_base_hole", style_hole=1)
        self.scad_module_test(
            module, Path("tests/expected/test_block_base_hole_style_1.stl"))

    def test_block_base_hole_style_2(self) -> None:
        module = ScadModule(Path("gridfinity-rebuilt-utility.scad"),
                            "block_base_hole", style_hole=2)
        self.scad_module_test(
            module, Path("tests/expected/test_block_base_hole_style_2.stl"))

    def test_block_base_hole_style_3(self) -> None:
        module = ScadModule(Path("gridfinity-rebuilt-utility.scad"),
                            "block_base_hole", style_hole=3)
        self.scad_module_test(
            module, Path("tests/expected/test_block_base_hole_style_3.stl"))


class BaseplateTest(OpenscadTestCase):

    def test_cutter_weight(self) -> None:
        module = ScadModule(Path("gridfinity-rebuilt-baseplate.scad"),
                            "cutter_weight")
        self.scad_module_test(
            module, Path("tests/expected/test_cutter_weight.stl"))
