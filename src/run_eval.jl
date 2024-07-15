@isdefined(DiscreteFactor)  || include(string(@__DIR__, "/discrete_factor.jl"))
@isdefined(nanos_to_millis) || include(string(@__DIR__, "/helper.jl"))

"""
	run_eval(dir=string(@__DIR__, "/../data/"), outdir=string(@__DIR__, "/../results/"))

Run the experiments.
"""
function run_eval(
	dir=string(@__DIR__, "/../data/"),
	outdir=string(@__DIR__, "/../results/")
)
	!isdir(outdir) && mkdir(outdir)
	outfile = string(outdir, "results.csv")
	outfile_exists = isfile(outfile)

	open(outfile, "a") do io
		!outfile_exists && write(io, "instance,n,k,algo,time,correct_result\n")
		for (root, dirs, files) in walkdir(dir)
			for f in files
				(!occursin(".DS_Store", f) && !occursin("README", f) &&
					!occursin(".gitkeep", f)) || continue

				fpath = string(root, endswith(root, "/") ? "" : "/", f)
				f_short = replace(f, ".ser" => "")
				_, check_res = load_from_file(fpath)

				@info "=> Processing file '$fpath'..."
				cmds = Dict(
					"naive" => `julia run_algo.jl $fpath naive`,
					"decor" => `julia run_algo.jl $fpath decor`,
				)
				for (algo, cmd) in cmds
					@info "Running algorithm '$algo'..."
					res = run_with_timeout(cmd)
					if !verify_result(res, check_res)
						estr = string(
							"Algo '$algo' returned wrong result for '$fpath':\n",
							"Expected: $check_res\n",
							"Actual: $(split(res, ";")[2])"
						)
						@error estr
					end
					write(io, join([
						f_short,
						parse(Int, match(r"n=(\d+)", f)[1]),
						parse(Int, match(r"k=(\d+)", f)[1]),
						algo,
						convert_result(res),
						check_res
					], ","), "\n")
					flush(io)
				end
			end
		end
	end
end

"""
	run_with_timeout(command, timeout::Int = 300)

Run an external command with a timeout. If the command does not finish within
the specified timeout, the process is killed and `timeout` is returned.
"""
function run_with_timeout(command, timeout::Int = 300)
	out, err = Pipe(), Pipe()
	cmd = run(pipeline(command, stdout=out, stderr=err); wait=false)
	close(out.in)
	close(err.in)
	for _ in 1:timeout
		if !process_running(cmd)
			stdout_content = read(out, String)
			stderr_content = read(err, String)
			return string(stdout_content, stderr_content)
		end
		sleep(1)
	end
	kill(cmd)
	return "timeout"
end

"""
	verify_result(res::String, check_res::String)::Bool

Verify the result of the algorithm. The result is correct if it is equal to
the expected result `check_res`.
The expected format of `res` is `time;output` where `time` is the execution
time in nanoseconds and `output` is a list of commutative arguments.
"""
function verify_result(res::String, check_res::String)::Bool
	@debug "Verify result: '$res'"
	if contains(lowercase(res), "error")
		@error "Error during execution: $res"
		return false
	elseif contains(res, "timeout")
		return true # No verification possible
	else
		res = split(res, ";")[2]
		res = replace(res, "[" => "", "]" => "")
		check_res = replace(check_res, "[" => "", "]" => "")
		return sort(split(res, ",")) == sort(split(check_res, ","))
	end
end

"""
	convert_result(res::String)::String

Convert the result into a measurement that can be used for the evaluation.
	The expected format of `res` is `time;output` where `time` is the execution
	time in nanoseconds and `output` is a list of commutative arguments.
The returned value is a number (as a string) specifying the runtime in
milliseconds.
"""
function convert_result(res::String)::String
	contains(res, "timeout") && return "timeout"
	return string(nanos_to_millis(parse(Float64, split(res, ";")[1])))
end


### Entry point ###
if abspath(PROGRAM_FILE) == @__FILE__
	run_eval()
end