import os
import shutil
import filecmp
from datetime import datetime
from subprocess import Popen, PIPE
from unittest import TestCase
from pathlib import Path
from typing import Union, Dict


class ScadModule():
    """Information container for an openscad module

    Args:
        file_name (str): File which contains the modules' implementation
        name (str): Name of the module
        kwargs (kwargs): arguments for a module in key-value format.
    """
    class Method():
        USE: str = "use"
        INCLUDE: str = "include"

    def __init__(self, file_name: Path, name: str, method: str = Method.USE, **kwargs: Union[str, int]):
        self.file_name: Path = file_name
        self.name: str = name
        self.method: str = method
        self.args: Dict[str, Union[str, int]] = kwargs


class OpenScadModuleTestRunner(TestCase):
    executable: str = "openscad"
    cwd: Path = Path.cwd()
    tmp_dir: Path = cwd.joinpath(
        Path("openscad_test_" + datetime.now().strftime("%d%m%Y_%H%M%S")))
    out_file: Path = Path("out.stl")
    out_file_path: Path = tmp_dir.joinpath(out_file)
    default_args: str = " --enable fast-csg -o "
    file_name: Path = Path("test.scad")

    def __init__(self) -> None:
        with Popen(["git", "rev-parse", "--show-toplevel"], stdout=PIPE, stderr=PIPE) as process:
            out, _ = process.communicate()
            result_path = Path(out.decode("utf-8").strip())
            if (result_path != self.cwd):
                raise OSError(
                    "Should be executed in root dir of git repo.")

        super().__init__()

        self._create_tmp_dir()

    def __del__(self) -> None:
        self._remove_tmp_dir()

    def Run(self, module: ScadModule, expected: Path) -> None:
        """Creates a scad file with the nesecary content to run a module stand
            alone, generates a stl file and compares it with an expected stl
            file

        Args:
            module (ScadModule): Contains information regarding the to be tested
                module. See Module documentation.
            expected (str): File path of the expected stl file.
        """
        file_path = self._create_scadfile(module)
        self._run_scadfile(file_path)
        self._compare_output(expected)

    def _compare_output(self, expected_file_path: Path) -> None:
        self.assertTrue(filecmp.cmp(expected_file_path,
                        self.out_file_path, shallow=False))

    def _run_scadfile(self, file_path: Path) -> None:
        command = self.executable + self.default_args + \
            str(self.out_file_path) + " " + str(file_path)
        print(f"Run with command: {command}")
        with Popen(command, stdout=PIPE, stderr=PIPE, shell=True) as process:
            ret = process.wait()
            self.assertFalse(ret)

    def _create_scadfile(self, module: ScadModule) -> Path:
        file_path = self.tmp_dir.joinpath(self.file_name)
        with open(file_path, "w", encoding="utf8") as infile:
            infile.write(self._create_openscad_string(module))
        return file_path

    def _create_openscad_string(self, module: ScadModule) -> str:
        string = module.method + " <" + \
            str(self.cwd.joinpath(module.file_name)) + ">\n"
        string += module.name + "("
        for key, value in module.args.items():
            string += key + "=" + str(value)
            if key != list(module.args.keys())[-1]:
                string += ","
        string += ");"
        return string

    def _create_tmp_dir(self) -> None:
        os.mkdir(self.tmp_dir)

    def _remove_tmp_dir(self) -> None:
        shutil.rmtree(self.tmp_dir)


class OpenscadTestCase(TestCase):
    _runner = OpenScadModuleTestRunner()

    def scad_module_test(self, module: ScadModule, expected_file: Path) -> None:
        self._runner.Run(module, expected_file)
