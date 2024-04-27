"""
Functions for testing hole cutouts.
@Copyright Arthur Moore 2024 MIT License
"""

from pathlib import Path
from openscad_runner import *
import subprocess
import unittest


class TestHoles(unittest.TestCase):
    """
    Test Hole Cutouts.
    
    Currently only makes sure code runs, and outputs pictures for manual verification.
    """
    scad_file_path = Path('../gridfinity-rebuilt-holes.scad')
    image_folder_base = Path('../images/hole_cutouts/')

    def run_image(self, camera_args: CameraArguments, test_args: [str], image_file_name: str):
        """
        Run the code, to create an image.
        @Important The only verification is that no errors occured.
                   There is no verification if the image was created, or the image contents.
        """
        assert(self.scad_file_path.exists())
        image_path = self.image_folder_base.joinpath(image_file_name)
        command_arguments = [openscad_binary_windows] + common_arguments + \
            [camera_args.as_argument()] + test_args + \
            [f'-o{str(image_path)}', str(self.scad_file_path)]
        print(command_arguments)
        return subprocess.run(command_arguments, check=True)

    def test_refined_hole(self):
        """
            refined_hole() is special, since top_angle_camera is not appropriate for it.
        """
        camera_args = CameraArguments(Vec3(0,0,0),Vec3(225,0,225),50)
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=true, magnet_hole=false, screw_hole=false, crush_ribs=false, chamfer=false, supportless=false)')
        self.run_image(camera_args, test_args, Path('refined_hole.png'))

    def test_plain_magnet_hole(self):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=false, crush_ribs=false, chamfer=false, supportless=false)')
        self.run_image(top_angle_camera, test_args, Path('magnet_hole.png'))

    def test_plain_screw_hole(self):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=false, screw_hole=true, crush_ribs=false, chamfer=false, supportless=false)')
        self.run_image(top_angle_camera, test_args, Path('screw_hole.png'))

    def test_magnet_and_screw_hole(self):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=true, crush_ribs=false, chamfer=false, supportless=false)')
        self.run_image(top_angle_camera, test_args, Path('magnet_and_screw_hole.png'))

    def test_chamfered_magnet_hole(self):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=false, crush_ribs=false, chamfer=true, supportless=false)')
        self.run_image(top_angle_camera, test_args, Path('chamfered_magnet_hole.png'))

    def test_magnet_hole_crush_ribs(self):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=false, crush_ribs=true, chamfer=false, supportless=false)')
        self.run_image(top_angle_camera, test_args, Path('magnet_hole_crush_ribs.png'))

    def test_magnet_hole_supportless(self):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=false, crush_ribs=false, chamfer=false, supportless=true)')
        self.run_image(top_angle_camera, test_args, Path('magnet_hole_supportless.png'))

    def test_magnet_and_screw_hole_supportless(self):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=true, crush_ribs=false, chamfer=false, supportless=true)')
        self.run_image(top_angle_camera, test_args, Path('magnet_and_screw_hole_supportless.png'))

    def test_all_hole_options(self):
        test_args = set_variable_argument('test_options',
            'bundle_hole_options(refined_hole=false, magnet_hole=true, screw_hole=true, crush_ribs=true, chamfer=true, supportless=true)')
        self.run_image(top_angle_camera, test_args, Path('all_hole_options.png'))

if __name__ == '__main__':
    unittest.main()
