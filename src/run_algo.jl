using BenchmarkTools

@isdefined(DiscreteFactor)         || include(string(@__DIR__, "/discrete_factor.jl"))
@isdefined(load_from_file)         || include(string(@__DIR__, "/helper.jl"))
@isdefined(commutative_args_naive) || include(string(@__DIR__, "/commutative_args.jl"))

"""
	run_benchmark(file::String, algo::String)

Run the benchmark for a given file and algorithm.
"""
function run_benchmark(file::String, algo::String)
	f, _ = load_from_file(file)
	try
		if algo == "naive"
			fn = commutative_args_naive
		elseif algo == "decor"
			fn = commutative_args_decor
		else
			println("Error: Unknown algorithm '$algo'.")
		end
		result = @benchmark (global res = $fn($f))
		res_str = string("[", join(res, ","), "]")
		print(string(mean(result.times), ";", res_str))
	catch e
		print(string(typeof(e), ": ", e))
	end
end


### Entry point ###
if abspath(PROGRAM_FILE) == @__FILE__
	if length(ARGS) != 2 || !isfile(ARGS[1]) || !(ARGS[2] in ["naive", "decor"])
		@error string(
			"Run this file via 'julia $PROGRAM_FILE <path> <algo>' ",
			"with <path> being the path to a data file on which to run the ",
			"algorithm <algo> (one of 'naive', 'decor')."
		)
		exit()
	end
	run_benchmark(ARGS[1], ARGS[2])
end