
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
include("petkovsek.jl")
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
        println("Recurrence extraction: $(time)s")

        cforms, time = @timed closed_forms(loop)
        println("Recurrence solving: $(time)s")
        
        invs, time = @timed invariants(cforms)
        println("Ideal computation: $(time)s")
    end
    println("\nTotal time needed: $(total)s")
    
    return invs
end

end # module
