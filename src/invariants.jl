
abstract type Loop end

const LoopBody = Array{<:Recurrence,1}

type EmptyLoop <: Loop end

struct SingleLoop <: Loop
    body::LoopBody
    lc::Sym
    vars::Array{Sym,1}
    # cond::Expr # not used for now
    # init
end

struct MultiLoop <: Loop
    branches::Array{SingleLoop}
    vars::Array{Sym,1}
    # cond::Expr
    # init
end

Base.length(ideal::Singular.sideal) = ngens(ideal)
Base.start(ideal::Singular.sideal) = 1
Base.next(ideal::Singular.sideal, state) = (ideal[state], state+1)
Base.done(ideal::Singular.sideal, state) = state > ngens(ideal)
Base.eltype(::Singular.sideal) = Singular.spoly

import Base.==

function ==(I::Singular.sideal, J::Singular.sideal)
    # TODO: is this the right kind of equality?
    for (a, b) in zip(I, J)
        if a != b
            return false
        end
    end
    return true
 end

function invariants(loop::MultiLoop)
    index = 0
    vars = [Sym("$(v)_0") for v in loop.vars]
    R, _ = PolynomialRing(QQ, string.(union(loop.vars, vars)))
    JJ = nothing
    J = Nullable{sideal}()
    while JJ == nothing || I != JJ
        I = JJ
        for l in loop.branches
            J = invariants(l, precond=Nullable{sideal}(J), index=index)
            println("New Ideal: ", J)
            index += 1
        end
        finvars = [Sym("$(v)_$(index)") for v in loop.vars]
        inivars = [Sym("$(v)") for v in loop.vars]
        b = [x - y for (x,y) in zip(finvars, inivars)]
        B, varmap = Ideal(b)
        elim = prod([varmap[v] for v in finvars])
        B = imap(B, base_ring(J))
        elim = imap(elim, base_ring(J))

        JJ = Singular.eliminate(J + B, elim)
        JJ = imap(JJ, R)
    end
    JJ
end

function invariants(loop::SingleLoop; precond::Nullable{sideal}=Nullable{sideal}(), index::Int=0)
    println("Invariants: ", loop)
    cfs = closedform.(loop.body)
    exp = union(exponentials.(cfs)...)
    exp = filter(x -> x!=Sym(1), exp)
    # TODO: Make sure that these variables are unique
    expv = symset("vvv", length(exp))

    emap = Dict(zip(exp, expv))
    expvars!.(cfs, emap)

    polyfn(cf) = Sym(string(Sym(cf.f.x))) - replace_init_vars(polynomial(cf), cf.f, index)[1]
    basis = polyfn.(cfs)
    # println("Basis (before preprocessing): ", basis)

    initvars = [Sym("$(v)_0") for v in loop.vars]
    midvars = [Sym("$(v)_$(index)") for v in loop.vars]
    vars = union(free_symbols.(basis)...)
    newvars = [Sym(string(v, "_", index+1)) for v in loop.vars]
    dict = Dict(zip(loop.vars, newvars))
    basis = [b |> subs(dict) for b in basis]
    # println("Basis (in invariatns): ", basis)
    I, varmap = Ideal(basis, vars=union(vars, initvars))
    if !isnull(precond)
        J = imap(get(precond), base_ring(I))
        I = I + J
    end
    elim = [get(varmap, loop.lc, 1)]
    if !isnull(precond)
        elim = union(elim, [get(varmap, v, 1) for v in midvars])
    end
    # elim = union(elim, )
    if isempty(exp)
        # println("Eliminate Inv: ", elim)
        if elim != [1]
            I = Singular.eliminate(I, prod(elim))
        end
        return groebner(I)
    end    

    A = dependencies(exp, variables = expv)

    if A != nothing
        R = base_ring(I)
        I += imap(A, R)
    end
    # elim = [expv; loop.lc]
    elim = union(elim, [varmap[v] for v in expv])
    return Singular.eliminate(I, prod(elim))
end

function imap(I::sideal, R::Singular.PolyRing)
    basis = [imap(g, R) for g in I]
    println("Ideal: ", I)
    println("Basis: ", basis)
    if isempty(basis)
        return Singular.Ideal(R)
    end
    Singular.Ideal(R, basis)
end

function replace_init_vars(expr::Sym, f::SymFunction, index::Int=0)
    w0   = Wild("w0")
    fns  = Sym.(collect(atoms(expr, AppliedUndef)))
    args = [Int(match(f(w0), fn)[w0]) for fn in fns]
    ffns = [f(x) for x in args]
    vars = [Sym("$(string(Sym(f.x)))_$(Int(x)+index)") for x in args]
    dict = Dict(zip(ffns, vars))
    return subs(expr, dict), vars
end