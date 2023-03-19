from unittest import TestCase
from openscadtestrunner import OpenScadModuleTestRunner, Module, OpenscadTestCase


class UtilityTesttest(OpenscadTestCase):

    def test_block_base_hole_style_0(self):
        self.scad_module_test(
            Module("gridfinity-rebuilt-utility.scad",
                   "block_base_hole",
                   style_hole=1), "tests/expected/test_block_base_hole_style_1.stl")


class UtilityTest(OpenscadTestCase):
    def test_block_base_hole_style_0(self):
        module = Module("gridfinity-rebuilt-utility.scad",
                        "block_base_hole",
                        style_hole=1)
        self.scad_module_test(
            module, "tests/expected/test_block_base_hole_style_1.stl")

    def test_block_base_hole_style_1(self):
        module = Module("gridfinity-rebuilt-utility.scad",
                        "block_base_hole", style_hole=1)
        self.scad_module_test(
            module, "tests/expected/test_block_base_hole_style_1.stl")

    def test_block_base_hole_style_2(self):
        module = Module("gridfinity-rebuilt-utility.scad",
                        "block_base_hole", style_hole=2)
        self.scad_module_test(
            module, "tests/expected/test_block_base_hole_style_2.stl")

    def test_block_base_hole_style_3(self):
        module = Module("gridfinity-rebuilt-utility.scad",
                        "block_base_hole", style_hole=3)
        self.scad_module_test(
            module, "tests/expected/test_block_base_hole_style_3.stl")


class BaseplateTest(OpenscadTestCase):

    def test_cutter_weight(self):
        module = Module("gridfinity-rebuilt-baseplate.scad",
                        "cutter_weight")
        self.scad_module_test(
            module, "tests/expected/test_cutter_weight.stl")
