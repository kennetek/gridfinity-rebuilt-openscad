from datetime import datetime
import os
import shutil
from subprocess import Popen, PIPE
from unittest import TestCase
import filecmp


class Module():
    """Information container for an openscad module

    Args:
        file_name (str): File which contains the modules' implementation
        name (str): Name of the module
        kwargs (kwargs): arguments for a module in key-value format.
    """
    class Method():
        USE = "use"
        INCLUDE = "include"

    def __init__(self, file_name, name, method=Method.USE, **kwargs):
        self.file_name = file_name
        self.name = name
        self.method = method
        self.args = kwargs


class OpenScadModuleTestRunner(TestCase):
    executable = "openscad"
    cwd = os.getcwd()
    tmp_dir = cwd + "/openscad_test_" + datetime.now().strftime("%d%m%Y_%H%M%S")
    out_file = "out.stl"
    out_file_path = tmp_dir + "/" + out_file
    default_args = " --enable fast-csg -o "
    file_name = "test.scad"

    def __init__(self):
        with Popen(["git", "rev-parse", "--show-toplevel"], stdout=PIPE, stderr=PIPE) as process:
            out, err = process.communicate()
            out = out.decode("utf-8").strip()
            if (out != self.cwd):
                raise OSError(
                    "Should be executed in root dir of git repo.")

        self._create_tmp_dir()

    def __del__(self):
        self._remove_tmp_dir()

    def Run(self, module, expected):
        """Creates a scad file with the nesecary content to run a module stand
            alone, generates a stl file and compares it with an expected stl 
            file

        Args:
            module (Module): Contains information regarding the to be tested
                module. See Module documentation.
            expected (str): File path of the expected stl file.
        """
        file_path = self._create_scadfile(module)
        self._run_scadfile(file_path)
        self._compare_output(expected)

    def _compare_output(self, expected_file_path):
        self.assertTrue(filecmp.cmp(expected_file_path,
                        self.out_file_path, shallow=False))

    def _run_scadfile(self, file_path):
        command = self.executable + self.default_args + \
            self.out_file_path + " " + file_path
        print(f"Run with command: {command}")
        with Popen(command, stdout=PIPE, stderr=PIPE, shell=True) as process:
            ret = process.wait()
            self.assertFalse(ret)

    def _create_scadfile(self, module):
        file_path = self.tmp_dir + "/" + self.file_name
        with open(file_path, "w", encoding="utf8") as infile:
            infile.write(self._create_openscad_string(module))
        return file_path

    def _create_openscad_string(self, module):
        string = module.method + " <" + self.cwd + "/" + module.file_name + ">\n"
        string += module.name + "("
        for key, value in module.args.items():
            string += key + "=" + str(value)
            if key != list(module.args.keys())[-1]:
                string += ","
        string += ");"
        return string

    def _create_tmp_dir(self):
        os.mkdir(self.tmp_dir)

    def _remove_tmp_dir(self):
        shutil.rmtree(self.tmp_dir)


class OpenscadTestCase(TestCase):
    _runner = OpenScadModuleTestRunner()

    def scad_module_test(self, module, expected_file):
        self._runner.Run(module, expected_file)
