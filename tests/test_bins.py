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

class TestBinHoles(unittest.TestCase):
    """
    Test how a single base looks with holes cut out.

    Currently only makes sure code runs, and outputs pictures for manual verification.
    """

    @classmethod
    def setUpClass(cls):
        parameter_file_path = Path("gridfinity-rebuilt-bins.json")
        parameter_file_data = ParameterFile.from_json(parameter_file_path.read_text())
        cls.default_parameters = parameter_file_data.parameterSets["Default"]

    def setUp(self):
        self.scad_runner = OpenScadRunner(Path('../gridfinity-rebuilt-bins.scad'))
        self.scad_runner.image_folder_base = Path('../images/base_hole_options/')
        self.scad_runner.parameters = self.default_parameters.copy()
        self.scad_runner.camera_arguments = CameraArguments(Vec3(0,0,0), CameraRotations.AngledBottom, 150)

    def test_no_holes(self):
        vars = self.scad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = False
        vars["screw_holes"] = False
        self.scad_runner.create_image([], Path('no_holes.png'))

    def test_only_corner_holes(self):
        vars = self.scad_runner.parameters
        vars["refined_holes"] = True
        vars["magnet_holes"] = False
        vars["screw_holes"] = False
        vars["only_corners"] = True
        self.scad_runner.create_image([], Path('only_corner_holes.png'))

    def test_refined_holes(self):
        vars = self.scad_runner.parameters
        vars["refined_holes"] = True
        vars["magnet_holes"] = False
        vars["screw_holes"] = False
        self.scad_runner.create_image([], Path('refined_holes.png'))

    def test_refined_and_screw_holes(self):
        vars = self.scad_runner.parameters
        vars["refined_holes"] = True
        vars["magnet_holes"] = False
        vars["screw_holes"] = True
        vars["printable_hole_top"] = False
        self.scad_runner.create_image([], Path('refined_and_screw_holes.png'))

    def test_screw_holes_plain(self):
        vars = self.scad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = False
        vars["screw_holes"] = True
        vars["printable_hole_top"] = False
        self.scad_runner.create_image([], Path('screw_holes_plain.png'))

    def test_screw_holes_printable(self):
        vars = self.scad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = False
        vars["screw_holes"] = True
        vars["printable_hole_top"] = True
        self.scad_runner.create_image([], Path('screw_holes_printable.png'))

    def test_magnet_holes_plain(self):
        vars = self.scad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = True
        vars["screw_holes"] = False
        vars["crush_ribs"] = False
        vars["chamfer_holes"] = False
        vars["printable_hole_top"] = False
        self.scad_runner.create_image([], Path('magnet_holes_plain.png'))

    def test_magnet_holes_chamfered(self):
        vars = self.scad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = True
        vars["screw_holes"] = False
        vars["crush_ribs"] = False
        vars["chamfer_holes"] = True
        vars["printable_hole_top"] = False
        self.scad_runner.create_image([], Path('magnet_holes_chamfered.png'))

    def test_magnet_holes_printable(self):
        vars = self.scad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = True
        vars["screw_holes"] = False
        vars["crush_ribs"] = False
        vars["chamfer_holes"] = False
        vars["printable_hole_top"] = True
        self.scad_runner.create_image([], Path('magnet_holes_printable.png'))

    def test_magnet_holes_with_crush_ribs(self):
        vars = self.scad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = True
        vars["screw_holes"] = False
        vars["crush_ribs"] = True
        vars["chamfer_holes"] = False
        vars["printable_hole_top"] = False
        self.scad_runner.create_image([], Path('magnet_holes_with_crush_ribs.png'))

    def test_magnet_and_screw_holes_plain(self):
        vars = self.scad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = True
        vars["screw_holes"] = True
        vars["crush_ribs"] = False
        vars["chamfer_holes"] = False
        vars["printable_hole_top"] = False
        self.scad_runner.create_image([], Path('magnet_and_screw_holes_plain.png'))

    def test_magnet_and_screw_holes_printable(self):
        vars = self.scad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = True
        vars["screw_holes"] = True
        vars["crush_ribs"] = False
        vars["chamfer_holes"] = False
        vars["printable_hole_top"] = True
        self.scad_runner.create_image([], Path('magnet_and_screw_holes_printable.png'))

    def test_magnet_and_screw_holes_all(self):
        vars = self.scad_runner.parameters
        vars["refined_holes"] = False
        vars["magnet_holes"] = True
        vars["screw_holes"] = True
        vars["crush_ribs"] = True
        vars["chamfer_holes"] = True
        vars["printable_hole_top"] = True
        self.scad_runner.create_image([], Path('magnet_and_screw_holes_all.png'))

if __name__ == '__main__':
    unittest.main()
