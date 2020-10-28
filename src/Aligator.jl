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

aligator(s::String) = aligator(Meta.parse(s))

function aligator(x::Expr)
    _, total = @timed begin
        (init, branches), etime = @timed transform(x)
        init = ValueMap(k=>v for (k,v) in init if v isa Int)
        vars = Base.unique(Iterators.flatten(map(Recurrences.symbols, branches)))
        @debug "Extracting branches" branches vars

        closedforms = extract(branches, init)
        @debug "Recurrence Systems" closedforms

        invs, itime = @timed invariants(closedforms, vars, init)
        @debug "Invariant ideal" invs
    end
    @debug "Time needed" total etime itime

    return InvariantIdeal(invs)
end

struct InvariantIdeal
    ideal::sideal
end

function Base.show(io::IO, I::InvariantIdeal)
    println(io, "Invariant ideal with $(Singular.ngens(I.ideal))-element basis:")
    Base.print_array(io, gens(I.ideal))
end

module Examples
include("../benchmark/singlepath.jl")
include("../benchmark/multipath.jl")
end

struct InvariantIdeal
    ideal::sideal
end

function Base.show(io::IO, I::InvariantIdeal)
    println(io, "Invariant ideal with $(ngens(I.ideal))-element basis:")
    Base.print_array(io, gens(I.ideal))
end

end # module