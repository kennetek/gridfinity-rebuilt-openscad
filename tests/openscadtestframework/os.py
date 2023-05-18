from __future__ import annotations
from platform import system
from typing import List
from subprocess import Popen, PIPE
from dataclasses import dataclass


class OS():

    @dataclass
    class ExecResult():
        def __init__(self, stdout: str, stderr: str, return_code: int):
            self.stdout: str = stdout
            self.stderr: str = stderr
            self.return_code: int = return_code

    @staticmethod
    def _scad_executable() -> str:
        if system() == "Linux":
            return "openscad"
        if system() == "Windows":
            return r'"C:\Program Files\Openscad\openscad.exe"'
        if system() == "Darwin":
            return r"/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
        raise OSError(f"Unkown OS: {system()}")

    @staticmethod
    def execute_openscad(cmd: List[str]) -> OS.ExecResult:
        return OS._execute_cmd([OS._scad_executable()] + cmd)

    @staticmethod
    def execute_git(cmd: List[str]) -> OS.ExecResult:
        return OS._execute_cmd(["git"] + cmd)

    @staticmethod
    def _execute_cmd(cmd: List[str]) -> OS.ExecResult:
        # Workaround for Windows PermissionError with shell=False
        if system() == "Windows":
            tmp_cmd: str = ""
            for item in cmd:
                tmp_cmd += item + " "
            with Popen(tmp_cmd, stdout=PIPE, stderr=PIPE, shell=True) as process:
                stdout, stderr = process.communicate()
                return OS.ExecResult(stdout.decode("utf-8"), stderr.decode("utf-8"), process.returncode)
        # End workaround
        else:
            with Popen(cmd, stdout=PIPE, stderr=PIPE) as process:
                stdout, stderr = process.communicate()
                return OS.ExecResult(stdout.decode("utf-8"), stderr.decode("utf-8"), process.returncode)
