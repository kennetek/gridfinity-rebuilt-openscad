"""
Tests for gridfinity-rebuilt-holes.scad
@Copyright Arthur Moore 2024 MIT License
"""

from pathlib import Path
import pytest

from openscad_runner import *

@pytest.fixture
def openscad_runner(pytestconfig) -> OpenScadRunner:
    scad_path = pytestconfig.rootpath.joinpath('src/core/gridfinity-rebuilt-holes.scad')
    scad_runner = OpenScadRunner(scad_path)
    scad_runner.image_folder_base = pytestconfig.rootpath.joinpath('images/hole_cutouts/')
    scad_runner.camera_arguments = CameraArguments(Vec3(0,0,0), CameraRotations.AngledTop, 50)
    return scad_runner

class TestHoleCutouts:
    """
    Test Hole Cutouts.  The negatives used with `difference()` to create a hole.

    Currently only makes sure code runs, and outputs pictures for manual verification.
    """

    def test_refined_hole(self, openscad_runner):
        """
         refined_hole() is special, since top_angle_camera is not appropriate for it.
        """
        openscad_runner.camera_arguments = openscad_runner.camera_arguments.with_rotation(CameraRotations.AngledBottom)
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=true, magnet_hole=false, screw_hole=false, crush_ribs=false, chamfer=false, supportless=false)')
        openscad_runner.create_image(test_args, Path('refined_hole.png'))

    def test_plain_magnet_hole(self, openscad_runner):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=false, crush_ribs=false, chamfer=false, supportless=false)')
        openscad_runner.create_image(test_args, Path('magnet_hole.png'))

    def test_plain_screw_hole(self, openscad_runner):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=false, screw_hole=true, crush_ribs=false, chamfer=false, supportless=false)')
        openscad_runner.create_image(test_args, Path('screw_hole.png'))

    def test_magnet_and_screw_hole(self, openscad_runner):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=true, crush_ribs=false, chamfer=false, supportless=false)')
        openscad_runner.create_image(test_args, Path('magnet_and_screw_hole.png'))

    def test_chamfered_magnet_hole(self, openscad_runner):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=false, crush_ribs=false, chamfer=true, supportless=false)')
        openscad_runner.create_image(test_args, Path('chamfered_magnet_hole.png'))

    def test_magnet_hole_crush_ribs(self, openscad_runner):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=false, crush_ribs=true, chamfer=false, supportless=false)')
        openscad_runner.create_image(test_args, Path('magnet_hole_crush_ribs.png'))

    def test_magnet_hole_supportless(self, openscad_runner):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=false, crush_ribs=false, chamfer=false, supportless=true)')
        openscad_runner.create_image(test_args, Path('magnet_hole_supportless.png'))

    def test_magnet_and_screw_hole_supportless(self, openscad_runner):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=true, crush_ribs=false, chamfer=false, supportless=true)')
        openscad_runner.create_image(test_args, Path('magnet_and_screw_hole_supportless.png'))

    def test_all_hole_options(self, openscad_runner):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=true, crush_ribs=true, chamfer=true, supportless=true)')
        openscad_runner.create_image(test_args, Path('all_hole_options.png'))

    def test_no_hole(self, openscad_runner):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=false, screw_hole=false, crush_ribs=true, chamfer=true, supportless=true)')
        openscad_runner.create_image(test_args, Path('no_hole.png'))
