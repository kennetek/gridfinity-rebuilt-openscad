from openscadtestframework import ScadModuleTestCase, Module, ModuleTest, Cube, Square


class block_base(ScadModuleTestCase):
    def setUp(self) -> None:
        self.module = Module.from_file(
            "block_base_hole", "gridfinity-rebuilt-utility.scad")
        self.module_test = ModuleTest(self.module)
        self.module_test.add_constants_file("gridfinity-constants.scad")

    def test_hole_style_0(self) -> None:
        self.module_test.add_arguments(style_hole=0)
        self.scad_module_test(self.module_test)

    def test_hole_style_1(self) -> None:
        self.module_test.add_arguments(style_hole=1)
        self.scad_module_test(self.module_test)

    def test_hole_style_2(self) -> None:
        self.module_test.add_arguments(style_hole=2)
        self.scad_module_test(self.module_test)

    def test_hole_style_3(self) -> None:
        self.module_test.add_arguments(style_hole=3)
        self.module_test.add_dependency(Module.from_file(
            "copy_mirror", "gridfinity-rebuilt-utility.scad"))
        self.scad_module_test(self.module_test)


class rounded_rectangle(ScadModuleTestCase):
    def setUp(self) -> None:
        self.module = Module.from_file(
            "rounded_rectangle", "gridfinity-rebuilt-utility.scad")
        self.module_test = ModuleTest(self.module)

    def test_basic(self) -> None:
        self.module_test.add_arguments(50, 35, 20, 5)
        self.scad_module_test(self.module_test)

    def test_basic_different(self) -> None:
        self.module_test.add_arguments(30, 60, 50, 2)
        self.scad_module_test(self.module_test)


class pattern_linear(ScadModuleTestCase):
    def setUp(self) -> None:
        self.module = Module.from_file(
            "pattern_linear", "gridfinity-rebuilt-utility.scad")
        self.module_test = ModuleTest(self.module)

    def test_no_values(self) -> None:
        self.module_test.add_child(Cube([1, 2, 3], True))
        self.scad_module_test(self.module_test)

    def test_x_axis(self) -> None:
        self.module_test.add_arguments(x=3, sx=10)
        self.module_test.add_child(Cube([1, 2, 3], True))
        self.scad_module_test(self.module_test)

    def test_y_axis(self) -> None:
        self.module_test.add_arguments(y=3, sy=10)
        self.module_test.add_child(Cube([1, 2, 3], True))
        self.scad_module_test(self.module_test)

    def test_both_axes(self) -> None:
        self.module_test.add_arguments(x=3, y=3, sx=10, sy=10)
        self.module_test.add_child(Cube([1, 2, 3], True))
        self.scad_module_test(self.module_test)


class pattern_circular(ScadModuleTestCase):
    def setUp(self) -> None:
        self.module = Module.from_file(
            "pattern_circular", "gridfinity-rebuilt-utility.scad")
        self.module_test = ModuleTest(self.module)

    def test_no_args(self) -> None:
        self.module_test.add_child(Cube([1, 2, 3], False))
        self.scad_module_test(self.module_test)

    def test_3(self) -> None:
        self.module_test.add_arguments(3)
        self.module_test.add_child(Cube([1, 2, 3], False))
        self.scad_module_test(self.module_test)


class copy_mirror(ScadModuleTestCase):
    def setUp(self) -> None:
        self.module = Module.from_file(
            "copy_mirror", "gridfinity-rebuilt-utility.scad")
        self.module_test = ModuleTest(self.module)

    def test_no_args(self) -> None:
        self.module_test.add_child(Cube([1, 2, 3], False))
        self.scad_module_test(self.module_test)

    def test_with_args(self) -> None:
        self.module_test.add_arguments([8, 4, 9])
        self.module_test.add_child(Cube([1, 2, 3], False))
        self.scad_module_test(self.module_test)


class rounded_square(ScadModuleTestCase):
    def setUp(self) -> None:
        self.module = Module.from_file(
            "rounded_square", "gridfinity-rebuilt-utility.scad")
        self.module_test = ModuleTest(self.module)
        self.module_test.add_dependency(Module.from_file(
            "rounded_rectangle", "gridfinity-rebuilt-utility.scad"))

    def test(self) -> None:
        self.module_test.add_arguments(20, 30, 2)
        self.scad_module_test(self.module_test)


class sweep_rounded(ScadModuleTestCase):
    def setUp(self) -> None:
        self.module = Module.from_file(
            "sweep_rounded", "gridfinity-rebuilt-utility.scad")
        self.module_test = ModuleTest(self.module)
        self.module_test.add_dependency(Module.from_file(
            "pattern_circular", "gridfinity-rebuilt-utility.scad"))
        self.module_test.add_dependency(Module.from_file(
            "copy_mirror", "gridfinity-rebuilt-utility.scad"))

    def test_no_args(self) -> None:
        self.module_test.add_child(Square(5, False))
        self.scad_module_test(self.module_test)

    def test_width(self) -> None:
        self.module_test.add_arguments(w=50)
        self.module_test.add_child(Square(5, False))
        self.scad_module_test(self.module_test)

    def test_height(self) -> None:
        self.module_test.add_arguments(h=50)
        self.module_test.add_child(Square(5, False))
        self.scad_module_test(self.module_test)
