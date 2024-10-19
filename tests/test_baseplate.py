"""
Tests for gridfinity-rebuilt-baseplate.scad
@Copyright Arthur Moore 2024 MIT License
"""

from pathlib import Path
import pytest

from openscad_runner import *

@pytest.fixture(scope="class")
def default_parameters(pytestconfig):
    parameter_file_path = pytestconfig.rootpath.joinpath("tests/gridfinity-rebuilt-baseplate.json")
    parameter_file_data = ParameterFile.from_json(parameter_file_path.read_text())
    return parameter_file_data.parameterSets["Default"]

@pytest.fixture
def openscad_runner(pytestconfig, default_parameters) -> OpenScadRunner:
    scad_path = pytestconfig.rootpath.joinpath('gridfinity-rebuilt-baseplate.scad')
    scad_runner = OpenScadRunner(scad_path)
    scad_runner.image_folder_base = pytestconfig.rootpath.joinpath('images/baseplate/')
    scad_runner.parameters = default_parameters.copy()
    scad_runner.camera_arguments = CameraArguments(Vec3(0,0,0), CameraRotations.AngledBottom, 150)
    return scad_runner

class TestBasePlateHoles:
    """
    Test creating a single base in "gridfinity-spiral-vase.scad"

    Currently only makes sure code runs, and outputs pictures for manual verification.
    """

    def test_no_holes(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["enable_magnet"] = False
        vars["style_hole"] = 0
        openscad_runner.create_image([], Path('no_holes_bottom.png'))
        openscad_runner.camera_arguments = openscad_runner.camera_arguments.with_rotation(CameraRotations.AngledTop)
        openscad_runner.create_image([], Path('no_holes_top.png'))

    def test_plain_magnet_holes(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["enable_magnet"] = True
        vars["style_hole"] = 0
        vars["chamfer_holes"] = False
        vars["crush_ribs"] = False
        openscad_runner.create_image([], Path('magnet_holes_bottom.png'))
        openscad_runner.camera_arguments = openscad_runner.camera_arguments.with_rotation(CameraRotations.AngledTop)
        openscad_runner.create_image([], Path('plain_magnet_holes_top.png'))

    def test_chamfered_magnet_holes(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["enable_magnet"] = True
        vars["style_hole"] = 0
        vars["chamfer_holes"] = True
        vars["crush_ribs"] = False
        openscad_runner.camera_arguments = openscad_runner.camera_arguments.with_rotation(CameraRotations.AngledTop)
        openscad_runner.create_image([], Path('chamfered_magnet_holes.png'))

    def test_ribbed_magnet_holes(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["enable_magnet"] = True
        vars["style_hole"] = 0
        vars["chamfer_holes"] = False
        vars["crush_ribs"] = True
        openscad_runner.camera_arguments = openscad_runner.camera_arguments.with_rotation(CameraRotations.AngledTop)
        openscad_runner.create_image([], Path('ribbed_magnet_holes.png'))

    def test_chamfered_and_ribbed_magnet_holes(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["enable_magnet"] = True
        vars["style_hole"] = 0
        vars["chamfer_holes"] = True
        vars["crush_ribs"] = True
        openscad_runner.camera_arguments = openscad_runner.camera_arguments.with_rotation(CameraRotations.AngledTop)
        openscad_runner.create_image([], Path('chamfered_and_ribbed_magnet_holes.png'))

    def test_only_countersunk_screw_holes(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["enable_magnet"] = False
        vars["style_hole"] = 1
        openscad_runner.create_image([], Path('only_countersunk_screw_holes_bottom.png'))
        openscad_runner.camera_arguments = openscad_runner.camera_arguments.with_rotation(CameraRotations.AngledTop)
        openscad_runner.create_image([], Path('only_countersunk_screw_holes_top.png'))

    def test_only_counterbored_screw_holes(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["enable_magnet"] = False
        vars["style_hole"] = 2
        openscad_runner.create_image([], Path('only_counterbored_screw_holes_bottom.png'))
        openscad_runner.camera_arguments = openscad_runner.camera_arguments.with_rotation(CameraRotations.AngledTop)
        openscad_runner.create_image([], Path('only_counterbored_screw_holes_top.png'))

    def test_magnet_and_countersunk_screw_holes(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["enable_magnet"] = True
        vars["chamfer_holes"] = False
        vars["crush_ribs"] = False
        vars["style_hole"] = 1
        openscad_runner.create_image([], Path('magnet_and_countersunk_screw_holes_bottom.png'))
        openscad_runner.camera_arguments = openscad_runner.camera_arguments.with_rotation(CameraRotations.AngledTop)
        openscad_runner.create_image([], Path('magnet_and_countersunk_screw_holes_top.png'))

    def test_magnet_and_counterbored_screw_holes(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["enable_magnet"] = True
        vars["chamfer_holes"] = False
        vars["crush_ribs"] = False
        vars["style_hole"] = 2
        openscad_runner.create_image([], Path('magnet_and_counterbored_screw_holes_bottom.png'))
        openscad_runner.camera_arguments = openscad_runner.camera_arguments.with_rotation(CameraRotations.AngledTop)
        openscad_runner.create_image([], Path('magnet_and_counterbored_screw_holes_top.png'))
