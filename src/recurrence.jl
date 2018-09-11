
import Base.show
import Base.==
import Base.isequal
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

function order(r::Recurrence)
    return length(r.coeffs) - 1
end

function relation(r::Recurrence)
    return hompart(r) + r.inhom
end

function Base.show(io::IO, r::Recurrence)
    print(io, "$(lhs(r)) = $(rhs(r))")
end

function hompart(r::Recurrence)
    return sum([c * r.f(r.n + (i - 1)) for (i, c) in enumerate(r.coeffs)])
end

function is_homogeneous(r::Recurrence)
    return simplify(r.inhom) == 0
end

function rhs(r::Recurrence)
    if length(r.coeffs) == 1
        return -r.inhom
    end
    simplify(-sum([c * r.f(r.n + (i - 1)) for (i, c) in enumerate(r.coeffs[1:end-1])]) - r.inhom)
end

function lhs(r::Recurrence)
    t = r.f(r.n + order(r))
    if length(r.coeffs) > 1
        t *= r.coeffs[end]
    end
    t
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
        res = expand((res |> subs(n, n + 1)) - res)
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

function closedform(orig::CFiniteRecurrence)
    # println("Original: ", orig)
    r = homogeneous(orig)
    # println("Homogeneous: ", r)
    
    shift = order(r) - order(orig)
    rh = rhs(orig)
    ord = order(orig)
    init = Dict{Sym,Sym}([(orig.f(i), rh |> SymPy.replace(orig.n, i-ord)) for i in ord:shift+ord-1])
    # init = rewrite(init)

    rel = relation(r)
    # println("Homogeneous: ", homogeneous(r))
    w0  = Wild("w0")
    @syms lbd
    cpoly   = rel |> SymPy.replace(r.f(r.n + w0), lbd^w0)
    # println("CPoly: ", cpoly |> simplify)
    # factors = factor_list(cpoly)
    roots   = polyroots(cpoly)
    # d = hcat([[uniquevar() * r.n^i, z^r.n] for (z, m) in roots for i in 0:m - 1])
    # println(d[:,2])
    ansatz = sum([sum([uniquevar() * r.n^i * z^r.n for i in 0:m - 1]) for (z, m) in roots])
    # println(ansatz)
    # println(free_symbols(ansatz(n)))
    unknowns = filter(e -> e != r.n, free_symbols(ansatz))
    system = [Eq(r.f(i), ansatz |> subs(r.n, i)) for i in 0:order(r) - 1]
    sol = solve(system, unknowns)
    sol = ansatz |> subs(sol)
    if !isempty(init)
        tmp = nothing
        while true
            tmp = (sol |> subs(init)) |> simplify
            if tmp == sol
                break
            end
            sol = tmp
            
        end
        sol = simplify(tmp)
    end
    
    exp = [z for (z, _) in roots]
    exp = filter(x -> x!=Sym(1), exp)
    push!(exp, Sym(1))
    coeff = exp_coeffs(sol, [z^r.n for z in exp])
    return CFiniteClosedForm(r.f, r.n, exp, coeff)
end

function exp_coeffs(expr::Sym, exp::Array{Sym,1})
    # assume if 1 in exp then it is at the end
    coeffs = Sym[]
    for ex in exp
        if ex == Sym(1)
            push!(coeffs, expr)
        else
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
    depvars = filter(x -> (func(x)!=Sym(rec.f.x) && !in(Sym(0), args(x))), fns)
    
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
    rel = relation(r)
    rhs = poly(cf)
    fns = symfunctions(rel)
    for fn in fns
        if func(fn) == Sym(cf.f.x)
            w0 = Wild("w0")
            idx = match(cf.f(cf.n + w0), fn)[w0]
            sub = rhs |> SymPy.subs(cf.n, cf.n + idx)
            rel = rel |> SymPy.subs(cf.f(cf.n + idx), sub) |> simplify
        end
    end
    return eq2rec(rel, r.f, r.n)
end

function rec_solve(recsorig::Array{<: Recurrence,1})
    # println("Recurrences: ", recs)
    if length(recsorig) == 0
        return ClosedForm[]
    end

    varlist = [(r.f(r.n), r.f) for r in recsorig]
    recs, varlist = rec_simplify(Recurrence[], varlist, recsorig...)
    # println("Simplifed recurrences: ", recs)
    # println("Varlist: ", varlist)
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
        end
        if isempty(recs)
            break
        end
    end

    inivars = []
    for cf in solved
        inivars = [inivars; initvars(cf)]
    end
    inivars = [(SymFunction(string(func(x))), args(x)[1]) for x in inivars]
    inivars = filter(x -> x[2]>0, inivars)
    iniexpr = init_expr(recsorig, inivars)
    # println("Initial expression: ", iniexpr)

    for var in varlist
        # TODO: assume var is something like (t(n-1), x)
        fn = SymFunction(string(func(var[1])))
        if fn != var[2]
            for cf in solved
                if cf.f == fn
                    sh = args(var[1])[1] - cf.n
                    tmp = shift(cf, sh)
                    tmp.f = var[2]
                    push!(solved, tmp)
                    break
                end
            end
        end
    end
    [subs!(cf, iniexpr...) for cf in solved]
