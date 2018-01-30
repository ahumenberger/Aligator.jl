
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

#-------------------------------------------------------------------------------

function var_order(loopvars::Array{String,1}, expvars::Array{String,1}, lc::String, index::Int)
    inivars = ["$(v)_$(0)" for v in loopvars]
    finvars = ["$(v)_$(index+2)" for v in loopvars]
    midvars = ["$(v)_$(index+1)" for v in loopvars]
    auxvars = [expvars; lc]

    vars = [inivars; finvars; midvars; auxvars], length(inivars) + length(finvars) # also return number of variables not to eliminate
end

function preprocess(loops::Array{SingleLoop,1})
    # assume loops[i].vars == loops[j].vars for all i,j

    cfslist = [rec_solve(sl.body) for sl in loops]

    preprocessed = []
    for (i, cfs) in enumerate(cfslist)

        exp = union(exponentials.(cfs)...)
        exp = filter(x -> x!=Sym(1), exp)
        # TODO: Make sure that these variables are unique
        # expv = symset("vvv", length(exp))
        # expv = symset("vvv", length(exp))
        
        # collect all variables
        lc = string(loops[i].lc)
        loopvars = string.(loops[i].vars)
        expvars = ["vvv_$(i)" for i in 1:length(exp)]
        vars, _ = var_order(loopvars, expvars, lc, 0)

        R, svars = PolynomialRing(QQ, vars)
        varmap = Dict(zip(Sym.(vars), svars))

        # # collect all variables
        # inivars = ["$(v)_0" for v in loopvars]
        # finvars = ["$(v)" for v in loopvars]
        # auxvars = [expvars; string(loops[i].lc)]



        # replace exponentials in closed forms with variables
        expsym = Sym(expvars...)
        if !isempty(expvars)
            expmap = Dict(zip(exp, expsym))
            expvars!.(cfs, expmap)
        end

        # generate basis of closed forms
        polyfn(cf) = Sym("$(Sym(cf.f.x))_2") - replace_functions(polynomial(cf), 1)
        basis = polyfn.(cfs)

        sbasis = [sym2spoly(p, varmap) for p in basis]
        I = Singular.Ideal(R, sbasis)

        # dependencies
        if !isempty(exp)
            A = dependencies(exp, variables = expsym)
            if A != nothing
                I += imap(A, R)
            else
                warn("No algebraic dependencies among exponentials! Is that correct?")
            end
        end    

        res = (I, loopvars, expvars, lc)
        push!(preprocessed, res)
    end
    preprocessed
end

function invariants(I_old::sideal, I_new::sideal, loopvars::Array{String,1}, expvars::Array{String,1}, lc::String, index::Int)

    vars, elimcnt = var_order(loopvars, expvars, lc, index)
    R, svars = PolynomialRing(QQ, vars)
    # map variables via order
    println("I_new (before map): ", I_new)
    I_new = fetch(I_new, R)
    println("I_new (after map): ", I_new)
    
    # map variables via name
    println("I_old (before map): ", I_old)
    I_old = imap(I_old, R)
    println("I_old (after map): ", I_old)    

    elimvars = collect(Iterators.drop(svars, elimcnt))
    Singular.eliminate(I_old + I_new, prod(elimvars))
end

function invariants(loop::MultiLoop)
    loopvars = string.(loop.vars)
    inivars = ["$(v)_0" for v in loopvars]
    R, _ = PolynomialRing(QQ, [inivars; loopvars])

    preprocessed = preprocess(loop.branches)
    index = 0
    I_new = initial_ideal(loopvars)
    I_o = 1
    I_n = nothing
    # I_new = nothing
    while I_n != I_o
        I_o = I_n
        for sys in preprocessed
            I_new = invariants(I_new, sys..., index)
            println("New ideal: ", I_new)
            index += 1
        end

        idxvars = ["$(v)_$(index+1)" for v in loopvars]
        S, _ = PolynomialRing(QQ, [inivars; loopvars; idxvars])
        println("Container: ", S)
        # rename variables to have v instead of v_index
        b, elim = renaming_polys(loopvars, index)
        println("Basis (before map): ", b)        
        b = [imap(g, S) for g in b]
        println("Basis (after map): ", b)
        B = Singular.Ideal(S, b)

        elim = imap(prod(elim), S)

        I_n = Singular.eliminate(imap(I_new, S) + B, elim)
        I_n = groebner(imap(I_n, R))
        println("Final ideal: ", I_n)
    end
    I_n
