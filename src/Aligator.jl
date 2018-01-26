

module Aligator

export aligator

using PyCall
using SymPy
using Nemo
using Singular
using ContinuedFractions
using Cxx

include("utils.jl")
include("recurrence.jl")
include("invariants.jl")
include("parse_julia.jl")
include("dependencies.jl")
include("ideals.jl")
include("singular_imap.jl")

#-------------------------------------------------------------------------------

function aligator(str::String)
    loop = extract_loop(str)
    invs = invariants(loop)
    return invs
end

#-------------------------------------------------------------------------------

loop = """
    while true
        if y > 1
            x = x + 1
            y = y - 1
            z = 1
            a = b
        elseif t > 1
            x1 = x1 + 1
            y1 = y1 - 1
            z1 = 1
            a1 = b1
        else
            abc = a2
        end
    end
"""

loop2 = """
    while true
        x = 1/2*x + 1
        y = y - 1
        z = 1
        a = b
    end
"""

loop3 = """
    while true
        x = 1/2*x
        y = 2y
    end
"""

aligator(loop3)

# package code goes here

end # module
