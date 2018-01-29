
import Base.show
import SymPy.solve
import SymPy.coeff
import SymPy.degree
import SymPy.subs

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
    end
    return (cf.exp .* cf.coeff)[1]
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

function rhs(r::Recurrence)
    simplify(-sum([c * r.f(r.n + (i - 1)) for (i, c) in enumerate(r.coeffs[1:end-1])]) - r.inhom)
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
        return eq2rec(simplify(res / c), r.f, r.n)
    else
        res = hompart(r) / r.inhom
        res = (res |> subs(n, n + 1)) - res
        idx = n + order(r) + 1
        c = coeff(res, r.f(idx))
        return eq2rec(simplify(res / c), r.f, r.n)
    end
end

function rewrite(d::Dict{Sym,Sym})
    # TODO: successively apply rewrite rules do values of dict
    dd = Dict{Sym,Sym}()
    while dd != d
        dd = d
        for (k, v) in d
            for (g, h) in dd
                dd[g] = h |> subs(k, v)
            end
        end
    end
    dd
end

function closedform(orig::Recurrence)
    println("Original: ", orig)
    r = homogeneous(orig)
    println("Homogenous: ", r)
    

    shift = order(r) - order(orig)
    rh = rhs(orig)
    init = Dict{Sym,Sym}([(orig.f(i), rh |> SymPy.replace(orig.n, i-1)) for i in 1:shift])
    # init = rewrite(init)

    println("Init: ", init)

    rel = relation(r)
    println("Recurrence: ", r)
    # println("Homogeneous: ", homogeneous(r))
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
    println("Solution: ", sol)
    sol = ansatz |> subs(sol)
    
    if !isempty(init)
        tmp = nothing
        while true
            tmp = sol |> subs(init)
            if tmp == sol
                break
            end
            sol = tmp
            println("tmp: ", tmp)
        end
        sol = simplify(tmp)
    end
    
    println("roots: ", roots)
    println("sol: ", sol)
    exp = sort([z for (z, _) in roots], rev=true)
    println("exp: ", exp)
    # coeff = [SymPy.coeff(sol, simplify(z^r.n)) for z in exp]
    coeff = exp_coeffs(sol, [z^r.n for z in exp])
    println("coeff: ", coeff)
    return CFiniteClosedForm(r.f, r.n, exp, coeff)
end

function exp_coeffs(expr::Sym, exp::Array{Sym,1})
    # assume if 1 in exp then it is at the end
    coeffs = Sym[]
    for ex in exp
        if ex == Sym(1)
            push!(coeffs, expr)
        else
            println("Expcoeffs: ", expr)
            c = SymPy.coeff(expr, simplify(ex))
            push!(coeffs, c)
            expr = simplify(expr - c*ex)
        end
    end
    coeffs
end

function rec_dependency(recs::Array{<: Recurrence,1})
    rec_dependency([], [], recs...)
end

function rec_dependency(indep, dep, rec::Recurrence, recs::Recurrence...)
    expr = rhs(rec)
    fns = symfunctions(expr)
    println("Functions: ", fns)
    # fns = union([match(f, w1(rec.n + w0))[w1] for f in fns])
    depvars = filter(x -> (func(x)!=Sym(rec.f.x) && !in(Sym(0), args(x))), fns)
    println("Functions 2: ", depvars)
    
    if isempty(depvars)
        push!(indep, rec)
    else
        push!(dep, (rec, depvars))
    end
    rec_dependency(indep, dep, recs...)
end

function rec_dependency(indep, dep)
    indep, dep
end

function subs(cf::ClosedForm, r::CFiniteRecurrence)
    println("[subs] Closed form: ", cf)
    println("[subs] Recurrence: ", r)
    rel = relation(r)
    rhs = polynomial(cf)
    fns = symfunctions(rel)
    for fn in fns
        println("Function: ", fn)        
        if func(fn) == Sym(cf.f.x)
            println("ADSKFLJASDLKFJASDL")
            w0 = Wild("w0")
            idx = match(cf.f(cf.n + w0), fn)[w0]
            # println(idx)
            sub = rhs |> SymPy.subs(cf.n, cf.n + idx)
            rel = rel |> SymPy.subs(cf.f(cf.n + idx), sub) |> simplify
        end
    end
    return eq2rec(rel, r.f, r.n)
    # r
end

function rec_solve(recs::Array{<: Recurrence,1})

    # recs = loop.body
    solved = ClosedForm[]
    solvable = true
    while solvable
        indep, dep = rec_dependency(recs)
        indepcnt = length(indep)
        depcnt = length(dep)
        
        if indepcnt == 0 && depcnt != 0
            error("Illegal coupling detected in loop body")
        elseif indepcnt == 0 && depcnt == 0
            break
        end

        recs = setdiff(recs, indep)
        for rec in indep
            cf = closedform(rec)

            # TODO: deal with the case when a recurrence is not solvable

            push!(solved, cf)
            recs = filter(x -> x!=rec, recs)

            recs = [subs(cf, r) for r in recs]
            println("Changed recurrences:", recs)
        end
        if isempty(recs)
            break
        end
    end
    solved
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