

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


function aligator(str::String)
    loop = extract_loop(str)
    invs = invariants(loop)
    return invs
end

end # module

#-------------------------------------------------------------------------------

module Examples

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

euclidex = """
    while a != b
        if a > b
            a = a - b
            p = p - q
            r = r - s
        else
            q = q - p
            b = b - a
            s = s - r
        end
    end
"""

fermat = """
    while r != 0
        if r > 0
            r = r - v
            v = v + 2
        else
            r = r + u
            u = u + 2
        end
    end
"""

notfermat = """
    while r != 0
            r = r - v
            v = v + 2
    end
"""

loop4 = """
    while a != b
        if a > b
            a = a - b
            p = p - q
            r = r - s
        end
    end
"""

wensley = """
    while d>= E
	    if P < a+b
            b = b/2
            d = d/2
        else
            a = a+b
            y = y+d/2
            b = b/2
            d = d/2
        end
    end
"""

exlcm = """
    while x != y
        if x > y
            x = x - y
            v = v + u
        else
            y = y - x
            u = u + v
        end
    end
"""

knuth = """
    while (s >= d) && (r != 0)
        if 2*r-rp+q < 0
        t  = r
        r  = 2*r-rp+q+d+2
        rp = t
        q  = q+4
        d  = d+2
        elseif (2*r-rp+q >= 0) && (2*r-rp+q < d+2)
        t  = r
        r  = 2*r-rp+q
        rp = t
        d  = d+2
        elseif (2*r-rp+q >= 0) && (2*r-rp+q >= d+2) && (2*r-rp+q < 2*d+4)
        t  = r
        r  = 2*r-rp+q-d-2
        rp = t
        q  = q-4
        d  = d+2
        else # ((2*r-rp+q >= 0) && (2*r-rp+q >= 2*d+4))
        t  = r
        r  = 2*r-rp+q-2*d-4
        rp = t
        q  = q-8
        d  = d+2
        end
    end
"""

end # module
