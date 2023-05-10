from unittest import TestCase, skip
from openscadtestframework import IntegrationTest


class bins(TestCase):
    def setUp(self) -> None:
        self.int_test = IntegrationTest("gridfinity-rebuilt-bins.scad")

    def test_default(self) -> None:
        self.int_test.run(self.id())

    def test_2x2x3(self) -> None:
        self.int_test.add_arguments(gridx=2, gridy=2, gridz=3)
        self.int_test.run(self.id())

    def test_compartment_3x2(self) -> None:
        self.int_test.add_arguments(
            gridx=1, gridy=1, gridz=6, divx=3, divy=2, style_tab=5)
        self.int_test.run(self.id())

    @skip("Feature broken, fixed in another branch")
    def test_style_corner(self) -> None:
        self.int_test.add_arguments(
            gridx=2, gridy=2, gridz=6, style_corner=True)
        self.int_test.run(self.id())

    def test_gridz_define_1(self) -> None:
        self.int_test.add_arguments(
            gridx=1, gridy=1, gridz=20, gridz_define=1)
        self.int_test.run(self.id())

    def test_gridz_define_2(self) -> None:
        self.int_test.add_arguments(
            gridx=1, gridy=1, gridz=30, gridz_define=2)
        self.int_test.run(self.id())

    def test_no_holes(self) -> None:
        self.int_test.add_arguments(
            gridx=1, gridy=1, gridz=6, style_hole=0)
        self.int_test.run(self.id())

    def test_div_base_2x3(self) -> None:
        self.int_test.add_arguments(
            gridx=1, gridy=1, gridz=6, div_base_x=2, div_base_y=3)
        self.int_test.run(self.id())
