"""
Tests for gridfinity-rebuilt-bins.scad
@Copyright Arthur Moore 2024 MIT License
"""

from pathlib import Path
import pytest

from openscad_runner import *

@pytest.fixture(scope="class")
def default_parameters(pytestconfig):
    parameter_file_path = pytestconfig.rootpath.joinpath("tests/gridfinity-rebuilt-bins.json")
    parameter_file_data = ParameterFile.from_json(parameter_file_path.read_text())
    return parameter_file_data.parameterSets["Default"]

@pytest.fixture
def openscad_runner(pytestconfig, default_parameters) -> OpenScadRunner:
    scad_path = pytestconfig.rootpath.joinpath('gridfinity-rebuilt-bins.scad')
    scad_runner = OpenScadRunner(scad_path)
    scad_runner.image_folder_base = pytestconfig.rootpath.joinpath('images/base_hole_options/')
    scad_runner.parameters = default_parameters.copy()
    scad_runner.camera_arguments = CameraArguments(Vec3(0,0,0), CameraRotations.AngledBottom, 150)
    return scad_runner

class TestBinHoles:
    """
    Test how a single base looks with holes cut out.

    Currently only makes sure code runs, and outputs pictures for manual verification.
    """

    @classmethod
    def setUpClass(cls):
        parameter_file_path = Path("gridfinity-rebuilt-bins.json")
        parameter_file_data = ParameterFile.from_json(parameter_file_path.read_text())
        cls.default_parameters = parameter_file_data.parameterSets["Default"]

    def setUp(self, openscad_runner):
        openscad_runner = OpenScadRunner(Path('../src/core/gridfinity-rebuilt-bins.scad'))
        openscad_runner.image_folder_base = Path('../images/base_hole_options/')
        openscad_runner.parameters = self.default_parameters.copy()
        openscad_runner.camera_arguments = CameraArguments(Vec3(0,0,0), CameraRotations.AngledBottom, 150)

    def test_no_holes(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = False
        vars["screw_holes"] = False
        openscad_runner.create_image([], Path('no_holes.png'))

    def test_only_corner_holes(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["refined_holes"] = True
        vars["magnet_holes"] = False
        vars["screw_holes"] = False
        vars["only_corners"] = True
        openscad_runner.create_image([], Path('only_corner_holes.png'))

    def test_refined_holes(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["refined_holes"] = True
        vars["magnet_holes"] = False
        vars["screw_holes"] = False
        openscad_runner.create_image([], Path('refined_holes.png'))

    def test_refined_and_screw_holes(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["refined_holes"] = True
        vars["magnet_holes"] = False
        vars["screw_holes"] = True
        vars["printable_hole_top"] = False
        openscad_runner.create_image([], Path('refined_and_screw_holes.png'))

    def test_screw_holes_plain(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = False
        vars["screw_holes"] = True
        vars["printable_hole_top"] = False
        openscad_runner.create_image([], Path('screw_holes_plain.png'))

    def test_screw_holes_printable(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = False
        vars["screw_holes"] = True
        vars["printable_hole_top"] = True
        openscad_runner.create_image([], Path('screw_holes_printable.png'))

    def test_magnet_holes_plain(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = True
        vars["screw_holes"] = False
        vars["crush_ribs"] = False
        vars["chamfer_holes"] = False
        vars["printable_hole_top"] = False
        openscad_runner.create_image([], Path('magnet_holes_plain.png'))

    def test_magnet_holes_chamfered(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = True
        vars["screw_holes"] = False
        vars["crush_ribs"] = False
        vars["chamfer_holes"] = True
        vars["printable_hole_top"] = False
        openscad_runner.create_image([], Path('magnet_holes_chamfered.png'))

    def test_magnet_holes_printable(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = True
        vars["screw_holes"] = False
        vars["crush_ribs"] = False
        vars["chamfer_holes"] = False
        vars["printable_hole_top"] = True
        openscad_runner.create_image([], Path('magnet_holes_printable.png'))

    def test_magnet_holes_with_crush_ribs(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = True
        vars["screw_holes"] = False
        vars["crush_ribs"] = True
        vars["chamfer_holes"] = False
        vars["printable_hole_top"] = False
        openscad_runner.create_image([], Path('magnet_holes_with_crush_ribs.png'))

    def test_magnet_and_screw_holes_plain(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = True
        vars["screw_holes"] = True
        vars["crush_ribs"] = False
        vars["chamfer_holes"] = False
        vars["printable_hole_top"] = False
        openscad_runner.create_image([], Path('magnet_and_screw_holes_plain.png'))

    def test_magnet_and_screw_holes_printable(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = True
        vars["screw_holes"] = True
        vars["crush_ribs"] = False
        vars["chamfer_holes"] = False
        vars["printable_hole_top"] = True
        openscad_runner.create_image([], Path('magnet_and_screw_holes_printable.png'))

    def test_magnet_and_screw_holes_all(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = True
        vars["screw_holes"] = True
        vars["crush_ribs"] = True
        vars["chamfer_holes"] = True
        vars["printable_hole_top"] = True
        openscad_runner.create_image([], Path('magnet_and_screw_holes_all.png'))
