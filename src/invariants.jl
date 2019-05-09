struct BranchIterator
    bs::Vector{sideal}
    vars::Vector{String}
    auxvars::Vector{String}
    length::Int
end

function BranchIterator(bs::Vector{Vector{Basic}}, vars::Vector{Basic}, auxvars::Vector{Basic})
    vs = [map(initvar, vars); vars; auxvars]
    R, _ = PolynomialRing(QQ, map(string, vs))
    ideals = [Singular.Ideal(R, map(R, b)) for b in bs]
    @debug "Ideals in branch iterator" ideals
    len = length(ideals) == 1 ? 1 : length(ideals) * (length(vars) + 1)
    BranchIterator(ideals, map(string, vars), map(string, auxvars), len)
end

nbranches(iter::BranchIterator) = length(iter.bs)

splitgens(R, lss...) = let sf = Iterators.Stateful(gens(R))
    (collect(Iterators.take(sf, length(ls))) for ls in lss)
end

function stateideal(iter::BranchIterator, I::sideal, state::Int)
    is = [initvar(v, 0) for v in iter.vars]
    ms = [initvar(v, state + 1) for v in iter.vars]
    fs = [initvar(v, state + 2) for v in iter.vars]
    as = iter.auxvars
    R, _ = PolynomialRing(QQ, map(string, [ms; fs; as; is]))
    mss, _, ass, _ = splitgens(R, ms, fs, as, is)
    fetch(I, R), [mss; ass]
end

function Base.iterate(iter::BranchIterator)
    if length(iter) == 0
        return nothing
    elseif length(iter) == 1
        I = iter.bs[1]
        _, _, as = splitgens(base_ring(I), iter.vars, iter.vars, iter.auxvars)
        return (iter.bs[1], as), 1
    end
    stateideal(iter, iter.bs[1], 0), 1
end

function Base.iterate(iter::BranchIterator, state)
    if state >= length(iter)
        return nothing
    end
    i = state % length(iter.bs) + 1
    stateideal(iter, iter.bs[i], state), state + 1
end

Base.IteratorSize(::Type{BranchIterator}) = Base.HasLength()
Base.length(iter::BranchIterator) = iter.length

# ------------------------------------------------------------------------------

function initial_ideal(vars::Vector{String})
    is = [initvar(v, 0) for v in vars]
    fs = [initvar(v, 1) for v in vars]

    R, svars = PolynomialRing(QQ, [is; fs])
    iss, fss = splitgens(R, is, fs)
    
    basis = [x - y for (x, y) in zip(iss, fss)]
    Singular.Ideal(R, basis)
end

function invariants(bs::Vector{Vector{Basic}}, vars::Vector{Basic}, auxvars::Vector{Basic})
    biter = BranchIterator(bs, vars, auxvars)
    if length(biter) == 1
        I, elim = first(biter)
        I = Singular.eliminate(I, elim...)
        return I
    end
    fixedpoint(biter, map(string, vars))
end

function fixedpoint(biter::BranchIterator, vars::Vector{String})
    is = [initvar(v, 0) for v in vars]    
    vs = [is; vars]
    R, _ = PolynomialRing(QQ, vs)
    bcount = nbranches(biter)
    I = Singular.Ideal(R)
    T = initial_ideal(vars)
    for (i, (J, elim)) in enumerate(biter)
        @debug "Fixed point iterations $i" T J
        S = base_ring(J)
        T = imap(T, S) # map old ideal to new ring via variable name
        T = Singular.eliminate(T + J, elim...)

        if i % bcount == 0
            fs = [initvar(v, i + 1) for v in vars]
            RR, _ = PolynomialRing(QQ, [fs; is])
            II = std(fetch(imap(T, RR), R)) # map current ideal to final ring
            @debug "Check if ideals are equal" T II I R isequal(I, II)
            if isequal(I, II)
                return I
            end
            I = II
        end
    end
    error("Fixed-point computation failed. Should not happen.")
end

# ------------------------------------------------------------------------------

function invariants(cs::Vector{Vector{T}}, vars::Vector{Symbol}) where {T <: Recurrences.ClosedForm}
    ps = Vector{Basic}[]
    as = Basic[]
    for c in cs
        p, auxvars = polys(c, vars)
        push!(ps, p)
        push!(as, auxvars...)
    end
    invariants(ps, map(Basic, vars), as)
end

function polys(cs::Vector{T}, vars::Vector{Symbol}) where {T <: Recurrences.ClosedForm}
    ls = Basic[]
    vs = Symbol[]
    exps = Base.unique(Iterators.flatten(map(exponentials, cs)))
    filter!(x->!iszero(x) && !isone(x), exps)
    evars = [Basic(Recurrences.gensym_unhashed(:v)) for _ in 1:length(exps)]
    ls = dependencies(exps; variables = evars)
    expmap = Dict(zip(exps, evars))
    push!(expmap, zero(Basic) => zero(Basic))
    @debug "Exponentials" exps expmap
    for c in cs
        exp = exponentials(c)
        exp = [get(expmap, x, x) for x in exp]
        p = c.func - expression(c; expvars = exp)
        p = SymEngine.expand(p * denominator(p))
        push!(ls, p)
        push!(vs, Symbol(string(c.func)))
    end
    for v in setdiff(vars, vs)
        push!(ls, :($v - $(initvar(v))))
    end
    ls, [evars; cs[1].arg]
end