# __init__.py

__all__ = ["IntegrationTest", "Module",
           "ModuleTest", "Cube", "Square", "OutputType", "OutcomeType"]
from .tests import IntegrationTest, ModuleTest, OutputType, OutcomeType
from .modules import Module, Cube, Square
