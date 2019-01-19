
module Aligator

export aligator, extract_loop, closed_forms, invariants

using PyCall
using SymPy
using Singular
using ContinuedFractions

const AppliedUndef = PyCall.PyNULL()

include("utils.jl")
include("closedform.jl")
include("recurrence.jl")
include("loop.jl")
include("invariants.jl")
include("parse_julia.jl")
include("dependencies.jl")
include("ideals.jl")
include("singular_imap.jl")


function aligator(str::String)
    _, total = @timed begin

        loop, time = @timed extract_loop(str)
        @info "Recurrence extraction" time

        cforms, time = @timed closed_forms(loop)
        @info "Recurrence solving" time
        
        invs, time = @timed invariants(cforms)
        @info "Ideal computation" time
    end
    @info "Total time needed" total
    
    return invs
end

function __init__()
    copy!(AppliedUndef, PyCall.pyimport_conda("sympy.core.function", "sympy")[:AppliedUndef])

    include(joinpath(@__DIR__,"..", "benchmark", "singlepath.jl"))
    include(joinpath(@__DIR__,"..", "benchmark", "multipath.jl"))

    singlepath = [:cohencu, :freire1, :freire2, :(petter(1)), :(petter(2)), :(petter(3)), :(petter(4))]
    multipath = [:divbin, :euclidex, :fermat, :knuth, :lcm, :mannadiv, :wensley]
end

end # module