"""
Tests for gridfinity-rebuilt-bins.scad
@Copyright Arthur Moore 2024 MIT License
"""

import dataclasses
import json
import unittest
from pathlib import Path
from tempfile import NamedTemporaryFile

from openscad_runner import *

class TestSpiralVaseBase(unittest.TestCase):
    """
    Test creating a single base in "gridfinity-spiral-vase.scad"

    Currently only makes sure code runs, and outputs pictures for manual verification.
    """

    @classmethod
    def setUpClass(cls):
        parameter_file_path = Path("gridfinity-spiral-vase.json")
        parameter_file_data = ParameterFile.from_json(parameter_file_path.read_text())
        cls.default_parameters = parameter_file_data.parameterSets["Default"]
        cls.camera_args = CameraArguments(Vec3(0,0,0),Vec3(225,0,225),150)

    def setUp(self):
        self.scad_runner = OpenScadRunner(Path('../gridfinity-spiral-vase.scad'))
        self.scad_runner.image_folder_base = Path('../images/spiral_vase_base/')
        self.scad_runner.parameters = self.default_parameters.copy()
        self.scad_runner.parameters["type"] = 1 # Create a Base

    def test_no_holes(self):
        vars = self.scad_runner.parameters
        vars["enable_holes"] = False
        self.scad_runner.create_image(self.camera_args, [], Path('no_holes_bottom.png'))
        self.camera_args = CameraArguments(Vec3(0,0,0),Vec3(45,0,0),150)
        self.scad_runner.create_image(self.camera_args, [], Path('no_holes_top.png'))

    def test_refined_holes(self):
        vars = self.scad_runner.parameters
        vars["enable_holes"] = True
        self.scad_runner.create_image(self.camera_args, [], Path('with_holes_bottom.png'))
        self.camera_args = CameraArguments(Vec3(0,0,0),Vec3(45,0,0),150)
        self.scad_runner.create_image(self.camera_args, [], Path('with_holes_top.png'))


if __name__ == '__main__':
    unittest.main()
