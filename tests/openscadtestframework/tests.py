from __future__ import annotations
import shutil
import filecmp
from enum import Enum
from pathlib import Path
from typing import List, Union, Dict, Optional
from re import search
from open3d import io, geometry  # type: ignore
from .modules import Module
from .utils import to_scad_str
from .os import OS

EXPECTED_DIR = Path.cwd().joinpath("tests/expected")
TMP_DIR_PREFIX = "oscad_generated_test_files."


class OutputType(Enum):
    SVG = 1
    STL = 2


class ScadTest():

    def __init__(self, test_runner: TestRunner) -> None:
        self._runner = test_runner
        self._result: Union[None, Result, STLResult, SVGResult] = None

    def run(self, test_id: str) -> None:
        try:
            self._result = self._runner.run(test_id, self)
        except:
            self._result = Result(Path())
            self._result.outcome = OutcomeType.NOK
            raise

    def clean_up(self) -> None:
        if not isinstance(self._result, Result):
            raise ValueError(
                "Cleanup called when no result is available. Did the test ran?")

        # Keep files when result is NOK
        if self._result.outcome == OutcomeType.OK:
            self._runner.clean_up()

    @property
    def stl_result(self) -> STLResult:
        if isinstance(self._result, STLResult):
            return self._result
        raise ValueError("No STL result available")

    @property
    def svg_result(self) -> SVGResult:
        if isinstance(self._result, SVGResult):
            return self._result
        raise ValueError("No STL result available")


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
        self._global_variables: Dict[str, Union[int, float]] = {}

    def add_dependency(self, module: Module) -> None:
        self.dependencies.append(module)

    def add_arguments(self, *args: Union[int, bool, List[int]], **kwargs: Union[str, int]) -> None:
        self.module_under_test.add_call_args(*args, **kwargs)

    def add_global_variable(self, name: str, value: Union[int, float]) -> None:
        self._global_variables[name] = value

    def add_children(self, children: List[Module]) -> None:
        for child in children:
            self.module_under_test.add_child(child)

    def add_child(self, child: Module) -> None:
        self.module_under_test.add_child(child)

    def get_test_file_string(self) -> str:
        out_str = ""
        for const_file in self.const_files:
            out_str += "include <" + str(const_file) + ">\n"

        for key, value in self._global_variables.items():
            out_str += "$" + key + "=" + to_scad_str(value) + ";\n"

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
    git_root_cmd = ["rev-parse", "--show-toplevel"]

    def __init__(self, out_type: OutputType) -> None:
        if (not self._check_if_run_on_root_repo()):
            raise OSError(
                "Should be executed in root dir of git repo.")

        self._out_type = out_type
        if self._out_type == OutputType.SVG:
            self.out_file_extention = ".svg"
        elif self._out_type == OutputType.STL:
            self.out_file_extention = ".stl"
        else:
            raise NotImplementedError(
                f"Not implemented output type {self._out_type.name}")

        self.tmp_dir: Path = Path()

    def run(self, test_name: str, test: ScadTest, keep_dir: bool = False) -> Union[None, STLResult, SVGResult]:
        raise NotImplementedError()

    def _check_if_run_on_root_repo(self) -> bool:
        result = OS.execute_git(self.git_root_cmd)
        if Path(result.stdout.strip()) == Path.cwd():
            return True
        return False

    def clean_up(self) -> None:
        self._remove_tmp_dir()

    def _run_openscad_command(self, in_file: Path, out_file: Path, args: Optional[List[str]] = None) -> Union[None, STLResult, SVGResult]:
        if args is None:
            args = []
        cmd = [self.output_arg,
               str(out_file), str(in_file)] + args

        output = OS.execute_openscad(cmd)

        if output.return_code != 0:
            raise OSError(
                f"openscad failed executing with message:\n{output.stderr}")

        if self._out_type == OutputType.STL:
            return STLResult(out_file)
        if self._out_type == OutputType.SVG:
            return SVGResult(out_file)
        raise NotImplementedError(
            f"Not implemented output type {self._out_type.name}")

    def _create_tmp_dir(self, test_name: str) -> None:
        self.tmp_dir = Path.cwd().joinpath(Path(TMP_DIR_PREFIX + test_name))
        if self.tmp_dir.exists():
            self._remove_tmp_dir()
        self.tmp_dir.mkdir()

    def _remove_tmp_dir(self) -> None:
        shutil.rmtree(self.tmp_dir)


class IntegrationTestRunner(TestRunner):
    def __init__(self, out_type: OutputType) -> None:
        super().__init__(out_type)
        self.out_file: Path = Path()

    def run(self, test_name: str, test: ScadTest, keep_dir: bool = False) -> Union[None, STLResult, SVGResult]:
        if not isinstance(test, IntegrationTest):
            raise ValueError("Test should be of type IntegrationTest")

        self._create_tmp_dir(test_name)
        return self._run_openscad_command(
            test.test_file,  self.tmp_dir.joinpath(test_name + self.out_file_extention), test.get_cli_arg_list())


class ModuleTestRunner(TestRunner):

    test_scad_file: Path = Path("test.scad")

    def __init__(self, out_type: OutputType) -> None:
        super().__init__(out_type)

        self.tmp_dir: Path = Path()

    def run(self, test_name: str, test: ScadTest, keep_dir: bool = False) -> Union[None, STLResult, SVGResult]:
        if not isinstance(test, ModuleTest):
            raise ValueError("Test should be of type ModuleTest")

        self._create_tmp_dir(test_name)
        file_path = self._create_scadfile(test)
        return self._run_scadfile(file_path, self.tmp_dir.joinpath(test_name + self.out_file_extention))

    def _run_scadfile(self, file_path: Path, output_path: Path) -> Union[None, STLResult, SVGResult]:
        return self._run_openscad_command(
            file_path, output_path)

    def _create_scadfile(self, module_test: ModuleTest) -> Path:
        file_path = self.tmp_dir.joinpath(self.test_scad_file)
        with open(file_path, "w", encoding="utf8") as infile:
            infile.write(module_test.get_test_file_string())
        return file_path


class OutcomeType(Enum):
    OK = 0
    NOK = 1


class Result():
    def __init__(self, path: Path):
        self.path = path

        self.outcome = OutcomeType.OK

    def compare_with_expected(self, test_id: str) -> None:
        raise NotImplementedError()


class STLResult(Result):
    def __init__(self, path: Path):
        super().__init__(path)
        self.mesh = io.read_triangle_mesh(str(path))

    def compare_with_expected(self, test_id: str) -> None:
        expected_path = EXPECTED_DIR.joinpath(test_id + ".stl")

        mesh_cmp = io.read_triangle_mesh(str(expected_path))

        cloud = geometry.PointCloud()
        cloud.points = self.mesh.vertices
        cloud_cmp = geometry.PointCloud()
        cloud_cmp.points = mesh_cmp.vertices

        cloud_result = cloud.compute_point_cloud_distance(cloud_cmp)

        if not all(i == 0 for i in cloud_result):
            raise AssertionError("STL files are not equal")

    @property
    def total_z(self) -> float:
        return 0

    def total_x(self) -> float:
        return 0

    def total_y(self) -> float:
        return 0


class SVGResult(Result):
    def compare_with_expected(self, test_id: str) -> None:
        expected_path = EXPECTED_DIR.joinpath(test_id + ".svg")
        if not filecmp.cmp(expected_path, self.path, shallow=False):
            self.outcome = OutcomeType.NOK
            raise AssertionError("Svg files are not equal")
