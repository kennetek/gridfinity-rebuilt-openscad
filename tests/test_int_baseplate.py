from openscadtestframework import ScadIntegrationTestCase, IntegrationTest


class baseplate(ScadIntegrationTestCase):
    def setUp(self) -> None:
        self.int_test = IntegrationTest("gridfinity-rebuilt-baseplate.scad")

    def test_default(self) -> None:
        self.run_test(self.int_test)

    def test_fit_to_drawer(self) -> None:
        self.int_test.add_arguments(
            distancex=200, distancey=250, fitx=-0.5, fity=0.7)
        self.run_test(self.int_test)
