"""
Helpful classes for running OpenScad from Python.
@Copyright Arthur Moore 2024 MIT License
"""

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

@dataclass
class CameraArguments:
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

class OpenScadRunner:
    '''Helper to run the openscad binary'''
    scad_file_path: Path
    openscad_binary_path: Path
    image_folder_base: Path
    parameters: Optional[dict]
    '''If set, a temporary parameter file is created, and used with these variables'''

    WINDOWS_DEFAULT_PATH = 'C:\\Program Files\\OpenSCAD\\openscad.exe'
    TOP_ANGLE_CAMERA = CameraArguments(Vec3(0,0,0),Vec3(45,0,45),50)

    common_arguments = [
        #'--hardwarnings', // Does not work when setting variables by using functions
        '--enable=fast-csg',
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
        self.parameters = None

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
            ["-o", str(image_path), str(self.scad_file_path)]
        #print(command_arguments)

        if self.parameters != None:
            params = ParameterFile(parameterSets={"python_generated": self.parameters})
            with NamedTemporaryFile(prefix="gridfinity-rebuilt-", suffix=".json", mode='wt',delete_on_close=False) as file:
                json.dump(params, file, sort_keys=True, indent=2, cls=DataClassJSONEncoder)
                file.close()
                command_arguments += ["-p", file.name, "-P", "python_generated"]
                return subprocess.run([self.openscad_binary_path]+command_arguments, check=True)
        else:
            return subprocess.run([self.openscad_binary_path]+command_arguments, check=True)
