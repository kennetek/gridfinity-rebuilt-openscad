from unittest import TestCase
from openscadtestframework import IntegrationTest, OutputType


# these tescases are all wrong, there is a bug in the baseplates which affects almost all renders

class baseplate(TestCase):
    def setUp(self) -> None:
        self.int_test = IntegrationTest(
            "gridfinity-rebuilt-baseplate.scad", OutputType.STL)

    def test_default(self) -> None:
        self.int_test.run(self.id())

    def test_fit_to_drawer(self) -> None:
        self.int_test.add_arguments(
            distancex=200, distancey=250, fitx=-0.5, fity=0.7)
        self.int_test.run(self.id())

    def test_screw_together(self) -> None:
        self.int_test.add_arguments(style_plate=3)
        self.int_test.run(self.id())

    def test_skeletonized(self) -> None:
        self.int_test.add_arguments(style_plate=2)
        self.int_test.run(self.id())

    def test_weigthed(self) -> None:
        self.int_test.add_arguments(style_plate=1)
        self.int_test.run(self.id())
