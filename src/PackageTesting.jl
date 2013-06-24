module PackageTesting
	function test(package_name::String) # Pass in package name
		# Should we load the package here?
		# Or require each test to do the loading for itself?
		# Latter solution makes it possible to run tests in parallel.
		# All tests should be enclosed in begin block to prevent crosstalk.
		startdir = pwd()

		cd(Pkg.dir(package_name))

		if !isdir("test")
			error("Package tests must be located in the test directory")
		end

		filenames = UTF8String[]

		if isfile(joinpath("test", "ACTIVE"))
			io = open(joinpath("test", "ACTIVE"), "r")
			filenames = map(chomp, readlines(io))
			close(io)
		else
			filenames = readdir("test")
		end

		errors = Dict{Any, Any}()

		@printf "Running tests for packaged '%s':\n" package_name
		for filename in filenames
			if ismatch(r"\.jl$", filename)
				try
					include(joinpath("test", filename))
					# TODO: Get print_with_color to work outside of the REPL
					@printf " * PASSED: %s\n" filename
				catch err
					# TODO: Get print_with_color to work outside of the REPL
					@printf " * FAILED: %s\n" filename
					d = get(errors, filename, {})
					push!(d, err)
					errors[filename] = d
				end
			end
		end

		for (filename, error_array) in errors
			@printf STDERR "Errors in file %s:\n" filename
			for err in error_array
				# TODO: Find a better way to print errors.
				print(STDERR, err)
			end
		end

		cd(startdir)
	end
end
