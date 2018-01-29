
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

function invariants(loop::SingleLoop)
    inivars = [Sym("$(v)_0") for v in loop.vars]
    auxvars = [Sym("$(v)_1") for v in loop.vars]    
    finvars = [Sym("$(v)") for v in loop.vars]
    
    R, _ = PolynomialRing(QQ, string.(union(inivars, finvars)))

    cfs = rec_solve(loop.body)
    I = invariants(cfs, loop.vars, loop.lc)

    b = [x - y for (x,y) in zip(finvars, auxvars)]
    B, varmap = Ideal(b)
    elim = prod([varmap[v] for v in auxvars])
    B = imap(B, base_ring(I))
    elim = imap(elim, base_ring(I))

    I = Singular.eliminate(I + B, elim)
    imap(I, R)
end

function invariants(loop::MultiLoop)

    cfslist = [rec_solve(sl.body) for sl in loop.branches]

    index = 0
    vars = [Sym("$(v)_0") for v in loop.vars]
    R, _ = PolynomialRing(QQ, string.(union(loop.vars, vars)))
    JJ = nothing
    J = Nullable{sideal}()
    while JJ == nothing || I != JJ
        I = JJ
        for (i, l) in enumerate(cfslist)
            J = invariants(l, loop.vars, loop.branches[i].lc, precond=Nullable{sideal}(J), index=index)
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

function invariants(cfs::Array{<: ClosedForm}, loopvars::Array{Sym,1}, lc::Sym; precond::Nullable{sideal}=Nullable{sideal}(), index::Int=0)
    println("Invariants: ", cfs)
    # cfs = closedform.(loop.body)
    exp = union(exponentials.(cfs)...)
    exp = filter(x -> x!=Sym(1), exp)
    # TODO: Make sure that these variables are unique
    expv = symset("vvv", length(exp))

    emap = Dict(zip(exp, expv))
    expvars!.(cfs, emap)

    polyfn(cf) = Sym(string(Sym(cf.f.x))) - replace_init_vars(polynomial(cf), index)[1]
    basis = polyfn.(cfs)
    println("Basis (before preprocessing): ", basis)

    initvars = [Sym("$(v)_0") for v in loopvars]
    midvars = [Sym("$(v)_$(index)") for v in loopvars]
    vars = union(free_symbols.(basis)...)
    newvars = [Sym(string(v, "_", index+1)) for v in loopvars]
    dict = Dict(zip(loopvars, newvars))
    basis = [b |> subs(dict) for b in basis]
    # println("Basis (in invariatns): ", basis)
    I, varmap = Ideal(basis, vars=union(vars, initvars, midvars))
    if !isnull(precond)
        J = imap(get(precond), base_ring(I))
        println("Preconditions: ", get(precond))
        println("Mapped preconditions: ", J)
        println("The ideal: ", I)
        I = I + J
    end
    elim = [get(varmap, lc, 1)]
    if !isnull(precond)
        elim = union(elim, [get(varmap, v, 1) for v in midvars])
    end
    # elim = union(elim, )
    if isempty(exp)
        println("Eliminate Inv: ", elim)
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

function replace_init_vars(expr::Sym, index::Int=0)
    println("Replace init: ", expr)
    w0   = Wild("w0")
    fns  = Sym.(collect(atoms(expr, AppliedUndef)))
    # args = [Int(match(f(w0), fn)[w0]) for fn in fns]
    # ffns = [f(x) for x in args]
    vars = [Sym("$(string(Sym(func(fn).x)))_$(Int(args(fn)[1])+index)") for fn in fns]
    dict = Dict(zip(fns, vars))
    return subs(expr, dict), vars
end