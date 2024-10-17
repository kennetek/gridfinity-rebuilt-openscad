"""
Helpful classes for running OpenScad from Python.
@Copyright Arthur Moore 2024 MIT License
"""
from __future__ import annotations

import json
import subprocess
from dataclasses import dataclass, is_dataclass, asdict
from pathlib import Path
from tempfile import NamedTemporaryFile
from typing import NamedTuple, Optional

class DataClassJSONEncoder(json.JSONEncoder):
    '''Allow json serialization'''
    def default(self, o):
        if is_dataclass(o):
            return asdict(o)
        # Let the base class default method raise the TypeError
        return super().default(o)

class Vec3(NamedTuple):
    '''Simple 3d Vector (x, y, z)'''
    x: float
    y: float
    z: float

@dataclass(frozen=True)
class CameraArguments:
    """
    Controls the camera position when outputting to png format.
    @see `openscad -h`.
    Supports fluid interface.
    """
    translate: Vec3
    rotate: Vec3
    distance: float

    def with_translation(self, new_translate: Vec3) -> CameraArguments:
        return CameraArguments(translate=new_translate, rotate=self.rotate, distance=self.distance)

    def with_rotation(self, new_rotate: Vec3) -> CameraArguments:
        return CameraArguments(translate=self.translate, rotate=new_rotate, distance=self.distance)

    def with_distance(self, new_distance: float) -> CameraArguments:
        return CameraArguments(translate=self.translate, rotate=rotate, distance=new_distance)

    def as_argument(self) -> str:
        return '--camera=' \
        f'{",".join(map(str,self.translate))},{",".join(map(str,self.rotate))},{self.distance}'

@dataclass(kw_only=True, frozen=True)
class ParameterFile:
    parameterSets: dict[str, dict]
    fileFormatVersion: int = 1

    @classmethod
    def from_json(cls, *pargs, **nargs):
        """
        Wrapper for `json.loads`, with some post-processing.
        The Customizer saves everything as strings. --Arthur 2024-04-28
        """
        nargs["object_pairs_hook"] = cls.object_pairs_hook
        file = ParameterFile(**json.loads(*pargs, **nargs))
        assert(file.fileFormatVersion == 1)
        return file

    @classmethod
    def object_pairs_hook(self, pairs: list[tuple]):
        '''Fixes customizer turning everything into strings'''
        output = dict(pairs)
        for (key, value) in output.items():
            if(type(value) == str):
                if(value == "true"):
                    output[key] = True
                    continue
                if(value == "false"):
                    output[key] = False
                    continue
                try:
                    output[key] = float(value)
                except ValueError:
                    pass
        return output

def set_variable_argument(var: str, val: str) -> [str, str]:
    """
    Allows setting a variable to a particular value.
    @warning value **can** be a function, but this is called for every file, so may generate 'undefined' warnings.
    """
    return ['-D', f'{var}={str(val)}']

class CameraRotations:
    '''Pre-defined useful camera rotations'''
    Default = Vec3(0,0,0),
    AngledTop = Vec3(45,0,45)
    AngledBottom = Vec3(225,0,225)
    Top = Vec3(45,0,0)

class OpenScadRunner:
    '''Helper to run the openscad binary'''
    scad_file_path: Path
    openscad_binary_path: Path
    image_folder_base: Path
    parameters: Optional[dict]
    '''If set, a temporary parameter file is created, and used with these variables'''

    WINDOWS_DEFAULT_PATH = 'C:\\Program Files\\OpenSCAD\\openscad.exe'
    TOP_ANGLE_CAMERA = CameraArguments(Vec3(0,0,0),Vec3(45,0,45),150)

    common_arguments = [
        #'--hardwarnings', # Does not work when setting variables by using functions
        '--enable=predictible-output',
        '--imgsize=1280,720',
        '--view=axes',
        '--projection=ortho',
        #"--summary", "all",
        #"--summary-file", "-"
        ] + \
        set_variable_argument('$fa', 8) + set_variable_argument('$fs', 0.25)

    def __init__(self, file_path: Path):
        self.openscad_binary_path = self.WINDOWS_DEFAULT_PATH
        self.scad_file_path = file_path
        self.image_folder_base = Path('.')
        self.camera_arguments = None
        self.parameters = None

    def create_image(self, args: [str], image_file_name: str) -> subprocess.CompletedProcess:
        """
        Run the code and create an image.
        @Important The only verification is that no errors occured.
                   There is no verification if the image was created, or the image contents.
        """
        assert(self.scad_file_path.exists())
        assert(self.image_folder_base.exists())

        image_path = self.image_folder_base.joinpath(image_file_name)
        command_arguments = self.common_arguments + \
            ([self.camera_arguments.as_argument()] if self.camera_arguments != None else []) + \
            args + \
            ["-o", str(image_path), str(self.scad_file_path)]
        #print(command_arguments)

        if self.parameters != None:
            #print(self.parameters)
            params = ParameterFile(parameterSets={"python_generated": self.parameters})
            with NamedTemporaryFile(prefix="gridfinity-rebuilt-", suffix=".json", mode='wt',delete_on_close=False) as file:
                json.dump(params, file, sort_keys=True, indent=2, cls=DataClassJSONEncoder)
                file.close()
                command_arguments += ["-p", file.name, "-P", "python_generated"]
                return self._run(command_arguments)
        else:
            return self._run(command_arguments)

    def _run(self, args: [str]) -> subprocess.CompletedProcess:
        """
        Run openscad with the passed in arguments.
        """
        output = subprocess.run([self.openscad_binary_path]+args, capture_output=True)
        error_strings = output.stderr.decode().strip().splitlines()
        if any(line.startswith("ERROR:") for line in error_strings):
            # OpenSCAD doesn't set an error return if it errors from bad SCAD code!
            output.returncode = 11
        output.check_returncode()
        return output
