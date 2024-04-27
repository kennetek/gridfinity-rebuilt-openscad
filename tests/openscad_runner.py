"""
Helpful classes for running OpenScad from Python.
@Copyright Arthur Moore 2024 MIT License
"""
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

openscad_binary_windows = 'C:\Program Files\OpenSCAD\openscad.exe'

common_arguments = [
    #'--hardwarnings', // Does not work when setting variables by using functions
    '--enable=fast-csg',
    '--enable=predictible-output',
    '--imgsize=1280,720',
    '--view=axes',
    '--projection=ortho',
    ] + set_variable_argument('$fa', 8) + set_variable_argument('$fs', 0.25)

top_angle_camera = CameraArguments(Vec3(0,0,0),Vec3(45,0,45),50)
