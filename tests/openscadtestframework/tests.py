from __future__ import annotations
import shutil
import filecmp
from enum import Enum
from subprocess import Popen, PIPE
from contextlib import contextmanager
from platform import system
from pathlib import Path
from typing import List, Union, Dict, Optional, Iterator
from .modules import Module
from .utils import to_scad_str, scad_executable
from .mesh import Mesh


class OutputType(Enum):
    SVG = 1
    STL = 2


class ScadTest():

    def __init__(self, test_runner: TestRunner) -> None:
        self._runner = test_runner

    def run(self, test_id: str) -> None:
        self._runner.Run(test_id, self)


class IntegrationTest(ScadTest):
    default_args: List[str] = ["-D$fa=12", "-D$fs=2"]

    def __init__(self, test_file: str, out_type: OutputType) -> None:
        super().__init__(IntegrationTestRunner(out_type))
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
    def __init__(self, module_under_test: Module, out_type: OutputType):
        super().__init__(ModuleTestRunner(out_type))
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

    output_arg: str = "-o"
    expected_dir = Path.cwd().joinpath("tests/expected")
    tmp_dir_prefix = "oscad_generated_test_files."
    git_root_cmd = ["git", "rev-parse", "--show-toplevel"]

    def __init__(self, out_type: OutputType) -> None:
        if (not self._check_if_run_on_root_repo()):
            raise OSError(
                "Should be executed in root dir of git repo.")

        if out_type == OutputType.SVG:
            self.out_file_extention = ".svg"
            self._compare_output = self._compare_output_svg
        elif out_type == OutputType.STL:
            self.out_file_extention = ".stl"
            self._compare_output = self._compare_output_stl
        else:
            raise NotImplementedError(
                f"Not implemented runner type {out_type}")

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

    def _run_openscad_command(self, in_file: Path, out_file: Path, args: Optional[List[str]] = None) -> None:
        if args is None:
            args = []
        cmd = [scad_executable(), self.output_arg,
               str(out_file), str(in_file)] + args

        # Workaround for Windows PermissionError with shell=False
        if system() == "Windows":
            tmp_cmd: str = ""
            for item in cmd:
                tmp_cmd += item + " "
            with Popen(tmp_cmd, stdout=PIPE, stderr=PIPE, shell=True) as process:
                _, stderr = process.communicate()
                if process.returncode != 0:
                    err_mesage = stderr.decode("utf-8")
                    raise OSError(
                        f"openscad failed executing with message:\n{err_mesage}")
            return
        # End workaround

        with Popen(cmd, stdout=PIPE, stderr=PIPE) as process:
            _, stderr = process.communicate()
            if process.returncode != 0:
                err_mesage = stderr.decode("utf-8")
                raise OSError(
                    f"openscad failed executing with message:\n{err_mesage}")

    def _compare_output_stl(self, expected: Path, current: Path) -> None:
        expected_mesh = Mesh(expected)
        current_mesh = Mesh(current)
        if expected_mesh != current_mesh:
            raise AssertionError("Stl files are not equal")

    def _compare_output_svg(self, expected: Path, current: Path) -> None:
        if not filecmp.cmp(expected, current, shallow=False):
            raise AssertionError("Svg files are not equal")

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
    def __init__(self, out_type: OutputType) -> None:
        super().__init__(out_type)
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

    def __init__(self, out_type: OutputType) -> None:
        super().__init__(out_type)

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
