from __future__ import annotations
import shutil
from pathlib import Path
from typing import Tuple, List, Union, Iterator, Dict, Any, Optional
from re import match, search
from subprocess import Popen, PIPE
from unittest import TestCase
from contextlib import contextmanager
from platform import system
from .mesh import Mesh


def count_curly_brackets_in_string(input_line: str) -> Tuple[int, int]:
    return input_line.count("{"), input_line.count("}")


def to_scad_str(input_str: Any) -> str:
    if isinstance(input_str, bool):
        return str(input_str).lower()
    return str(input_str)


class Module():
    def __init__(self, name: str, content: Optional[List[str]] = None, arguments: Optional[List[str]] = None):
        if content is None:
            content = []
        if arguments is None:
            arguments = []
        self.name = name
        self.content = content
        self.arguments = arguments
        self._call_args: Tuple[Union[str, int, bool, List[int]], ...] = ()
        self._call_kwargs: Dict[str, Union[str, int]] = {}
        self._children: List[Module] = []

    def get_module_string(self) -> str:
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
        return self.get_module_string()

    def add_child(self, child: Module) -> None:
        self._children.append(child)\


    def add_call_args(self, *args: Union[str, int, bool, List[int]], **kwargs: Union[str, int]) -> None:
        self._call_args += args
        self._call_kwargs.update(kwargs)

    def get_call_string(self) -> str:
        out_str = self.name + "("
        for arg in self._call_args:
            out_str += to_scad_str(arg) + ","

        for key, value in self._call_kwargs.items():
            out_str += key + "=" + to_scad_str(value) + ","

        if out_str[-1] == ",":
            out_str = out_str[:-1]

        out_str += ")"

        if self._children:
            out_str += "{\n"
            for child in self._children:
                out_str += child.get_call_string() + "\n"
            out_str += "}"

        out_str += ";"
        return out_str

    @staticmethod
    def from_file(module_name: str, file_name: str) -> Module:
        return ModuleBuilder.from_file(module_name, file_name)


class ModuleBuilder():
    @ staticmethod
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

    @ staticmethod
    def _get_arguments(line: str) -> List[str]:
        result = search(r"\((.*?)\)", line)
        if result:
            arguments = result.group(1).split(",")
            arguments = [x.strip() for x in arguments]
            return arguments
        return []


class ScadTest():

    def __init__(self) -> None:
        pass


class IntegrationTest(ScadTest):
    default_args: List[str] = ["-D$fa=12", "-D$fs=2"]

    def __init__(self, test_file: str) -> None:
        self.test_file = Path(test_file)
        self._kwargs: Dict[str, Union[int, float,  bool]] = {}

    def add_arguments(self, **kwargs: Union[int, float, bool]) -> None:
        self._kwargs.update(kwargs)

    def get_cli_arg_list(self) -> List[str]:
        tmp_list: List[str] = []
        for key, value in self._kwargs.items():
            tmp_list.append("-D" + key + "=" + to_scad_str(value))
        tmp_list += self.default_args
        return tmp_list


class ModuleTest(ScadTest):
    def __init__(self, module_under_test: Module):
        self.module_under_test = module_under_test
        self.dependencies: List[Module] = []
        self.const_files: List[Path] = []

    def add_dependency(self, module: Module) -> None:
        self.dependencies.append(module)

    def add_arguments(self, *args: Union[int, bool, List[int]], **kwargs: Union[str, int]) -> None:
        self.module_under_test.add_call_args(*args, **kwargs)

    def add_children(self, children: List[Module]) -> None:
        for child in children:
            self.module_under_test.add_child(child)

    def add_child(self, child: Module) -> None:
        self.module_under_test.add_child(child)

    def get_test_file_string(self) -> str:
        out_str = ""
        for const_file in self.const_files:
            out_str += "include <" + str(const_file) + ">\n"

        out_str += self._get_call_string() + "\n"
        out_str += self.module_under_test.get_module_string() + "\n"
        for dependency in self.dependencies:
            out_str += dependency.get_module_string() + "\n"

        return out_str

    def add_constants_file(self, const_file: str) -> None:
        full_path = Path.cwd().joinpath(Path(const_file))
        if not full_path.exists():
            raise FileNotFoundError(f"File does not exist {full_path}")
        self.const_files.append(full_path)

    def _get_call_string(self) -> str:
        return self.module_under_test.get_call_string()


