from unittest import TestCase
from openscadtestframework import Module, ModuleTest, OutputType, Cube, Square


class block_base(TestCase):
    def setUp(self) -> None:
        self.module = Module.from_file(
            "block_base_hole", "gridfinity-rebuilt-utility.scad")
        self.module_test = ModuleTest(self.module, OutputType.STL)
        self.module_test.add_constants_file("gridfinity-constants.scad")

    def tearDown(self) ->None:
        self.module_test.clean_up()

    def test_hole_style_0(self) -> None:
        self.module_test.add_arguments(style_hole=0)
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())

    def test_hole_style_1(self) -> None:
        self.module_test.add_arguments(style_hole=1)
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())

    def test_hole_style_2(self) -> None:
        self.module_test.add_arguments(style_hole=2)
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())

    def test_hole_style_3(self) -> None:
        self.module_test.add_arguments(style_hole=3)
        self.module_test.add_dependency(Module.from_file(
            "copy_mirror", "gridfinity-rebuilt-utility.scad"))
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())


class rounded_rectangle(TestCase):
    def setUp(self) -> None:
        self.module = Module.from_file(
            "rounded_rectangle", "gridfinity-rebuilt-utility.scad")
        self.module_test = ModuleTest(self.module, OutputType.STL)

    def tearDown(self) ->None:
        self.module_test.clean_up()

    def test_basic(self) -> None:
        self.module_test.add_arguments(50, 35, 20, 5)
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())

    def test_basic_different(self) -> None:
        self.module_test.add_arguments(30, 60, 50, 2)
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())


class pattern_linear(TestCase):
    def setUp(self) -> None:
        self.module = Module.from_file(
            "pattern_linear", "gridfinity-rebuilt-utility.scad")
        self.module_test = ModuleTest(self.module, OutputType.STL)

    def tearDown(self) ->None:
        self.module_test.clean_up()

    def test_no_values(self) -> None:
        self.module_test.add_child(Cube([1, 2, 3], True))
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())

    def test_x_axis(self) -> None:
        self.module_test.add_arguments(x=3, sx=10)
        self.module_test.add_child(Cube([1, 2, 3], True))
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())

    def test_y_axis(self) -> None:
        self.module_test.add_arguments(y=3, sy=10)
        self.module_test.add_child(Cube([1, 2, 3], True))
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())

    def test_both_axes(self) -> None:
        self.module_test.add_arguments(x=3, y=3, sx=10, sy=10)
        self.module_test.add_child(Cube([1, 2, 3], True))
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())


class pattern_circular(TestCase):
    def setUp(self) -> None:
        self.module = Module.from_file(
            "pattern_circular", "gridfinity-rebuilt-utility.scad")
        self.module_test = ModuleTest(self.module, OutputType.STL)

    def tearDown(self) ->None:
        self.module_test.clean_up()

    def test_no_args(self) -> None:
        self.module_test.add_child(Cube([1, 2, 3], False))
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())

    def test_3(self) -> None:
        self.module_test.add_arguments(3)
        self.module_test.add_child(Cube([1, 2, 3], False))
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())


class copy_mirror(TestCase):
    def setUp(self) -> None:
        self.module = Module.from_file(
            "copy_mirror", "gridfinity-rebuilt-utility.scad")
        self.module_test = ModuleTest(self.module, OutputType.STL)

    def tearDown(self) ->None:
        self.module_test.clean_up()

    def test_no_args(self) -> None:
        self.module_test.add_child(Cube([1, 2, 3], False))
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())

    def test_with_args(self) -> None:
        self.module_test.add_arguments([8, 4, 9])
        self.module_test.add_child(Cube([1, 2, 3], False))
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())


class rounded_square(TestCase):
    def setUp(self) -> None:
        self.module = Module.from_file(
            "rounded_square", "gridfinity-rebuilt-utility.scad")
        self.module_test = ModuleTest(self.module, OutputType.STL)
        self.module_test.add_dependency(Module.from_file(
            "rounded_rectangle", "gridfinity-rebuilt-utility.scad"))

    def tearDown(self) ->None:
        self.module_test.clean_up()

    def test(self) -> None:
        self.module_test.add_arguments(20, 30, 2)
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())


