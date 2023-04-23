from openscadtestframework import ScadIntegrationTestCase, IntegrationTest


class vase(ScadIntegrationTestCase):
    def setUp(self) -> None:
        self.int_test = IntegrationTest("gridfinity-spiral-vase.scad")

    def test_default(self) -> None:
        self.run_test(self.int_test)

    def test_default_base(self) -> None:
        self.int_test.add_arguments(type=1)
        self.run_test(self.int_test)

    def test_printer_settings(self) -> None:
        self.int_test.add_arguments(nozzle=0.8, layer=0.5, bottom_layer=2)
        self.run_test(self.int_test)

    def test_general_bin_settings(self) -> None:
        self.int_test.add_arguments(gridx=2, gridy=2, gridz=3, n_divx=4)
        self.run_test(self.int_test)
