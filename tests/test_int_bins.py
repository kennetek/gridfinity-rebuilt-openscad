from openscadtestframework import ScadIntegrationTestCase, IntegrationTest


class bins(ScadIntegrationTestCase):
    def setUp(self) -> None:
        self.int_test = IntegrationTest("gridfinity-rebuilt-bins.scad")

    def test_default_bin(self) -> None:
        self.run_test(self.int_test, keep_files=True)
