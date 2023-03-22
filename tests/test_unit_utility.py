from openscadtestframework import ScadTestCase, Module, ModuleTest


class block_base(ScadTestCase):
    def setUp(self) -> None:
        self.module = Module.from_file(
            "block_base_hole", "gridfinity-rebuilt-utility.scad")
        self.module_test = ModuleTest(self.module)
        self.module_test.add_constants_file("gridfinity-constants.scad")

    def test_hole_style_0(self) -> None:
        self.module_test.add_arguments(style_hole=0)
        self.scad_module_test(
            self.module_test, "test_block_base_hole_style_1.stl")

    def test_hole_style_1(self) -> None:
        self.module_test.add_arguments(style_hole=1)
        self.scad_module_test(
            self.module_test, "test_block_base_hole_style_1.stl")

    def test_hole_style_2(self) -> None:
        self.module_test.add_arguments(style_hole=2)
        self.scad_module_test(
            self.module_test, "test_block_base_hole_style_2.stl")

    def test_hole_style_3(self) -> None:
        self.module_test.add_arguments(style_hole=3)
        self.module_test.add_dependency(Module.from_file(
            "copy_mirror", "gridfinity-rebuilt-utility.scad"))
        self.scad_module_test(
            self.module_test, "test_block_base_hole_style_3.stl")


class rounded_rectangle(ScadTestCase):
    def setUp(self) -> None:
        self.module = Module.from_file(
            "rounded_rectangle", "gridfinity-rebuilt-utility.scad")
        self.module_test = ModuleTest(self.module)

    def test_basic(self) -> None:
        self.module_test.add_arguments(50, 35, 20, 5)
        self.scad_module_test(
            self.module_test, "test_rounded_rectangle_basic.stl")

    def test_basic_different(self) -> None:
        self.module_test.add_arguments(30, 60, 50, 2)
        self.scad_module_test(
            self.module_test, "test_rounded_rectangle_basic_different.stl", keep_files=True)
