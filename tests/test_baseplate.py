"""
Tests for gridfinity-rebuilt-baseplate.scad
@Copyright Arthur Moore 2024 MIT License
"""

import dataclasses
import json
import unittest
from pathlib import Path
from tempfile import NamedTemporaryFile

from openscad_runner import *

class TestBasePlateHoles(unittest.TestCase):
    """
    Test creating a single base in "gridfinity-spiral-vase.scad"

    Currently only makes sure code runs, and outputs pictures for manual verification.
    """

    @classmethod
    def setUpClass(cls):
        parameter_file_path = Path("gridfinity-rebuilt-baseplate.json")
        parameter_file_data = ParameterFile.from_json(parameter_file_path.read_text())
        cls.default_parameters = parameter_file_data.parameterSets["Default"]

    def setUp(self):
        self.scad_runner = OpenScadRunner(Path('../gridfinity-rebuilt-baseplate.scad'))
        self.scad_runner.image_folder_base = Path('../images/baseplate/')
        self.scad_runner.parameters = self.default_parameters.copy()
        self.scad_runner.camera_arguments = CameraArguments(Vec3(0,0,0), CameraRotations.AngledBottom, 150)

    def test_no_holes(self):
        vars = self.scad_runner.parameters
        vars["enable_magnet"] = False
        vars["style_hole"] = 0
        self.scad_runner.create_image([], Path('no_holes_bottom.png'))
        self.scad_runner.camera_arguments = self.scad_runner.camera_arguments.with_rotation(CameraRotations.AngledTop)
        self.scad_runner.create_image([], Path('no_holes_top.png'))

    def test_plain_magnet_holes(self):
        vars = self.scad_runner.parameters
        vars["enable_magnet"] = True
        vars["style_hole"] = 0
        vars["chamfer_holes"] = False
        vars["crush_ribs"] = False
        self.scad_runner.create_image([], Path('magnet_holes_bottom.png'))
        self.scad_runner.camera_arguments = self.scad_runner.camera_arguments.with_rotation(CameraRotations.AngledTop)
        self.scad_runner.create_image([], Path('plain_magnet_holes_top.png'))

    def test_chamfered_magnet_holes(self):
        vars = self.scad_runner.parameters
        vars["enable_magnet"] = True
        vars["style_hole"] = 0
        vars["chamfer_holes"] = True
        vars["crush_ribs"] = False
        self.scad_runner.camera_arguments = self.scad_runner.camera_arguments.with_rotation(CameraRotations.AngledTop)
        self.scad_runner.create_image([], Path('chamfered_magnet_holes.png'))

    def test_ribbed_magnet_holes(self):
        vars = self.scad_runner.parameters
        vars["enable_magnet"] = True
        vars["style_hole"] = 0
        vars["chamfer_holes"] = False
        vars["crush_ribs"] = True
        self.scad_runner.camera_arguments = self.scad_runner.camera_arguments.with_rotation(CameraRotations.AngledTop)
        self.scad_runner.create_image([], Path('ribbed_magnet_holes.png'))

    def test_chamfered_and_ribbed_magnet_holes(self):
        vars = self.scad_runner.parameters
        vars["enable_magnet"] = True
        vars["style_hole"] = 0
        vars["chamfer_holes"] = True
        vars["crush_ribs"] = True
        self.scad_runner.camera_arguments = self.scad_runner.camera_arguments.with_rotation(CameraRotations.AngledTop)
        self.scad_runner.create_image([], Path('chamfered_and_ribbed_magnet_holes.png'))

    def test_only_countersunk_screw_holes(self):
        vars = self.scad_runner.parameters
        vars["enable_magnet"] = False
        vars["style_hole"] = 1
        self.scad_runner.create_image([], Path('only_countersunk_screw_holes_bottom.png'))
        self.scad_runner.camera_arguments = self.scad_runner.camera_arguments.with_rotation(CameraRotations.AngledTop)
        self.scad_runner.create_image([], Path('only_countersunk_screw_holes_top.png'))

    def test_only_counterbored_screw_holes(self):
        vars = self.scad_runner.parameters
        vars["enable_magnet"] = False
        vars["style_hole"] = 2
        self.scad_runner.create_image([], Path('only_counterbored_screw_holes_bottom.png'))
        self.scad_runner.camera_arguments = self.scad_runner.camera_arguments.with_rotation(CameraRotations.AngledTop)
        self.scad_runner.create_image([], Path('only_counterbored_screw_holes_top.png'))

    def test_magnet_and_countersunk_screw_holes(self):
        vars = self.scad_runner.parameters
        vars["enable_magnet"] = True
        vars["chamfer_holes"] = False
        vars["crush_ribs"] = False
        vars["style_hole"] = 1
        self.scad_runner.create_image([], Path('magnet_and_countersunk_screw_holes_bottom.png'))
        self.scad_runner.camera_arguments = self.scad_runner.camera_arguments.with_rotation(CameraRotations.AngledTop)
        self.scad_runner.create_image([], Path('magnet_and_countersunk_screw_holes_top.png'))

    def test_magnet_and_counterbored_screw_holes(self):
        vars = self.scad_runner.parameters
        vars["enable_magnet"] = True
        vars["chamfer_holes"] = False
        vars["crush_ribs"] = False
        vars["style_hole"] = 2
        self.scad_runner.create_image([], Path('magnet_and_counterbored_screw_holes_bottom.png'))
        self.scad_runner.camera_arguments = self.scad_runner.camera_arguments.with_rotation(CameraRotations.AngledTop)
        self.scad_runner.create_image([], Path('magnet_and_counterbored_screw_holes_top.png'))


if __name__ == '__main__':
    unittest.main()
