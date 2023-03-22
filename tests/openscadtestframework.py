from __future__ import annotations
import filecmp
import shutil
from pathlib import Path
from typing import Tuple, List, Union, Iterator, Optional, Dict
from re import match, search
from subprocess import Popen, PIPE
from unittest import TestCase
from contextlib import contextmanager
from platform import system
from collections import Counter


def count_curly_brackets_in_string(input_line: str) -> Tuple[int, int]:
    return input_line.count("{"), input_line.count("}")


class Module():
    def __init__(self, name: str, content: List[str], arguments: List[str]):
        self.name = name
        self.content = content
        self.arguments = arguments

    def get_scad_string(self) -> str:
        out_str = "module " + self.name + "("
        for arg in self.arguments:
            out_str = out_str + arg
            if arg != self.arguments[-1]:
                out_str = out_str + ","

        out_str = out_str + ") {\n"

        for content in self.content:
            out_str = out_str + content + "\n"

        out_str = out_str + "}"

        return out_str

    def __str__(self) -> str:
        return self.get_scad_string()

    @staticmethod
    def from_file(module_name: str, file_name: str) -> Module:
        return ModuleBuilder.from_file(module_name, file_name)


class ModuleBuilder():
    @staticmethod
    def from_file(module_name: str, file_name: str) -> Module:
        file_path = Path.cwd().joinpath(Path(file_name))

        module_found: bool = False
        open_brackets_found = 0
        closed_brackets_found = 0

        arguments: List[str] = []
        content: List[str] = []

        with file_path.open(encoding="utf8") as file:
            for line in file:
                if not module_found:
                    if match("module " + module_name + "(.*).*{", line):
                        open_brackets_found = open_brackets_found + 1
                        module_found = True
                        arguments = ModuleBuilder._get_arguments(line)
                else:
                    o_brack, c_brack = count_curly_brackets_in_string(line)
                    open_brackets_found = open_brackets_found + o_brack
                    closed_brackets_found = closed_brackets_found + c_brack
                    if open_brackets_found == closed_brackets_found:
                        break
                    content.append(line.strip("\n"))

        if not module_found:
            raise ValueError(
                f'Module "{module_name}" not found in {file_path}')
        return Module(module_name, content, arguments)

    @staticmethod
    def _get_arguments(line: str) -> List[str]:
        result = search(r"\((.*?)\)", line)
        if result:
            arguments = result.group(1).split(",")
            arguments = [x.strip() for x in arguments]
            return arguments
        return []


class ModuleTest():
    def __init__(self, module_under_test: Module):
        self.module_under_test = module_under_test
        self._args: Tuple[Union[int, bool], ...] = ()
        self._kwargs: Dict[str, Union[str, int]] = {}
        self.dependencies: List[Module] = []
        self.const_files: List[Path] = []

    def add_arguments(self, *args: Union[int, bool], **kwargs: Union[str, int]) -> None:
        self._args = self._args + args
        self._kwargs.update(kwargs)

    def add_dependency(self, module: Module) -> None:
        self.dependencies.append(module)

    def get_test_file_string(self) -> str:
        out_str = ""
        for const_file in self.const_files:
            out_str = out_str + "include <" + str(const_file) + ">\n"

        out_str = out_str + self._get_call_string() + "\n" + \
            self.module_under_test.get_scad_string() + "\n"

        for dependency in self.dependencies:
            out_str = out_str + dependency.get_scad_string() + "\n"

        return out_str

    def add_constants_file(self, const_file: str) -> None:
        full_path = Path.cwd().joinpath(Path(const_file))
        if not full_path.exists():
            raise FileNotFoundError(f"File does not exist {full_path}")
        self.const_files.append(full_path)

    def _get_call_string(self) -> str:
        out_str = self.module_under_test.name + "("
        for arg in self._args:
            out_str = out_str + str(arg) + ","

        for key, value in self._kwargs.items():
            out_str = out_str + key + "=" + str(value) + ","

        if out_str[-1] == ",":
            out_str = out_str[:-1]

        out_str = out_str + ");"
        return out_str


