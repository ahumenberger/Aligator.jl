
module Aligator

export aligator, extract_loop, closed_forms, invariants

using PyCall
using SymPy
using Nemo
using Singular
using ContinuedFractions
using Cxx


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
        info("Recurrence extraction: $(time)s")

        cforms, time = @timed closed_forms(loop)
        info("Recurrence solving: $(time)s")
        
        invs, time = @timed invariants(cforms)
        info("Ideal computation: $(time)s")
    end
    println("\nTotal time needed: $(total)s")
    
    return invs
end

end # module

include("../benchmark/singlepath.jl")
include("../benchmark/multipath.jl")

singlepath = [:cohencu, :freire1, :freire2, :(petter(1)), :(petter(2)), :(petter(3)), :(petter(4))]
multipath = [:divbin, :euclidex, :fermat, :knuth, :lcm, :mannadiv, :wensley]