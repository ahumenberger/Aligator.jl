
module Aligator

export aligator

using PyCall
using SymPy
using Nemo
using Singular
using ContinuedFractions
using Cxx


include("utils.jl")
include("closedform.jl")
include("recurrence.jl")
include("invariants.jl")
include("parse_julia.jl")
include("dependencies.jl")
include("ideals.jl")
include("singular_imap.jl")


function aligator(str::String)
    _, time = @timed begin
        loop, time = @timed extract_loop(str)
        println("Time need for recurrence extraction: $(time)")
        invs = invariants(loop)
    end
    println("\nTotal time needed: $(time)")
    
    return invs
end

end # module
