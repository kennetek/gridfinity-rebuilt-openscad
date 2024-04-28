"""
Tests for gridfinity-rebuilt-holes.scad
@Copyright Arthur Moore 2024 MIT License
"""

from pathlib import Path
from openscad_runner import *
import unittest


class TestHoleCutouts(unittest.TestCase):
    """
    Test Hole Cutouts.  The negatives used with `difference()` to create a hole.

    Currently only makes sure code runs, and outputs pictures for manual verification.
    """

    @classmethod
    def setUpClass(cls):
        cls.scad_runner = OpenScadRunner(Path('../gridfinity-rebuilt-holes.scad'))
        cls.scad_runner.image_folder_base = Path('../images/hole_cutouts/')

    def test_refined_hole(self):
        """
            refined_hole() is special, since top_angle_camera is not appropriate for it.
        """
        camera_args = CameraArguments(Vec3(0,0,0),Vec3(225,0,225),50)
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=true, magnet_hole=false, screw_hole=false, crush_ribs=false, chamfer=false, supportless=false)')
        self.scad_runner.create_image(camera_args, test_args, Path('refined_hole.png'))

    def test_plain_magnet_hole(self):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=false, crush_ribs=false, chamfer=false, supportless=false)')
        self.scad_runner.create_image(self.scad_runner.TOP_ANGLE_CAMERA,
            test_args, Path('magnet_hole.png'))

    def test_plain_screw_hole(self):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=false, screw_hole=true, crush_ribs=false, chamfer=false, supportless=false)')
        self.scad_runner.create_image(self.scad_runner.TOP_ANGLE_CAMERA,
            test_args, Path('screw_hole.png'))

    def test_magnet_and_screw_hole(self):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=true, crush_ribs=false, chamfer=false, supportless=false)')
        self.scad_runner.create_image(self.scad_runner.TOP_ANGLE_CAMERA,
            test_args, Path('magnet_and_screw_hole.png'))

    def test_chamfered_magnet_hole(self):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=false, crush_ribs=false, chamfer=true, supportless=false)')
        self.scad_runner.create_image(self.scad_runner.TOP_ANGLE_CAMERA,
            test_args, Path('chamfered_magnet_hole.png'))

    def test_magnet_hole_crush_ribs(self):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=false, crush_ribs=true, chamfer=false, supportless=false)')
        self.scad_runner.create_image(self.scad_runner.TOP_ANGLE_CAMERA,
            test_args, Path('magnet_hole_crush_ribs.png'))

    def test_magnet_hole_supportless(self):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=false, crush_ribs=false, chamfer=false, supportless=true)')
        self.scad_runner.create_image(self.scad_runner.TOP_ANGLE_CAMERA,
            test_args, Path('magnet_hole_supportless.png'))

    def test_magnet_and_screw_hole_supportless(self):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=true, crush_ribs=false, chamfer=false, supportless=true)')
        self.scad_runner.create_image(self.scad_runner.TOP_ANGLE_CAMERA,
            test_args, Path('magnet_and_screw_hole_supportless.png'))

    def test_all_hole_options(self):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=true, crush_ribs=true, chamfer=true, supportless=true)')
        self.scad_runner.create_image(self.scad_runner.TOP_ANGLE_CAMERA,
            test_args, Path('all_hole_options.png'))

    def test_no_hole(self):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=false, screw_hole=false, crush_ribs=true, chamfer=true, supportless=true)')
        self.scad_runner.create_image(self.scad_runner.TOP_ANGLE_CAMERA,
            test_args, Path('no_hole.png'))

if __name__ == '__main__':
    unittest.main()
