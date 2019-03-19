
module Aligator

export aligator, extract_loop, closed_forms, invariants

using PyCall
using SymPy
using Singular
using ContinuedFractions
using MacroTools
using Recurrences
using SymEngine

const AppliedUndef = PyCall.PyNULL()

include("utils.jl")
include("closedform.jl")
include("recurrence.jl")
include("loop.jl")
include("invariants.jl")
# include("parse_julia.jl")
include("dependencies.jl")
include("ideals.jl")
include("singular_imap.jl")
include("looptransform.jl")


function aligator(str::String)
    _, total = @timed begin

        loops, time = @timed extract_loops(Meta.parse(str))
        vars = Base.unique(Iterators.flatten(map(Recurrences.free_symbols, loops)))
        @info "Recurrence extraction" time
        @info loops vars

        cforms = map(x -> Recurrences.solve(lrs_sequential(Vector{Expr}(x.args))), loops)
        # cforms, time = @timed closed_forms(loop)
        # @info "Recurrence solving" time
        @info "" cforms
        # @info "" map(polys, cforms)
        invs, time = @timed invariants(cforms, vars)
        @info "" invs
        # @info "Ideal computation" time
    end
    @info "Total time needed" total
    
    # return invs
end

function polys(cs::Vector{T}, vars::Vector{Symbol}) where {T<:Recurrences.ClosedForm}
    ls = Basic[]
    vs = Symbol[]
    for c in cs
        p = c.func - expression(c)
        p = SymEngine.expand(p * denominator(p))
        push!(ls, p)
        push!(vs, Symbol(string(c.func)))
    end
    for v in setdiff(vars, vs)
        push!(ls, :($v - $(Recurrences.initvariable(v, 0))))
    end
    ls
end

function invariants(cs::Vector{Vector{T}}, vars::Vector{Symbol}) where {T<:Recurrences.ClosedForm}
    ps = [polys(c, vars) for c in cs]
end

function __init__()
    copy!(AppliedUndef, PyCall.pyimport_conda("sympy.core.function", "sympy")[:AppliedUndef])

    include(joinpath(@__DIR__,"..", "benchmark", "singlepath.jl"))
    include(joinpath(@__DIR__,"..", "benchmark", "multipath.jl"))

    singlepath = [:cohencu, :freire1, :freire2, :(petter(1)), :(petter(2)), :(petter(3)), :(petter(4))]
    multipath = [:divbin, :euclidex, :fermat, :knuth, :lcm, :mannadiv, :wensley]
end

end # module