class sweep_rounded(TestCase):
    def setUp(self) -> None:
        self.module = Module.from_file(
            "sweep_rounded", "gridfinity-rebuilt-utility.scad")
        self.module_test = ModuleTest(self.module, OutputType.STL)
        self.module_test.add_dependency(Module.from_file(
            "pattern_circular", "gridfinity-rebuilt-utility.scad"))
        self.module_test.add_dependency(Module.from_file(
            "copy_mirror", "gridfinity-rebuilt-utility.scad"))

    def tearDown(self) ->None:
        self.module_test.clean_up()

    def test_no_args(self) -> None:
        self.module_test.add_child(Square(5, False))
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())
        # self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())

    def test_width(self) -> None:
        self.module_test.add_arguments(w=50)
        self.module_test.add_child(Square(5, False))
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())
        # self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())

    def test_height(self) -> None:
        self.module_test.add_arguments(h=50)
        self.module_test.add_child(Square(5, False))
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())
        # self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())


class profile_cutter_tab(TestCase):
    def setUp(self) -> None:
        self.module = Module.from_file(
            "profile_cutter_tab", "gridfinity-rebuilt-utility.scad")
        self.module_test = ModuleTest(self.module, OutputType.SVG)
        self.module_test.add_constants_file("gridfinity-constants.scad")

    def tearDown(self) ->None:
        self.module_test.clean_up()

    def test_normal(self) -> None:
        self.module_test.add_arguments(10, 20, 30)
        self.module_test.run(self.id())
        self.module_test.svg_result.compare_with_expected(self.id())

    def test_normal_alternative(self) -> None:
        self.module_test.add_arguments(30, 40, 60)
        self.module_test.run(self.id())
        self.module_test.svg_result.compare_with_expected(self.id())

    def test_no_output(self) -> None:
        self.module_test.add_arguments(10, 0, 30)
        self.assertRaises(OSError, self.module_test.run, self.id())


class profile_cutter(TestCase):
    def setUp(self) -> None:
        self.module_test = ModuleTest(Module.from_file(
            "profile_cutter", "gridfinity-rebuilt-utility.scad"), OutputType.SVG)
        self.module_test.add_constants_file("gridfinity-constants.scad")
        self.module_test.add_global_variable("dh", 50)

    def tearDown(self) ->None:
        self.module_test.clean_up()

    def test_no_scoop(self) -> None:
        self.module_test.add_arguments(40, 20, 0)
        self.module_test.run(self.id())
        self.module_test.svg_result.compare_with_expected(self.id())

    def test_with_scoop(self) -> None:
        self.module_test.add_arguments(40, 20, 1)
        self.module_test.run(self.id())
        self.module_test.svg_result.compare_with_expected(self.id())

    def test_with_scoop_altenative(self) -> None:
        self.module_test.add_arguments(20, 40, 1)
        self.module_test.run(self.id())
        self.module_test.svg_result.compare_with_expected(self.id())


class fillet_cutter(TestCase):
    def setUp(self) -> None:
        self.module_test = ModuleTest(Module.from_file(
            "fillet_cutter", "gridfinity-rebuilt-utility.scad"), OutputType.STL)
        self.module_test.add_constants_file("gridfinity-constants.scad")

    def tearDown(self) ->None:
        self.module_test.clean_up()

    def test_no_args(self) -> None:
        self.module_test.add_child(Cube([10, 10, 10]))
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())

    def test_t(self) -> None:
        self.module_test.add_arguments(20)
        self.module_test.add_child(Cube([10, 10, 10]))
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())


class transform_tab(TestCase):
    def setUp(self) -> None:
        self.module_test = ModuleTest(Module.from_file(
            "transform_tab", "gridfinity-rebuilt-utility.scad"), OutputType.STL)
        self.module_test.add_constants_file("gridfinity-constants.scad")
        self.module_test.add_dependency(Module.from_file(
            "copy_mirror", "gridfinity-rebuilt-utility.scad"))

    def tearDown(self) -> None:
        self.module_test.clean_up()

    def test_left(self) -> None:
        self.module_test.add_arguments(-1, 70, 0)
        self.module_test.add_child(Square([10, 10]))
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())

    def test_center(self) -> None:
        self.module_test.add_arguments(0, 70, 0)
        self.module_test.add_child(Square([10, 10]))
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())

    def test_right(self) -> None:
        self.module_test.add_arguments(1, 70, 0)
        self.module_test.add_child(Square([10, 10]))
        self.module_test.run(self.id())
        self.module_test.stl_result.compare_with_expected(self.id())
