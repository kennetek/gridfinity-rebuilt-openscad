from typing import Union, List, Optional
from .openscadtestframework import Module


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
