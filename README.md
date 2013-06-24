# Introduction

As the number of packages written for Julia has increased, it's become clear that we need a standardized mechanism for testing packages to ensure that user-contributed packages function as advertisted.

This document describes a simple standard for writing tests for packages that I would like to see the Julia community adopt. Any package that obeys this standard can be tested automatically by the package manager without any user intervention.

This standard tries to satisfy the following design requirements:

* Each set of tests should be a single executable Julia file that loads and uses the package.
* Each set of tests should be independent from all other sets of tests. This independence implies that:
	* It should be possible to execute the tests in any order.
	* It should be possible to run any subset of tests manually.
	* It should be possible to run all of the tests for a package in a single interpreter session. This makes testing faster by avoiding needless restarts of the Julia interpreter.

# Basic Requirements

As stated above, each test should be an executable Julia file. The test file should load all of the packages that it will need access to, including the package being tested. Importantly, each test file must be located in the `test` subdirectory of the package's home directory.

For example, we might write a single test for a package called `Demo`. This package's single test will be located in a directory called `~/.julia/Demo/test`. We'll assume that the test file is called `01.jl`: this implies that the test file's full path is `~/.julia/Demo/test/01.jl`.

By itself, `~/.julia/Demo/test/01.jl` should usefully test the `Demo` package. It might therefore look like the following program:

	using Demo
	@assert Demo.returns1() == 1

This is a complete test file. The only problem with this file is that it is written in a global scope that might interfere with other test files if they all share a single interpreter session. Thus, a clean test file should look like:

	using Demo
	let
		@assert Demo.returns1() == 1
	end

By using `let` blocks, we can ensure that every test can be executed without affecting any of the other files.

We might, for example, have two test files:

* `~/.julia/Demo/test/01.jl`
* `~/.julia/Demo/test/02.jl`

If these files both use `let` blocks, they cannot interfere with one another.

If you write tests that are located in the `test` directory and satisfy this independence assumption, your package's functionality can be verified automatically by the testing system outlined in this repo.

By default, the package testing system will attempt to execute all of the test files stored inside of the `test` directory. If any fails, the package as a whole fails. Otherwise, the package succeeds.

The rest of this document describes a simple mechanism for controlling the order in which the test files are executed as well as a mechanism for excluding tests that are known to fail in advance.

# Controlling the Execution of Test Files

Sometimes it is helpful to ensure that tests run in a specific order. Although we have insisted that tests should be written so that there are no dependencies across files, it can help to see more basic tests fail before seeing advanced tests fail. In addition, it can be helpful to exclude certain tests that are known to fail a priori.

To allow the user to determine both (a) which test files are executed and (b) which order they were executed, you can create a file inside of the `test` directory called `ACTIVE`. The `ACTIVE` file lists _line-by-line_ the names of every test file that you would like to run. These files are listed _in the order you would like them to be run_. For example, `ACTIVE` might look like,

	02.jl
    01.jl

This file will therefore reverse the default order of execution. In contrast, if `ACTIVE` looked like,

	02.jl

then the package testing system would entirely skip the `01.jl` test file during package testing.

# Usage Example

To experiment with this testing standard, you can try out the `PackageTesting` package which implements this standard and also demonstrates its use in a complete package with source code and tests. Install this package in your `.julia` directory and then run the lines:

	using PackageTesting

	PackageTesting.test("PackageTesting")

In addition, the DataFrames package now obeys this standard as well:

	using PackageTesting

	PackageTesting.test("DataFrames")
