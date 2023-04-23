from __future__ import annotations
from pathlib import Path
from typing import Optional, List
from re import match, search


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
        if len(self.facets) != len(other.facets):
            return False
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
