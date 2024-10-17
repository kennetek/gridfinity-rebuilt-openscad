"""
Tests for gridfinity-spiral-vase.scad
@Copyright Arthur Moore 2024 MIT License
"""

from pathlib import Path
import pytest

from openscad_runner import *

@pytest.fixture(scope="class")
def default_parameters(pytestconfig):
    parameter_file_path = pytestconfig.rootpath.joinpath("tests/gridfinity-spiral-vase.json")
    parameter_file_data = ParameterFile.from_json(parameter_file_path.read_text())
    return parameter_file_data.parameterSets["Default"]

@pytest.fixture
def openscad_runner(pytestconfig, default_parameters) -> OpenScadRunner:
    scad_path = pytestconfig.rootpath.joinpath('gridfinity-spiral-vase.scad')
    scad_runner = OpenScadRunner(scad_path)
    scad_runner.image_folder_base = pytestconfig.rootpath.joinpath('images/spiral_vase_base/')
    scad_runner.parameters = default_parameters.copy()
    scad_runner.camera_arguments = CameraArguments(Vec3(0,0,0), CameraRotations.AngledBottom, 150)
    return scad_runner

class TestSpiralVaseBase:
    """
    Test creating a single base in "gridfinity-spiral-vase.scad"

    Currently only makes sure code runs, and outputs pictures for manual verification.
    """

    def test_no_holes(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["type"] = 1 # Create a Base
        vars["enable_holes"] = False
        openscad_runner.create_image([], Path('no_holes_bottom.png'))
        openscad_runner.camera_arguments = openscad_runner.camera_arguments.with_rotation(CameraRotations.Top)
        openscad_runner.create_image([], Path('no_holes_top.png'))

    def test_holes(self, openscad_runner):
        vars = openscad_runner.parameters
        vars["type"] = 1 # Create a Base
        vars["enable_holes"] = True
        openscad_runner.create_image([], Path('with_holes_bottom.png'))
        openscad_runner.camera_arguments = openscad_runner.camera_arguments.with_rotation(CameraRotations.Top)
        openscad_runner.create_image([], Path('with_holes_top.png'))
