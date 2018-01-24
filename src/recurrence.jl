
import Base.show
import SymPy.solve
import SymPy.coeff
import SymPy.degree

abstract type Recurrence end

struct CFiniteRecurrence <: Recurrence
    coeffs::Array{Sym}
    f::SymFunction
    n::Sym
    inhom::Sym
end

CFiniteRecurrence(coeffs::Array{Sym}, f::SymFunction, n::Sym) = CFiniteRecurrence(coeffs, f, n, Sym(0))
CFiniteRecurrence(coeffs::Array{Sym}, f::SymFunction, n::Symbol) = CFiniteRecurrence(coeffs, f, Sym(n))

abstract type ClosedForm end

mutable struct CFiniteClosedForm <: ClosedForm
    f::SymFunction
    n::Sym
    exp::Array{Sym}
    coeff::Array{Sym}
    expvars::Array{Sym}
end

CFiniteClosedForm(f::SymFunction, n::Sym, exp::Array{Sym}, coeff::Array{Sym}) = CFiniteClosedForm(f, n, exp, coeff, [])

function poly(cf::CFiniteClosedForm)
    return sum([ex^cf.n * c for (ex, c) in zip(cf.exp, cf.coeff)])
end

function Base.show(io::IO, cf::CFiniteClosedForm)
    print(io, cf.f(cf.n), " Exp: $(cf.exp) Coeff: $(cf.coeff)\n", sympy["pretty"](poly(cf)))
end

struct HyperClosedForm <: ClosedForm
    exp::Array{Sym} # TODO: do exponentials contain loop counter?
    fact::Array{Sym}
    coeff::Array{Sym}
end

function polynomial(cf::CFiniteClosedForm) 
    if !isempty(cf.expvars)
        return (cf.expvars .* cf.coeff)[1]
        # return dot(cf.expvars, cf.coeff)
    else
        Error("No replacement variables for exponentials specified.")
    end
end

exponentials(cf::ClosedForm) = cf.exp

function expvars!(cf::ClosedForm, d::Dict{Sym,Sym})
    cf.expvars = replace(cf.exp, d)
end 


function order(r::Recurrence)
    return length(r.coeffs) - 1
end

function relation(r::Recurrence)
    return hompart(r) + r.inhom
end

function Base.show(io::IO, r::Recurrence)
    print(io, relation(r))
end

function hompart(r::Recurrence)
    return sum([c * r.f(r.n + (i - 1)) for (i, c) in enumerate(r.coeffs)])
end

function is_homogeneous(r::Recurrence)
    return simplify(r.inhom) == 0
end

function homogeneous(r::Recurrence)
    n = r.n
    if is_homogeneous(r)
        return r
    elseif is_polynomial(r.inhom, r.n)
        d = degree(Poly(r.inhom, n)) |> Int64
        res = relation(r)
        for i in 1:d + 1
            res = (res |> subs(n, n + 1)) - res
        end
        res = simplify(res)
        
        idx = n + order(r) + d + 1
        c = coeff(res, r.f(idx))
        return (simplify(res / c))
    else
        res = hompart(r) / r.inhom
        res = (res |> subs(n, n + 1)) - res
        idx = n + order(r) + 1
        c = coeff(res, r.f(idx))
        return (simplify(res / c))
    end
end

function closedform(r::Recurrence)
    rel = relation(r)
    w0  = Wild("w0")
    @syms lbd
    cpoly   = rel |> SymPy.replace(r.f(r.n + w0), lbd^w0)
    # factors = factor_list(cpoly)
    roots   = polyroots(cpoly)
    # d = hcat([[uniquevar() * r.n^i, z^r.n] for (z, m) in roots for i in 0:m - 1])
    # println(d[:,2])
    ansatz = sum([sum([uniquevar() * r.n^i * z^r.n for i in 0:m - 1]) for (z, m) in roots])
    println(ansatz)
    # println(free_symbols(ansatz(n)))
    unknowns = filter(e -> e != r.n, free_symbols(ansatz))
    println(unknowns)
    system = [Eq(r.f(i), ansatz |> subs(r.n, i)) for i in 0:order(r) - 1]
    println(system)
    sol = solve(system, unknowns)
    sol = (ansatz |> subs(sol))
    println("sol: ", sol)
    exp = [z for (z, _) in roots]
    println("exp: ", exp)
    coeff = [SymPy.coeff(sol, simplify(z^r.n)) for z in exp]
    println("coeff: ", coeff)
    return CFiniteClosedForm(r.f, r.n, exp, coeff)
end

# @syms n
# f = SymFunction("F")

# rec = CFiniteRecurrence([Sym(-1),Sym(-1),Sym(1)], f, n)

# r2 = CFiniteRecurrence([Sym(-2),Sym(1)], f, n)

# closedform(rec)

# println("order: ", order(rec))

# inhom = CFiniteRecurrence([Sym(-1),Sym(-1),Sym(1)], f, n, 2)
# is_homogeneous(inhom)
# homogeneous(inhom)