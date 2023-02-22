from unittest import TestCase
from openscad_test_runner import OpenScadModuleTestRunner, Module


class UtilityTest(TestCase):
    def setUp(self):
        self.runner = OpenScadModuleTestRunner()

    def test_block_base_hole_style_0(self):
        module = Module("../gridfinity-rebuilt-utility.scad",
                        "block_base_hole",
                        style_hole=1)
        self.runner.Run(
            module, "tests/expected/test_block_base_hole_style_1.stl")

    def test_block_base_hole_style_1(self):
        module = Module("../gridfinity-rebuilt-utility.scad",
                        "block_base_hole", style_hole=1)
        self.runner.Run(
            module, "tests/expected/test_block_base_hole_style_1.stl")

    def test_block_base_hole_style_2(self):
        module = Module("../gridfinity-rebuilt-utility.scad",
                        "block_base_hole", style_hole=2)
        self.runner.Run(
            module, "tests/expected/test_block_base_hole_style_2.stl")

    def test_block_base_hole_style_3(self):
        module = Module("../gridfinity-rebuilt-utility.scad",
                        "block_base_hole", style_hole=3)
        self.runner.Run(
            module, "tests/expected/test_block_base_hole_style_3.stl")


class BaseplateTest(TestCase):
    def setUp(self):
        self.runner = OpenScadModuleTestRunner()

    def test_cutter_weight(self):
        module = Module("../gridfinity-rebuilt-baseplate.scad",
                        "cutter_weight")
        self.runner.Run(
            module, "tests/expected/test_cutter_weight.stl", way="use")
