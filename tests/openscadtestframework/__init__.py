# __init__.py

__all__ = ["IntegrationTest", "Module",
           "ModuleTest", "Cube", "Square", "OutputType"]
from .tests import IntegrationTest, ModuleTest, OutputType
from .modules import Module, Cube, Square
