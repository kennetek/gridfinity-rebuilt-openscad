from typing import Tuple, Any
from platform import system


def count_curly_brackets_in_string(input_line: str) -> Tuple[int, int]:
    return input_line.count("{"), input_line.count("}")


def to_scad_str(input_str: Any) -> str:
    if isinstance(input_str, bool):
        return str(input_str).lower()
    return str(input_str)


def scad_executable() -> str:
    if system() == "Linux":
        return "openscad"
    if system() == "Windows":
        return r'"C:\Program Files\Openscad\openscad.exe"'
    if system() == "Darwin":
        return r"/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
    raise OSError(f"Unkown OS: {system()}")
