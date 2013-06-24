# Introduction

As the number of packages written for Julia has increased, it's become clear that we need a standardized mechanism for testing packages to ensure that user-contributed packages function as advertisted.

This document therefore describes a simple standard for writing tests for packages. Any package that obeys this standard can be tested automatically by the package manager without user invention.

This standard was developed to satisfy several desiderata:

* Each set of tests should be a single executable Julia file that loads and uses the package.
* Each set of tests should be independent from all of other sets of tests. In particular, this implies that:
	* It should be possible to execute the tests in any order that the user desires.
	* It should be possible to run any set of tests manually.
	* It should be possible to run all of the tests for a package in a single interpreter session. This makes testing faster by avoiding needless restarts of the Julia interpreter.

# Basic Requirements

As stated above, each test should be an executable Julia file. The test file should load all of the packages that it will need access to, including the package being tested. Importantly, _each test file must be located in the `test` subdirectory of the package's home directory.

For example, we might write a single test for a package called `Demo`. This package's tests will be located in a directory like `~/.julia/Demo/test`. Let's assume that the test file is called `01.jl`, which means that its full path will be `~/.julia/Demo/test/01.jl`.

By itself, `~/.julia/Demo/test/01.jl` should usefully test the `Demo` package. It might therefore look like the following program:

	using Demo
	@assert Demo.returns1() == 1

This is a complete test file. The only problem with this file is that it is written in a global scope that might interfere with other test files. Thus, a clean test file should look like:

	using Demo
	let
		@assert Demo.returns1() == 1
	end

By using `let` blocks, we can ensure that every test can be executed without affecting any of the other files.

We might, for example, have two test files:

* `~/.julia/Demo/test/01.jl`
* `~/.julia/Demo/test/02.jl`

If these files both use `let` blocks, they satisfy the modularity requirements that the package testing standard requires.

With this in mind, the package testing standard's requirements are very simple:

* Each set of tests for a package must be stored in an executable Julia file that lies inside of the `test` subdirectory of the package.
* Each set of tests must load all of the packages that it depends upon for itself.
* Each set of tests must not depend upon or create any global variables that will be shared across files.

If you write tests that satisfy these three requirements, your package can be verified automatically by the package system. By default, the package system will attempt to execute all of the test files stored inside of the `test` directory. If any fails, the package as a whole fails. Otherwise, the package succeeds.

The rest of this document describes a simple mechanism for controlling how the test files are executed.

# Controlling the Execution of Test Files

Sometimes it is helpful to ensure that tests run in a specific order. Although we have insisted that tests should be written so that there are no dependencies across files, it can help to see more basic tests fail before seeing advanced tests fail. In addition, it can be helpful to exclude certain tests that are known to fail without harm to the system.

To allow the user to determine both (a) which test files are executed and (b) which order they were executed, you can create a file inside of the `test` directory called `ACTIVE`. The `ACTIVE` file lists _line-by-line_ the names of every test that you would like to run in the order you would like them to be run. For example, `ACTIVE` might look like,

	02.jl
    01.jl

This file will therefore reverse the default order of execution. In contrast, if `ACTIVE` looked like,

	02.jl

then you would entirely skip the `01.jl` test file during package testing.

# Usage Example

To experiment with this testing standard, you can try out the `PackageTesting` package which implements this standard and also demonstrates its use in a complete package with source code and tests. Install this package in your `.julia` directory and then run the lines:

	using PackageTesting

	PackageTesting.test("PackageTesting")