end

function ==(f::SymFunction, g::SymFunction)
    isequal(Sym(f.x), Sym(g.x))
end

function init_expr(recs::Array{<:Recurrence,1}, vars::Array{Tuple{SymFunction,Sym},1})
    initrules = Pair[]
    for (var, idx) in vars
        rec = [r for r in recs if r.f == var][1]
        rhs = initial(rec, idx)
        while true
            newvars = [(SymFunction(string(func(t))), args(t)[1]) for t in symfunctions(rhs) if args(t)[1] > 0]
            # newvars = filter(x -> x[2]>0, newvars)
            if isempty(newvars)
                break
            end
            rules = init_expr(recs, newvars)
            rhs = (rhs |> subs(rules...)) |> simplify
        end
        push!(initrules, Pair(var(idx), rhs))
    end
    initrules
end

function initial(r::CFiniteRecurrence, n::Sym)
    if n < order(r)
        error("Cannot give expression for $(r.f(n))")
    end
    i = n - order(r)
    rhs(r) |> subs(r.n, i)
end

function initvars(r::ClosedForm)
    symfunctions(rhs(r))
end

#-------------------------------------------------------------------------------

function contains_func(expr::Sym, f::SymFunction)
    fns = symfunctions(expr)
    w0 = Wild("w0")
    args = [get(match(f(w0), fn), w0, nothing) for fn in fns]
    args = filter(x -> x!=nothing, args)
    !isempty(args)
end

function rec_subs(r::Recurrence, rec::Recurrence)
    # println("subs $(rec) in $(r)")
    expr = rhs(r)
    fns = symfunctions(expr)
    w0 = Wild("w0")
    args = [get(match(rec.f(w0), fn), w0, nothing) for fn in fns]
    args = filter(x -> x!=nothing, args)
    if isempty(args)
        return r
    end
    for arg in args
        diff = rec.n + 1 - arg
        sub = rhs(rec) |> subs(rec.n, rec.n - diff)
        expr = expr |> subs(rec.f(arg), sub)
    end
    # assume lhs of rec is always f(n+1) (just temporarily)
    # println("result: ", expr)
    eq2rec(r.f(r.n+1) - simplify(expr), r.f, r.n)
end

function rec_subs(expr::Sym, rec::Recurrence)
    # println("subs $(rec) in $(r)")
    # expr = rhs(r)
    fns = symfunctions(expr)
    w0 = Wild("w0")
    args = [get(match(rec.f(w0), fn), w0, nothing) for fn in fns]
    args = filter(x -> x!=nothing, args)
    for arg in args
        diff = rec.n + 1 - arg
        sub = rhs(rec) |> subs(rec.n, rec.n - diff)
        expr = expr |> subs(rec.f(arg), sub)
    end
    simplify(expr)
end

# function rec_simplify(recs::Array{<:Recurrence,1})
#     # processed = Recurrence[]
#     # for rec in recs
#     #     expr = rhs(rec)
#     #     # fns = symfunctions(expr)
#     #     # w0 = Wild("w0")
#     #     # args = [match(rec.f(w0), expr)[w0] for fn in fns]
#     #     if !contains_func(expr, rec.f) # not a real recurrence
#     #         processed = [rec_subs(r, rec) for r in processed]
#     #         recs = [rec_subs(r, rec) for r in recs]
#     #     else
#     #         push!(processed, rec)
#     #     end
#     # end
#     # processed
#     rec_simplify(Recurrence[], recs...)
# end

function rec_simplify(processed::Array{<:Recurrence}, varlist::Array{Tuple{Sym,SymFunction},1}, rec::Recurrence, recs::Recurrence...)
    expr = rhs(rec)
    # fns = symfunctions(expr)
    # w0 = Wild("w0")
    # args = [match(rec.f(w0), expr)[w0] for fn in fns]
    if !contains_func(expr, rec.f) # not a real recurrence
        varlist = [var_simplify(var, rec) for var in varlist]
        processed = [rec_subs(r, rec) for r in processed]
        recs = [rec_subs(r, rec) for r in recs]
    else
        push!(processed, rec)
    end
    rec_simplify(processed, varlist, recs...)
end

function rec_simplify(processed::Array{<:Recurrence}, varlist::Array{Tuple{Sym,SymFunction},1})
    processed, varlist
end

function var_simplify(var::Tuple{Sym,SymFunction}, rec::Recurrence)
    rec_subs(var[1], rec), var[2]
end
