from typing import Union, List
from .openscadtestframework import Module


class Cube(Module):
    def __init__(self, size: Union[int, List[int]] = [1, 1, 1], center: bool = False) -> None:
        super().__init__("cube")
        if isinstance(size, int):
            self.add_call_args(size, center)
        if isinstance(size, list):
            if len(size) != 3:
                raise ValueError("Cube expects linst of 3")
            self.add_call_args(str(size), center)


class Square(Module):
    def __init__(self, size: Union[int, List[int]] = [1, 1], center: bool = False) -> None:
        super().__init__("square")
        if isinstance(size, int):
            self.add_call_args(size, center)
        if isinstance(size, list):
            if len(size) != 2:
                raise ValueError("Cube expects linst of 3")
            self.add_call_args(str(size), center)
