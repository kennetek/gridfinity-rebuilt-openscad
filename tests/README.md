# Openscad test framework
The openscad framework will isolate a openscad module by generating a new scad file and copy the to be tested module to that file. The file is rendered with openscad to a stl which is compared with an expected stl.
## How to run tests manualy
### Unit tests
Unittests are designed to be fast(er). These test let you make small changes and check over and over again. Usualy only these test will be used during development and the integration test will be used afterwards as check.
```bash
python -m unittest discover tests/ -p "test_unit*.py"
```
### Integration tests
These tests test the outcome which users of this repo can expect. They usualy take long(er) to run.
```bash
python -m unittest discover tests/ -p "test_int*.py"
```

## Get a expected stl
A passing testcase will clean generated files afterwards. A failing testcase will leave the generated files in a directory. The filenames are generated with the name of the test function. Keep in mind that renaming a test makes it fail automaticaly as the expected file for that test can not be found. 
1. Create test
2. Run Test (it fails)
3. Inspect output file in directory starting with `oscad_generated_test_files` followed by testname
4. copy stl to `tests/expected`
5. Run Test (it should pass)
## How to use the test framework
Lets test the following scad module `module_to_be_tested` witch has a dependecy `module_dependency`.
```openscad
module module_to_be_tested(argument_a, argument_b, argumet_c=42) {
    module_dependency(argument_a, argument_b);
}

module module_dependency(argument_a, argument_b) {
    some_buildin_open_scad_function();
}
```


1. Import some classes from the framework:
```python
from openscadtestframework import ScadTestCase, Module, ModuleTest
```
2. Create a test class with a test case
```python
class openscad_module_test(ScadTestCase):

    def test_case(self):
```
3. Create a module object of the to be tested object from a file:
```python
        module = Module.from_file("module_to_be_tested", "scadfilewithmodule.scad")
```
4. Create a module test.
```python
        module_test = ModuleTest(module)
```
5. If needed, create a dependency module.
    - from file
    ```python
        dep_module = Module.from_file("module_dependency", "scadfilewithmodule.scad")
    ```
    - mock module
    ``` python
        dep_module = Module("module_dependency", 
                    ["module_behavior_line1();", "module_behaviour_line2();"],
                    ["argument_a","argument_b"])
    ```
6. Add dependendy to the module test:
```python
        module_test.add_dependency(dep_module)
```
7. If needed, add file with constants to the module test:
```python
        module_test.add_constants_file("constants.scad")
```
8. Add arguments with which the tested module should be called:
```python
        module_test.add_arguments(argument_a=1, argument_b=2, argument_c=3)
```
9. Run the module test. `keep_files` will not remove any generated test files which can be used for debuging:
```python
        self.scad_module_test(module_test, "expected_stl.stl",keep_files=True)
```
10. The final test file looks like this:
``` python
from openscadtestframework import ScadTestCase, Module, ModuleTest

class openscad_module_test(ScadTestCase):

    def test_case(self):
        module = Module.from_file("module_to_be_tested", "scadfilewithmodule.scad")
        module_test = ModuleTest(module)
        dep_module = Module("module_dependency", 
                    ["module_behavior_line1();", "module_behaviour_line2();"],
                    ["argument_a","argument_b"])
        module_test.add_dependency(dep_module)
        module_test.add_constants_file("constants.scad")
        module_test.add_arguments(argument_a=1, argument_b=2, argument_c=3)
        self.scad_module_test(module_test, "expected_stl.stl")
```