module Recurrences

using SymPy
using PyCall

import Base.==
import SymPy.simplify

include("utils.jl")


export CFiniteRecurrence
export order, lhs, rhs, standardform
export normalize!, shift!, replace_n!

export RecSystem
export solve, simplify

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

mutable struct CFiniteRecurrence <: Recurrence
    coeffs::Array{Sym}
    f::SymFunction
    n::Sym
    inhom::Sym
    minarg::Sym
end

function CFiniteRecurrence(eq::Sym, fn::SymFunction, lc::Sym)
    fns = symfunctions(eq)
    w0 = Wild("w0")
    args = [get(match(fn(lc + w0), f), w0, nothing) for f in fns]
    args = filter(x -> x!=nothing, args)
    minarg = Int(minimum(args))
    maxarg = Int(maximum(args))
    coeffs = Sym[]
    for i in minarg:maxarg
        c, eq = coeff_rem(eq, fn(lc + i))
        coeffs = [coeffs; c]
    end
    return CFiniteRecurrence(coeffs, fn, lc, eq, minarg)
end

#-------------------------------------------------------------------------------

function Base.show(io::IO, r::Recurrence)
    print(io, "$(lhs(r)) = $(rhs(r))")
end

#-------------------------------------------------------------------------------

"Returns the left-hand side of the recurrence equation of `r`."
lhs(r::Recurrence) = r.f(r.n + order(r) + r.minarg)

"Returns the right-hand side of the recurrence equation of `r`."
function rhs(r::Recurrence)
    if length(r.coeffs) == 1
        return -r.inhom
    end
    basearg = r.n + r.minarg
    simplify(-sum([c * r.f(basearg + (i - 1)) for (i, c) in enumerate(r.coeffs[1:end-1])]) - r.inhom)
end

"Returns the recurrence relation in standard form `rhs - lhs`."
standardform(r::Recurrence) = lhs(r) - rhs(r)

#-------------------------------------------------------------------------------

order(r::Recurrence) = length(r.coeffs) - 1

"Checks whether `r` is an actual recurrence, i.e. if there is more than one occurrence of `r.f`."
isrecurrence(r::Recurrence) = length(r.coeffs) > 1

#-------------------------------------------------------------------------------

"Returns the homogeneous part of `r`."
hompart(r::Recurrence) = sum([c * r.f(r.n + r.minarg + (i - 1)) for (i, c) in enumerate(r.coeffs)])

"Returns the inhomogeneous part of `r`."
inhompart(r::Recurrence) = r.inhom

#-------------------------------------------------------------------------------

"Shifts `r` by `sh`."
function shift!(r::Recurrence, sh::Symbolic)
    r.minarg += sh
    r.coeffs = [c |> subs(r.n, r.n + sh) for c in r.coeffs]
    r.inhom = r.inhom |> subs(r.n, r.n + sh)
    r
end

"Replaces `r.n` by `s` on the right-hand side and returns it."
function replace_n(r::Recurrence, s::Symbolic)
    res = 0
    for (i, c) in enumerate(r.coeffs)
        res += (c |> subs(r.n, s)) * r.f(s + r.minarg + (i - 1))
    end
    res += r.inhom |> subs(r.n, s)
end

function rhs(r::Recurrence, arg::Symbolic)
    carg = r.n + r.minarg + order(r)
    shift = arg - carg
    rhs(r) |> subs(r.n, r.n + shift)
end

# "Applies substition in `sub` to `r`. For replacing `r.n` use method `replace_n`."
# function subs(r::CFiniteRecurrence, sub::Pair{Symbolic,Symbolic}...)
#     rec = standardform(r) |> SymPy.subs(sub...)
#     CFiniteRecurrence(rec, r.f, r.n)
# end

function subs!(r::Recurrence, s::Recurrence)
    # Assume other recurrences do only appear in inhom part.
    r.inhom = subs!(r.inhom, s)
    r
end

function subs!(expr::Symbolic, s::Recurrence)
    fns = [fn for fn in symfunctions(expr) if symfunc(fn) == s.f]
    for fn in fns
        expr = expr |> subs(fn, rhs(s, symarg(fn)))
    end
    expr
end

"Shifts `r` such that the lowest occurring argument is `n+0`."
normalize!(r::Recurrence) = shift!(r, -r.minarg)

#-------------------------------------------------------------------------------

"Returns recurrence dependencies, i.e. `g(n)` for a recurrence `r(n+1) = r(n) + g(n)`."
function deps(r::Recurrence)
    fns = [fn for fn in symfunctions(rhs(r)) if symfunc(fn) != r.f]
end

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

const RecSystem = Array{<:Recurrence,1}

function solve(sys::RecSystem)
end

function simplify(sys::RecSystem)
    varlist = [(r.f(r.n), r.f) for r in sys]
    _simplify(Recurrence[], varlist, sys...)
end

function _simplify(processed::RecSystem, varlist::Array{Tuple{Sym,SymFunction},1}, rec::Recurrence, recs::Recurrence...)
    if !isrecurrence(rec)
        varlist = [_simplify(var, rec) for var in varlist]
        processed = [subs!(r, rec) for r in processed]
        recs = [subs!(r, rec) for r in recs]
    else
        push!(processed, rec)
    end
    _simplify(processed, varlist, recs...)
end

function _simplify(processed::RecSystem, varlist::Array{Tuple{Sym,SymFunction},1})
    processed, varlist
end

_simplify(var::Tuple{Sym,SymFunction}, rec::Recurrence) = subs!(var[1], rec), var[2]

end # module

using SymPy;
using Recurrences;
# r = SymFunction("R"); 
# g = SymFunction("G"); 
# n = Sym("n"); 
# ex1 = r(n+Sym(2)) + 2*r(n+Sym(1)) + 4*r(n)
# ex2 = r(n+1) + 2*r(n) + 4*r(n-1) + 5*g(n)
# rec1 = Recurrences.CFiniteRecurrence(ex1, r, n)
# rec2 = Recurrences.CFiniteRecurrence(ex2, r, n)


t, r, rp, q, d = SymFunction("t,r,rp,q,d")
n = Sym("n"); 

r1 = CFiniteRecurrence(t(n+1) - r(n), t, n)
r2 = CFiniteRecurrence(r(n+1) - 2*r(n) + rp(n) - q(n) - d(n) - 2, r, n)
r3 = CFiniteRecurrence(rp(n+1) - t(n+1), rp, n)
r4 = CFiniteRecurrence(q(n+1) - q(n) - 4, q, n)
r5 = CFiniteRecurrence(d(n+1) - d(n) - 2, d, n)

recsys = RecSystem([r1, r2, r3, r4, r5])

# function get_func(ex::FunctionSymbol)
#     args = CVecBasic()
#     ccall((:basic_get_args, libsymengine), Void, (Ptr{Basic}, Ptr{Void}), &ex, args.ptr)
#     convert(Vector, args)
# end