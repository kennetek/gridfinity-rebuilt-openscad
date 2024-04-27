"""
Helpful classes for running OpenScad from Python.
@Copyright Arthur Moore 2024 MIT License
"""

import subprocess
from pathlib import Path
from typing import NamedTuple

class Vec3(NamedTuple):
    '''Simple 3d Vector (x, y, z)'''
    x: float
    y: float
    z: float

class CameraArguments(NamedTuple):
    """
    Controls the camera position when outputting to png format.
    @see `openscad -h`.
    """
    translate: Vec3
    rotate: Vec3
    distance: float

    def as_argument(self):
        return '--camera=' \
        f'{",".join(map(str,self.translate))},{",".join(map(str,self.rotate))},{self.distance}'

def set_variable_argument(var: str, val) -> [str, str]:
    """
    Allows setting a variable to a particular value.
    @warning value **can** be a function, but this is called for every file, so may generate 'undefined' warnings.
    """
    return ['-D', f'{var}={str(val)}']

class OpenScadRunner:
    '''Helper to run the openscad binary'''
    scad_file_path: Path
    openscad_binary_path: Path
    image_folder_base: Path

    WINDOWS_DEFAULT_PATH = 'C:\Program Files\OpenSCAD\openscad.exe'
    TOP_ANGLE_CAMERA = CameraArguments(Vec3(0,0,0),Vec3(45,0,45),50)

    common_arguments = [
        #'--hardwarnings', // Does not work when setting variables by using functions
        '--enable=fast-csg',
        '--enable=predictible-output',
        '--imgsize=1280,720',
        '--view=axes',
        '--projection=ortho',
        ] + \
        set_variable_argument('$fa', 8) + set_variable_argument('$fs', 0.25)

    def __init__(self, file_path: Path):
        self.openscad_binary_path = self.WINDOWS_DEFAULT_PATH
        self.scad_file_path = file_path
        self.image_folder_base = Path('.')

    def create_image(self, camera_args: CameraArguments, args: [str], image_file_name: str):
        """
        Run the code, to create an image.
        @Important The only verification is that no errors occured.
                   There is no verification if the image was created, or the image contents.
        """
        assert(self.scad_file_path.exists())
        assert(self.image_folder_base.exists())

        image_path = self.image_folder_base.joinpath(image_file_name)
        command_arguments = self.common_arguments + \
            [camera_args.as_argument()] + args + \
            [f'-o{str(image_path)}', str(self.scad_file_path)]
        #print(command_arguments)
        return subprocess.run([self.openscad_binary_path]+command_arguments, check=True)
