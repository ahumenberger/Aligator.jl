module Aligator

export aligator

using MacroTools
using Recurrences
using AlgebraicDependencies
using Singular
using AbstractAlgebra
using Nemo
using SymEngine

include("looptransform.jl")
include("extract.jl")
include("map.jl")
include("invariants.jl")
# include("singular.jl")

aligator(s::String) = aligator(Meta.parse(s))

function aligator(x::Expr)
    _, total = @timed begin
        (init, branches), etime = @timed transform(x)
        vars = Base.unique(Iterators.flatten(map(Recurrences.symbols, branches)))
        @debug "Extracting branches" branches vars

        closedforms = extract(branches, init)
        @debug "Recurrence Systems" closedforms

        invs, itime = @timed invariants(closedforms, vars)
        @debug "Invariant ideal" invs
    end
    @info "Time needed" total etime itime

    return InvariantIdeal(invs)
end

struct InvariantIdeal
    ideal::sideal
end

function Base.show(io::IO, I::InvariantIdeal)
    println(io, "Invariant ideal with $(Singular.ngens(I.ideal))-element basis:")
    Base.print_array(io, gens(I.ideal))
end

function __init__()
    include(joinpath(@__DIR__, "..", "benchmark", "singlepath.jl"))
    include(joinpath(@__DIR__, "..", "benchmark", "multipath.jl"))

    singlepath = [:cohencu, :freire1, :freire2, :(petter(1)), :(petter(2)), :(petter(3)), :(petter(4))]
    multipath = [:divbin, :euclidex, :fermat, :knuth, :lcm, :mannadiv, :wensley]
end

end # module