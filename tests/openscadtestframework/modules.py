from __future__ import annotations
from pathlib import Path
from typing import Tuple, List, Union, Dict, Optional
from re import match, search
from .utils import to_scad_str, count_curly_brackets_in_string


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
                        open_brackets_found += 1
                        module_found = True
                        arguments = ModuleBuilder._get_arguments(line)
                else:
                    o_brack, c_brack = count_curly_brackets_in_string(line)
                    open_brackets_found += o_brack
                    closed_brackets_found += c_brack
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


class Cube(Module):
    def __init__(self, size: Union[int, Optional[List[int]]] = None, center: bool = False) -> None:
        if size is None:
            size = [1, 1, 1]
        super().__init__("cube")
        if isinstance(size, int):
            self.add_call_args(size, center)
        if isinstance(size, list):
            if len(size) != 3:
                raise ValueError("Cube expects list of 3")
            self.add_call_args(str(size), center)


class Square(Module):
    def __init__(self, size: Union[int, Optional[List[int]]] = None, center: bool = False) -> None:
        if size is None:
            size = [1, 1]
        super().__init__("square")
        if isinstance(size, int):
            self.add_call_args(size, center)
        if isinstance(size, list):
            if len(size) != 2:
                raise ValueError("Square expects list of 2")
            self.add_call_args(str(size), center)
