using Random
using StatsBase

@isdefined(DiscreteFactor) || include(string(@__DIR__, "/discrete_factor.jl"))
@isdefined(save_to_file)   || include(string(@__DIR__, "/helper.jl"))

"""
	gen_commutative_randpots(rs::Array, comm_indices::Vector{Int}, seed::Int=123)::Vector{Tuple{Vector, Float64}}

Generate random commutative potentials for a given array of ranges.
The second parameter `comm_indices` specifies the indices of the ranges
that should be commutative.
If no indices should be commutative, set `comm_indices` to an empty list.
"""
function gen_commutative_randpots(
	rs::Array,
	comm_indices::Vector{Int},
	seed::Int=123
)::Vector{Tuple{Vector, Float64}}
	@assert all(idx -> 1 <= idx <= length(rs), comm_indices)
	@assert all(idx -> rs[idx] == rs[comm_indices[1]], comm_indices)

	isempty(comm_indices) && return gen_asc_pots(rs)

	Random.seed!(seed)
	length(rs) > 5 && @warn("Generating at least $(2^length(rs)) potentials!")

	com_range = rs[comm_indices[1]]
	non_comm_pos = [idx for idx in 1:length(rs) if !(idx in comm_indices)]
	vals = Dict()
	next_val = 1
	potentials = []
	for conf in Iterators.product(rs...)
		key_parts = Vector{Int}(undef, length(com_range))
		nom_com_vals = [val for (idx, val) in enumerate(conf) if idx in non_comm_pos]
		for (idx, range_val) in enumerate(com_range)
			com_vals = [val for (idx, val) in enumerate(conf) if idx in comm_indices]
			key_parts[idx] = count(x -> x == range_val, com_vals)
		end
		key = string(join(key_parts, "-"), "--", join(nom_com_vals, "-"))
		!haskey(vals, key) && (vals[key] = next_val)
		push!(potentials, ([conf...], vals[key]))
		next_val += 1
	end

	return potentials
end

"""
	gen_asc_pots(rs::Array, start::Int=1)::Vector{Tuple{Vector, Float64}}

Generate ascending potentials for a given array of ranges, starting at `start`.
"""
function gen_asc_pots(rs::Array, start::Int=1)::Vector{Tuple{Vector, Float64}}
	length(rs) > 5 && @warn("Generating at least $(2^length(rs)) potentials!")

	potentials = []
	i = start
	for conf in Iterators.product(rs...)
		push!(potentials, ([conf...], i))
		i += 1
	end

	return potentials
end

### Entry point ###
if abspath(PROGRAM_FILE) == @__FILE__
	Random.seed!(123)
	dir = string(@__DIR__, "/../data/")
	!isdir(dir) && mkdir(dir)
	for n in [2, 4, 6, 8, 10, 12, 14, 16]
		nstr = lpad(n, 2, "0")
		for k in unique([0, 2, floor(log2(n)), floor(n/2), n-1, n])
			k == 1 && continue
			k = Int(floor(k))
			kstr = lpad(k, 2, "0")
			indices = StatsBase.sample(1:n, k, replace=false)
			randvars = [DiscreteRV("R$i") for i in 1:n]
			p = gen_commutative_randpots([range(rv) for rv in randvars], indices)
			f = DiscreteFactor("f", randvars, p)
			res = sort([string("R", i) for i in indices])
			save_to_file(
				(f, string("[", join(res, ","), "]")),
				string(dir, "n=$nstr-k=$kstr.ser")
			)
		end
	end
end