end

function renaming_polys(loopvars::Array{String,1}, index::Int)
    midvars = ["$(v)_$(index+1)" for v in loopvars]
    # finvars = ["$(v)" for v in loopvars]

    _, svars = PolynomialRing(QQ, [midvars; loopvars])

    midcnt = length(midvars)
    midsvars = collect(Iterators.take(svars, midcnt))
    finsvars = collect(Iterators.drop(svars, midcnt))
    
    [ x - y for (x, y) in zip(midsvars, finsvars)], midsvars # also return variables to eliminate
end

function initial_ideal(loopvars::Array{String,1})
    inivars = ["$(v)_0" for v in loopvars]
    finvars = ["$(v)_1" for v in loopvars]

    R, svars = PolynomialRing(QQ, [inivars; finvars])

    inicnt = length(inivars)
    inisvars = collect(Iterators.take(svars, inicnt))
    finsvars = collect(Iterators.drop(svars, inicnt))
    
    basis = [ x - y for (x, y) in zip(inisvars, finsvars)]
    Singular.Ideal(R, basis)
end

#-------------------------------------------------------------------------------

function invariants(loop::SingleLoop)
    # inivars = [Sym("$(v)_0") for v in loop.vars]
    # auxvars = [Sym("$(v)_1") for v in loop.vars]    
    # finvars = [Sym("$(v)") for v in loop.vars]
    
    # R, _ = PolynomialRing(QQ, string.(union(inivars, finvars)))

    # cfs = rec_solve(loop.body)
    # I = invariants(cfs, loop.vars, loop.lc)

    # b = [x - y for (x,y) in zip(finvars, auxvars)]
    # B, varmap = Ideal(b)
    # elim = prod([varmap[v] for v in auxvars])
    # B = imap(B, base_ring(I))
    # elim = imap(elim, base_ring(I))

    # I = Singular.eliminate(I + B, elim)
    # imap(I, R)
end

# function invariants(loop::MultiLoop)

#     cfslist = [rec_solve(sl.body) for sl in loop.branches]

#     index = 0
#     vars = [Sym("$(v)_0") for v in loop.vars]
#     R, _ = PolynomialRing(QQ, string.(union(loop.vars, vars)))
#     JJ = nothing
#     J = Nullable{sideal}()
#     while JJ == nothing || I != JJ
#         I = JJ
#         for (i, l) in enumerate(cfslist)
#             J = invariants(l, loop.vars, loop.branches[i].lc, precond=Nullable{sideal}(J), index=index)
#             println("New Ideal: ", J)
#             index += 1
#         end
#         finvars = [Sym("$(v)_$(index)") for v in loop.vars]
#         inivars = [Sym("$(v)") for v in loop.vars]
#         b = [x - y for (x,y) in zip(finvars, inivars)]
#         B, varmap = Ideal(b)
#         elim = prod([varmap[v] for v in finvars])
#         B = imap(B, base_ring(J))
#         elim = imap(elim, base_ring(J))

#         JJ = Singular.eliminate(J + B, elim)
#         JJ = imap(JJ, R)
#     end
#     JJ
# end

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

function replace_functions(expr::Sym, index::Int)
    println("Replace functions: ", expr)
    w0   = Wild("w0")
    fns  = Sym.(collect(atoms(expr, AppliedUndef)))
    # args = [Int(match(f(w0), fn)[w0]) for fn in fns]
    # ffns = [f(x) for x in args]
    vars = [Sym("$(string(Sym(func(fn).x)))_$(Int(args(fn)[1])+index)") for fn in fns]
    dict = Dict(zip(fns, vars))
    return subs(expr, dict)
end