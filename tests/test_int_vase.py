from unittest import TestCase
from openscadtestframework import IntegrationTest, OutputType


class vase(TestCase):
    def setUp(self) -> None:
        self.int_test = IntegrationTest(
            "gridfinity-spiral-vase.scad", OutputType.STL)

    def tearDown(self) ->None:
        self.int_test.clean_up()

    def test_default(self) -> None:
        self.int_test.run(self.id())
        self.int_test.stl_result.compare_with_expected(self.id())

    def test_default_base(self) -> None:
        self.int_test.add_arguments(type=1)
        self.int_test.run(self.id())
        self.int_test.stl_result.compare_with_expected(self.id())

    def test_printer_settings(self) -> None:
        self.int_test.add_arguments(nozzle=0.8, layer=0.5, bottom_layer=2)
        self.int_test.run(self.id())
        self.int_test.stl_result.compare_with_expected(self.id())

    def test_general_bin_settings(self) -> None:
        self.int_test.add_arguments(gridx=2, gridy=2, gridz=3, n_divx=4)
        self.int_test.run(self.id())
        self.int_test.stl_result.compare_with_expected(self.id())
