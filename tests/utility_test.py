from openscadtestframework import ScadTestCase, Module, ModuleTest


class UtilityTesttest(ScadTestCase):

    def test_block_base_hole_style_0(self) -> None:
        tested_module = Module.from_file(
            "block_base_hole", "gridfinity-rebuilt-utility.scad")
        module_test = ModuleTest(tested_module, style_hole=1)
        module_test.add_constants_file("gridfinity-constants.scad")
        module_test.add_dependency(
            Module("Test_mod", ['echo("something");'], []))

        self.scad_module_test(
            module_test, "test_block_base_hole_style_1.stl")


class block_base(ScadTestCase):
    def setUp(self) -> None:
        self.module = Module.from_file(
            "block_base_hole", "gridfinity-rebuilt-utility.scad")
        self.module_test = ModuleTest(self.module)
        self.module_test.add_constants_file("gridfinity-constants.scad")

    def test_hole_style_0(self) -> None:
        self.module_test.add_arguments(style_hole=0)
        self.scad_module_test(
            self.module_test, "test_block_base_hole_style_1.stl", keep_files=True)

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
            self.module_test, "test_block_base_hole_style_3.stl", keep_files=True)


class BaseplateTest(ScadTestCase):

    def test_cutter_weight(self) -> None:
        module = Module.from_file(
            "cutter_weight", "gridfinity-rebuilt-baseplate.scad")

        module_test = ModuleTest(module)
        module_test.add_constants_file("gridfinity-constants.scad")
        module_test.add_dependency(Module.from_file(
            "pattern_circular", "gridfinity-rebuilt-utility.scad"))
        self.scad_module_test(
            module_test, "test_cutter_weight.stl")