class TestRunner():
    out_file_extention = ".stl"
    output_arg: str = "-o"
    expected_dir = Path.cwd().joinpath("tests/expected")
    tmp_dir_prefix = "oscad_generated_test_files."
    git_root_cmd = ["git", "rev-parse", "--show-toplevel"]

    def __init__(self) -> None:
        if (not self._check_if_run_on_root_repo()):
            raise OSError(
                "Should be executed in root dir of git repo.")

        self.tmp_dir: Path = Path()

    def Run(self, test_name: str, test: ScadTest, keep_dir: bool = False) -> None:
        raise NotImplementedError()

    def _check_if_run_on_root_repo(self) -> bool:
        with Popen(self.git_root_cmd, stdout=PIPE, stderr=PIPE) as process:
            out, _ = process.communicate()
            result_path = Path(out.decode("utf-8").strip())
            if result_path == Path.cwd():
                return True
        return False

    def _get_scad_executable(self) -> str:
        if system() == "Linux":
            return "openscad"
        if system() == "Windows":
            return r'"C:\Program Files\Openscad\openscad.exe"'
        if system() == "Darwin":
            return r"/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
        raise OSError(f"Unkown OS: {system()}")

    def _run_openscad_command(self, in_file: Path, out_file: Path, args: Optional[List[str]] = None) -> None:
        if args is None:
            args = []
        cmd = [self._get_scad_executable(), self.output_arg,
               str(out_file), str(in_file)] + args
        with Popen(cmd, stdout=PIPE, stderr=PIPE) as process:
            _, stderr = process.communicate()
            if process.returncode != 0:
                err_mesage = stderr.decode("utf-8")
                raise OSError(
                    f"openscad failed executing with message:\n{err_mesage}")

    def _compare_output(self, expected: Path, current: Path) -> None:
        expected_mesh = Mesh(expected)
        current_mesh = Mesh(current)
        if expected_mesh != current_mesh:
            raise AssertionError("Stl files are not equal")

    @ contextmanager
    def _temp_dir(self, test_name: str, keep_dir: bool = False) -> Iterator[None]:
        self.tmp_dir = Path.cwd().joinpath(Path("oscad_generated_test_files." + test_name))
        if self.tmp_dir.exists():
            shutil.rmtree(self.tmp_dir)
        self.tmp_dir.mkdir()
        yield
        if not keep_dir:
            shutil.rmtree(self.tmp_dir)


class IntegrationTestRunner(TestRunner):
    def __init__(self) -> None:
        super().__init__()
        self.out_file: Path = Path()

    def Run(self, test_name: str, test: ScadTest, keep_dir: bool = False) -> None:
        if not isinstance(test, IntegrationTest):
            raise ValueError("Test should be of type IntegrationTest")
        with self._temp_dir(test_name, keep_dir):
            self.out_file = Path(test_name + self.out_file_extention)
            self._run_openscad_command(
                test.test_file,  self.tmp_dir.joinpath(self.out_file), test.get_cli_arg_list())
            self._compare_output(self.expected_dir.joinpath(
                self.out_file), self.tmp_dir.joinpath(self.out_file))


class ModuleTestRunner(TestRunner):

    test_scad_file: Path = Path("test.scad")

    def __init__(self) -> None:

        super().__init__()

        self.tmp_dir: Path = Path()
        self.out_file: Path = Path()

    def Run(self, test_name: str, test: ScadTest, keep_dir: bool = False) -> None:
        if not isinstance(test, ModuleTest):
            raise ValueError("Test should be of type ModuleTest")

        with self._temp_dir(test_name, keep_dir):
            self.out_file = Path(test_name + self.out_file_extention)
            file_path = self._create_scadfile(test)
            self._run_scadfile(file_path)
            self._compare_output(self.expected_dir.joinpath(
                self.out_file), self.tmp_dir.joinpath(self.out_file))

    def _run_scadfile(self, file_path: Path) -> None:
        self._run_openscad_command(
            file_path, self.tmp_dir.joinpath(self.out_file))

    def _create_scadfile(self, module_test: ModuleTest) -> Path:
        file_path = self.tmp_dir.joinpath(self.test_scad_file)
        with open(file_path, "w", encoding="utf8") as infile:
            infile.write(module_test.get_test_file_string())
        return file_path


class ScadModuleTestCase(TestCase):
    _runner = ModuleTestRunner()

    def scad_module_test(self, module_test: ModuleTest, keep_files: bool = False) -> None:
        self._runner.Run(self.id(), module_test, keep_files)


class ScadIntegrationTestCase(TestCase):
    _runner = IntegrationTestRunner()

    def run_test(self, int_test: IntegrationTest, keep_files: bool = False) -> None:
        self._runner.Run(self.id(), int_test, keep_files)
