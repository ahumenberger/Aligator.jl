
abstract type Loop end

const LoopBody = Array{<:Recurrence,1}

type EmptyLoop <: Loop end

struct SingleLoop <: Loop
    body::LoopBody
    lc::Sym
    vars::Array{Sym,1}
end

struct MultiLoop <: Loop
    branches::Array{SingleLoop}
    vars::Array{Sym,1}
end

function Base.show(io::IO, body::LoopBody)
    print(io, "[")
    join(io, body, ", ")
    println(io, "]")
end

function Base.show(io::IO, loop::SingleLoop)
    if get(io, :compact, false)
        Base.show(io, loop.body)
    else
        println(io, "$(length(loop.body))-element $(typeof(loop)):")
        for l in loop.body
            print(io, "  $(l)\n")
        end
    end
end

function Base.show(io::IO, loop::MultiLoop)
    println(io, "$(length(loop.branches))-element $(typeof(loop)):")
    for l in loop.branches
        print(io, " ")
        showcompact(io, l)
        # print(io, "\n")
    end
end

function closed_forms(loop::MultiLoop)
    [ClosedFormSystem(rec_solve(l.body), l.lc, l.vars) for l in loop.branches]
end

function closed_forms(loop::SingleLoop)
    ClosedFormSystem(rec_solve(loop.body), loop.lc, loop.vars)
end


#-------------------------------------------------------------------------------

function invariants(cforms::ClosedFormSystem)
    I, loopvars, expvars, lc = preprocess([cforms], singleloop = true)[1]
    elim = collect(Iterators.drop(Singular.gens(base_ring(I)), length(loopvars)*2))
    Singular.eliminate(I, prod(elim))     
end

function invariants(loop::SingleLoop)
    invariants(closed_forms(loop))
end

function invariants(loop::MultiLoop)
    invariants(closed_forms(loop))
end

function invariants(loops::Array{ClosedFormSystem,1})
    if length(loops) == 0
        warn("No loops given!")
        return
    end
    loopvars = string.(loops[1].vars)
    inivars = ["$(v)_0" for v in loopvars]
    R, _ = PolynomialRing(QQ, [inivars; loopvars])

    preprocessed = preprocess(loops)

    index = 0
    I_new = initial_ideal(loopvars)
    I_o = 1
    I_n = nothing
    while I_n != I_o
        I_o = I_n
        for sys in preprocessed
            I_new = invariants(I_new, sys..., index)
            # println("New ideal: ", I_new)
            index += 1
        end

        idxvars = ["$(v)_$(index+1)" for v in loopvars]
        S, _ = PolynomialRing(QQ, [inivars; loopvars; idxvars])
        # println("Container: ", S)
        # rename variables to have v instead of v_index
        b, elim = renaming_polys(loopvars, index)
        # println("Basis (before map): ", b)        
        b = [imap(g, S) for g in b]
        # println("Basis (after map): ", b)
        B = Singular.Ideal(S, b)

        elim = imap(prod(elim), S)

        I_n = Singular.eliminate(imap(I_new, S) + B, elim)
        I_n = groebner(imap(I_n, R))
        # println("Final ideal: ", I_n)
    end
    I_n
end

#-------------------------------------------------------------------------------

function preprocess(loops::Array{ClosedFormSystem,1}; singleloop::Bool = false)
    # assume loops[i].vars == loops[j].vars for all i,j

    # cfslist = [rec_solve(sl.body) for sl in loops]
    # cfslist = loops.cforms
    # println("Closed forms:", cfslist)

    preprocessed = []
    for (i, loop) in enumerate(loops)
        cfs = loop.cforms
        exp = union(exponentials.(cfs)...)
        exp = filter(x -> x!=Sym(1), exp)
        
        # collect all variables
        lc = string(loops[i].lc)
        loopvars = string.(loops[i].vars)
        expvars = ["vvv_$(i)" for i in 1:length(exp)]

        vars, _ = var_order(loopvars, expvars, lc, 0)        
        if singleloop
            vars, _ = var_order_single(loopvars, expvars, lc, 0)
        end

        R, svars = PolynomialRing(QQ, vars)
        varmap = Dict(zip(vars, svars))

        # replace exponentials in closed forms with variables
        if !isempty(expvars)
            expsym = Sym.(expvars)
            expmap = Dict(zip(exp, expsym))
            expvars!.(cfs, expmap)
        end

        # generate basis of closed forms
        function polyfn(cf) 
            if singleloop
                return Sym("$(Sym(cf.f.x))") - replace_functions(polynomial(cf), 0)
            end
            return Sym("$(Sym(cf.f.x))_2") - replace_functions(polynomial(cf), 1)
        end
        basis = polyfn.(cfs)

        sbasis = [sym2spoly(p, varmap) for p in basis]
        I = Singular.Ideal(R, sbasis)

        # dependencies
        if !isempty(exp)
            # println("Something with dependencies?????")            
            A = dependencies(exp, variables = expsym)
            if A != nothing
                # println("Something with imap?????")
                I += imap(A, R)
            else
                warn("No algebraic dependencies among exponentials! Is that correct?")
            end
        end    

        res = (I, loopvars, expvars, lc)
        push!(preprocessed, res)
    end
    # println(preprocessed)
    preprocessed
end

function invariants(I_old::sideal, I_new::sideal, loopvars::Array{String,1}, expvars::Array{String,1}, lc::String, index::Int)

    vars, elimcnt = var_order(loopvars, expvars, lc, index)
    R, svars = PolynomialRing(QQ, vars)
    # map variables via order
    I_new = fetch(I_new, R)
    # map variables via name
    I_old = imap(I_old, R)

    elimvars = collect(Iterators.drop(svars, elimcnt))
    Singular.eliminate(I_old + I_new, prod(elimvars))
end

function var_order(loopvars::Array{String,1}, expvars::Array{String,1}, lc::String, index::Int)
    inivars = ["$(v)_0" for v in loopvars]
    finvars = ["$(v)_$(index+2)" for v in loopvars]
    midvars = ["$(v)_$(index+1)" for v in loopvars]
    auxvars = [expvars; lc]

    vars = [inivars; finvars; midvars; auxvars], length(inivars) + length(finvars) # also return number of variables not to eliminate
end

function var_order_single(loopvars::Array{String,1}, expvars::Array{String,1}, lc::String, index::Int)
    inivars = ["$(v)_0" for v in loopvars]
    finvars = ["$(v)" for v in loopvars]
    auxvars = [expvars; lc]

    vars = [inivars; finvars; auxvars], length(inivars) + length(finvars) # also return number of variables not to eliminate
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

function replace_functions(expr::Sym, index::Int)
    w0   = Wild("w0")
    fns  = Sym.(collect(atoms(expr, AppliedUndef)))
    vars = [Sym("$(string(Sym(func(fn).x)))_$(Int(args(fn)[1])+index)") for fn in fns]
    dict = Dict(zip(fns, vars))
    return subs(expr, dict)
end
