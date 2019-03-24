
module Aligator

export aligator

using MacroTools
using SymEngine
using Recurrences
using AlgebraicDependencies
using Singular

include("singular_imap.jl")
include("looptransform.jl")
include("invs.jl")

function aligator(str::String)
    _, total = @timed begin

        loops, time = @timed extract_loops(Meta.parse(str))
        vars = Base.unique(Iterators.flatten(map(Recurrences.free_symbols, loops)))
        @info "Recurrence extraction" time
        @info loops vars

        cforms = map(x -> Recurrences.solve(lrs_sequential(Vector{Expr}(x.args), :n)), loops)
        # cforms, time = @timed closed_forms(loop)
        # @info "Recurrence solving" time
        @info "" cforms
        # @info "" map(polys, cforms)
        invs, time = @timed invariants(cforms, vars)
        @info "" invs
        # @info "Ideal computation" time
    end
    @info "Total time needed" total
    
    return invs
end

function polys(cs::Vector{T}, vars::Vector{Symbol}) where {T<:Recurrences.ClosedForm}
    ls = Basic[]
    vs = Symbol[]
    exps = Base.unique(Iterators.flatten(map(exponentials, cs)))
    exps = filter(x->x!=1, exps)
    evars = [Basic(Recurrences.gensym_unhashed(:v)) for _ in 1:length(exps)]
    ls= dependencies(exps; variables=evars)
    expmap = Dict(zip(exps, evars))
    @info "" exps
    for c in cs
        exp = exponentials(c)
        exp = [get(expmap, x, x) for x in exp]
        p = c.func - expression(c; expvars = exp)
        p = SymEngine.expand(p * denominator(p))
        push!(ls, p)
        push!(vs, Symbol(string(c.func)))
    end
    for v in setdiff(vars, vs)
        push!(ls, :($v - $(initvar(v))))
    end
    ls, [evars; cs[1].arg]
end

function invariants(cs::Vector{Vector{T}}, vars::Vector{Symbol}) where {T<:Recurrences.ClosedForm}
    ps = Vector{Basic}[]
    as = Basic[]
    for c in cs
        p, auxvars = polys(c, vars)
        @info "" p
        push!(ps, p)
        push!(as, auxvars...)
    end
    invariants(ps, map(Basic, vars), as)
end

function __init__()
    include(joinpath(@__DIR__,"..", "benchmark", "singlepath.jl"))
    include(joinpath(@__DIR__,"..", "benchmark", "multipath.jl"))

    singlepath = [:cohencu, :freire1, :freire2, :(petter(1)), :(petter(2)), :(petter(3)), :(petter(4))]
    multipath = [:divbin, :euclidex, :fermat, :knuth, :lcm, :mannadiv, :wensley]
end

end # module