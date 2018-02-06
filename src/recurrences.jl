# module Recurrence

using SymPy

const Symbolic = SymPy.Sym

#-------------------------------------------------------------------------------

macro mustimplement(sig)
    fname = sig.args[1]
    arg1 = sig.args[2]
    if isa(arg1,Expr)
        arg1 = arg1.args[1]
    end
    :($(esc(sig)) = error(typeof($(esc(arg1))),
                          " must implement ", $(Expr(:quote,fname))))
end

#-------------------------------------------------------------------------------

abstract type Recurrence end

@mustimplement solve(r::Recurrence)

# @mustimplement lhs(r::Recurrence)
# @mustimplement rhs(r::Recurrence)

# @mustimplement standardform(r::Recurrence)

# @mustimplement order(r::Recurrence)

# @mustimplement hompart(r::Recurrence)
# @mustimplement inhompart(r::Recurrence)


#-------------------------------------------------------------------------------

struct CFiniteRecurrence <: Recurrence
    coeffs::Array{Sym}
    f::SymFunction
    n::Sym
    inhom::Sym
end

#-------------------------------------------------------------------------------

function Base.show(io::IO, r::Recurrence)
    print(io, "$(lhs(r)) = $(rhs(r))")
end

#-------------------------------------------------------------------------------

"Returns the left-hand side of the recurrence equation of `r`."
function lhs(r::Recurrence)
end

"Returns the right-hand side of the recurrence equation of `r`."
function rhs(r::Recurrence)
    if length(r.coeffs) == 1
        return -r.inhom
    end
    simplify(-sum([c * r.f(r.n + (i - 1)) for (i, c) in enumerate(r.coeffs[1:end-1])]) - r.inhom)
end

"Returns the recurrence relation in standard form `rhs - lhs`."
function standardform(r::Recurrence)
    lhs(r) - rhs(r)
end

#-------------------------------------------------------------------------------

function order(r::Recurrence)
end

#-------------------------------------------------------------------------------

"Returns the homogeneous part of `r`."
function hompart(r::Recurrence)
end

"Returns the inhomogeneous part of `r`."
function inhompart(r::Recurrence)
end

#-------------------------------------------------------------------------------

"Shifts `r` by `sh` and returns it."
function shift!(r::Recurrence, sh::Symbolic)
end

"Replaces `r.n` by `s`."
function replace_n(r::Recurrence, s::Symbolic)
end

"Applies substition in `sub` to `r`."
function subs!(r::Recurrence, sub::Pair{Symbolic,Symbolic}, s::Pair{Symbolic,Symbolic}...)
end

#-------------------------------------------------------------------------------

"Returns recurrence dependencies, i.e. `g(n)` for a recurrence `r(n+1) = r(n) + g(n)`."
function deps(r::Recurrence)
end

#-------------------------------------------------------------------------------


# end # module