class ModuleTestRunner(TestCase):
    out_file: Path = Path("out.stl")
    default_args: str = " --enable fast-csg -o "
    test_scad_file: Path = Path("test.scad")
    expected_dir = Path.cwd().joinpath("tests/expected")

    def __init__(self) -> None:
        if (not self._check_if_run_on_root_repo()):
            raise OSError(
                "Should be executed in root dir of git repo.")

        super().__init__()

        self.tmp_dir: Path = Path()

    def _scad_executable(self) -> str:
        if system() == "Linux":
            return "openscad"
        if system() == "Windows":
            return r'"C:\Program Files\Openscad\openscad.exe"'
        if system() == "Darwin":
            return r"/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
        raise OSError(f"Unkown OS: {system()}")

    def _check_if_run_on_root_repo(self) -> bool:
        with Popen(["git", "rev-parse", "--show-toplevel"], stdout=PIPE, stderr=PIPE) as process:
            out, _ = process.communicate()
            result_path = Path(out.decode("utf-8").strip())
            if (result_path == Path.cwd()):
                return True
        return False

    def Run(self, test_name: str, module_test: ModuleTest, expected: str, keep_dir: bool = False) -> None:
        """Creates a scad file with the nesecary content to run a module stand
            alone, generates a stl file and compares it with an expected stl
            file

        Args:
            module (ScadModule): Contains information regarding the to be tested
                module. See Module documentation.
            expected (str): File path of the expected stl file.
        """
        with self._temp_dir(test_name, keep_dir):
            file_path = self._create_scadfile(module_test)
            self._run_scadfile(file_path)
            compare_file = self.expected_dir.joinpath(Path(expected))
            if not compare_file.exists():
                raise FileNotFoundError(
                    f"Expected file does noet exist: {compare_file}")
            self._compare_output(self.expected_dir.joinpath(Path(expected)))

    def _compare_output(self, expected_file_path: Path) -> None:
        expected_mesh = Mesh(expected_file_path)
        current_mesh = Mesh(self.tmp_dir.joinpath(self.out_file))
        self.assertEqual(expected_mesh, current_mesh,
                         "Stl files are not equal")

    def _run_scadfile(self, file_path: Path) -> None:
        command = self._scad_executable() + self.default_args + \
            str(self.tmp_dir.joinpath(self.out_file)) + " " + str(file_path)
        with Popen(command, stdout=PIPE, stderr=PIPE, shell=True) as process:
            _, stderr = process.communicate()
            if process.returncode != 0:
                err_mesage = stderr.decode("utf-8")
                raise OSError(
                    f"openscad failed executing with message:\n{err_mesage}")

    def _create_scadfile(self, module_test: ModuleTest) -> Path:
        file_path = self.tmp_dir.joinpath(self.test_scad_file)
        with open(file_path, "w", encoding="utf8") as infile:
            infile.write(module_test.get_test_file_string())
        return file_path

    @ contextmanager
    def _temp_dir(self, test_name: str, keep_dir: bool = False) -> Iterator[None]:
        self.tmp_dir = Path.cwd().joinpath(Path("oscad_generated_test_files." + test_name))
        if self.tmp_dir.exists():
            shutil.rmtree(self.tmp_dir)
        self.tmp_dir.mkdir()
        yield
        if not keep_dir:
            shutil.rmtree(self.tmp_dir)


class ScadTestCase(TestCase):
    _runner = ModuleTestRunner()

    def scad_module_test(self, module_test: ModuleTest, expected_file: str, keep_files: bool = False) -> None:
        self._runner.Run(self.id(), module_test, expected_file, keep_files)


class Mesh():
    def __init__(self, file_name: Path):
        self.solid: Optional[Solid] = None
        tmp_facet: Optional[Facet] = None

        with file_name.open(encoding="utf-8") as input_file:
            for line in input_file:
                if not self.solid and match("solid", line):
                    self.solid = Solid(line.split()[1])
                if self.solid:
                    if not tmp_facet and search("facet normal", line):
                        tmp_facet = Facet(
                            Vector([float(x) for x in line.split()[2:]]))
                    if tmp_facet:
                        if search("vertex", line):
                            tmp_facet.add_vertex(
                                Vector([float(x) for x in line.split()[1:]]))
                        if search("endfacet", line):
                            self.solid.add_facet(tmp_facet)
                            tmp_facet = None

        if not self.solid:
            raise ValueError("Failed to parse file")

    def _parse_solid(self, input: str) -> None:
        pass

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Mesh):
            return NotImplemented
        return self.solid == other.solid


class Vector():
    def __init__(self, numbers: List[float]):
        if len(numbers) != 3:
            raise ValueError("List should exist of 3 numbers")
        self.numbers = numbers

    def __str__(self) -> str:
        return str(self.numbers)

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Vector):
            return NotImplemented
        return self.numbers == other.numbers


class Solid():
    def __init__(self, name: str):
        self.name = name
        self.facets: List[Facet] = []

    def add_facet(self, facet: Facet) -> None:
        self.facets.append(facet)

    def __str__(self) -> str:
        string = self.name + "\n"
        for facet in self.facets:
            string = string + str(facet) + "\n"
        return string

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Solid):
            return NotImplemented
        for facet in self.facets:
            if not facet in other.facets:
                print(f"facet not found: {facet}")
                return False
        return True


class Facet():
    def __init__(self, normal: Vector):
        self.normal = normal
        self.vertices: List[Vector] = []

    def add_vertex(self, vertex: Vector) -> None:
        self.vertices.append(vertex)

    def __str__(self) -> str:
        string = "normal:" + str(self.normal) + "\n"
        for vertex in self.vertices:
            string = string + str(vertex) + "\n"
        return string

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Facet):
            return NotImplemented
        if not self.normal == other.normal:
            return False
        for vertice in self.vertices:
            if not vertice in other.vertices:
                return False
        return True
