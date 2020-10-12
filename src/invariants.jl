struct BranchIterator
    bs::Vector{sideal}
    vars::Vector{String}
    auxvars::Vector{String}
    length::Int
end

function BranchIterator(bs::Vector{Vector{MPolyElem}}, vars::Vector{Symbol}, auxvars::Vector{Symbol})
    vs = [map(Recurrences.initvar, vars); vars; auxvars]
    R, _ = Singular.PolynomialRing(Nemo.QQ, map(string, vs))
    σ = IdMap(R)
    ideals = [Singular.Ideal(R, map(σ, b)) for b in bs]
    @debug "Ideals in branch iterator" ideals
    len = length(ideals) == 1 ? 1 : length(ideals) * (length(vars) + 1)
    BranchIterator(ideals, map(string, vars), map(string, auxvars), len)
end

nbranches(iter::BranchIterator) = length(iter.bs)

splitgens(R, lss...) = let sf = Iterators.Stateful(gens(R))
    (collect(Iterators.take(sf, length(ls))) for ls in lss)
end

function stateideal(iter::BranchIterator, I::sideal, state::Int)
    is = [Recurrences.initvar(v, 0) for v in iter.vars]
    ms = [Recurrences.initvar(v, state + 1) for v in iter.vars]
    fs = [Recurrences.initvar(v, state + 2) for v in iter.vars]
    as = iter.auxvars
    R, _ = Singular.PolynomialRing(Nemo.QQ, map(string, [ms; fs; as; is]))
    mss, _, ass, _ = splitgens(R, ms, fs, as, is)
    σ = IndexMap(R)
    Singular.Ideal(R, [σ(g; force=true) for g in gens(I)]), [mss; ass]
end

function Base.iterate(iter::BranchIterator)
    if length(iter) == 0
        return nothing
    # elseif length(iter) == 1
    #     I = iter.bs[1]
    #     _, _, as = splitgens(base_ring(I), iter.vars, iter.vars, iter.auxvars)
    #     return (iter.bs[1], as), 1
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

function initial_ideal(vars::Vector{String}, init::ValueMap)
    is = [Recurrences.initvar(v, 0) for v in vars]
    fs = [Recurrences.initvar(v, 1) for v in vars]

    R, svars = Singular.PolynomialRing(Nemo.QQ, [is; fs])
    iss, fss = splitgens(R, is, fs)
    
    iss = [haskey(init, Symbol(v)) ? Nemo.QQ(init[Symbol(v)]) : iss[i] for (i, v) in enumerate(vars)]

    basis = [x - y for (x, y) in zip(iss, fss)]
    Singular.Ideal(R, basis)
end

function invariants(bs::Vector{Vector{MPolyElem}}, vars::Vector{Symbol}, auxvars::Vector{Symbol}, init::ValueMap)
    biter = BranchIterator(bs, vars, auxvars)
    # if length(biter) == 1
    #     I, elim = first(biter)
    #     I = Singular.eliminate(I, elim...)
    #     return I
    # end
    fixedpoint(biter, map(string, vars), init)
end

function fixedpoint(biter::BranchIterator, vars::Vector{String}, init::ValueMap)
    is = [Recurrences.initvar(v, 0) for v in vars]    
    vs = [vars; is]
    R, _ = Singular.PolynomialRing(Nemo.QQ, vs)
    bcount = nbranches(biter)
    I = Singular.Ideal(R)
    T = initial_ideal(vars, init)
    for (i, (J, elim)) in enumerate(biter)
        S = base_ring(J)
        T = imap(T, S) # map old ideal to new ring via variable name
        T = Singular.eliminate(T + J, elim...)

        if i % bcount == 0
            fs = [Recurrences.initvar(v, i + 1) for v in vars]
            RR, _ = Singular.PolynomialRing(Nemo.QQ, [fs; is])
            II = std(fetch(imap(T, RR), R)) # map current ideal to final ring
            if bcount == 1
                return II
            end
            @debug "Check if ideals are equal" T II I std(I) R isequal(I, II)
            if isequal(I, II)
                return I
            end
            I = II
        end
    end
    error("Fixed-point computation failed. Should not happen.")
end

# ------------------------------------------------------------------------------

function invariants(cs::Vector{Vector{T}}, _vars::Vector{Symbol}, init::ValueMap) where {T <: Recurrences.ClosedForm}
    __vars = [Set(first(c) for c in branch) for branch in cs]
    vars = [x for x in intersect(__vars...)]
    removed = setdiff(Set(_vars), Set(vars))
    if !isempty(removed)
        @debug "No closed form found for $removed"
    end
    ps = Vector{MPolyElem}[]
    as = Symbol[]
    for c in cs
        p, auxvars = polys(c, vars)
        push!(ps, p)
        push!(as, auxvars...)
    end
    invariants(ps, vars, as, init)
end

# ------------------------------------------------------------------------------

AbstractAlgebra.isconstant(x::FracElem) = AbstractAlgebra.isconstant(numerator(x)) && AbstractAlgebra.isconstant(denominator(x))
AbstractAlgebra.isconstant(x::fmpq) = true

get_constant(x::PolyElem) = get_constant(AbstractAlgebra.coeff(x, 0))
get_constant(x::MPolyElem) = iszero(x) ? zero(base_ring(x)) : get_constant(AbstractAlgebra.coeff(x, 1))
get_constant(x::FracElem) = get_constant(numerator(x)) // get_constant(denominator(x))
get_constant(x::RingElem) = x
get_constant(x::FieldElem) = x

AbstractAlgebra.show_minus_one(::Type{T}) where T <: FracElem = false

function polys(cs::Vector{ClosedForm}, _all_vars::Vector{Symbol})

    all_vars = copy(_all_vars)

    geometrics = Dict{fmpq,Symbol}()
    factorials = Dict{fmpq,Symbol}()

    function map_geom(x::fmpq)
        isone(x) && return x
        haskey(geometrics, x) && return geometrics[x]
        s = Recurrences.gensym_unhashed(:g)
        push!(geometrics, x=>s)
        return s
    end

    function map_fact(x::fmpq_poly)
        R = parent(x)
        v = gen(parent(x))
        c = x - v
        @assert isconstant(c) c
        c = Nemo.coeff(c, 0)
        for (k, s) in factorials
            d = k - c
            iszero(d) && return s, one(R)//one(R)
            if isone(denominator(d))
                n = numerator(d)
                p = prod(v + k + i for i in 1:abs(n))
                q = R(prod(c + i for i in 0:abs(n)-1))
                @debug "map_fact" n p q factorials
                if n < 0
                    return s, p // q
                else
                    return s, q // p
                end
            end
        end
        s = Recurrences.gensym_unhashed(:f)
        @assert isconstant(c)
        push!(factorials, c=>s)
        return s, one(R)//one(R)
    end

    function _poly(t::Recurrences.HyperTerm)
        c = Recurrences.coeff(t)
        g = Recurrences.geom(t)
        f = Recurrences.fact(t)
        n, d = numerator(f), denominator(f)
        # make fmpq_poly, needed for factorization
        nn = map_coeffs(get_constant, n)
        dd = map_coeffs(get_constant, d)

        function __factor(__x::fmpq_poly)
            __f = Nemo.factor(__x)
            c *= get_constant(unit(__f))
            __vs = Pair{Symbol,fmpz}[]
            for (__fac, __mul) in __f
                # poly should be monic
                lcoeff = Nemo.coeff(__fac, 1)
                __fac = __fac * (1//lcoeff)
                c *= lcoeff
                __var, __coeff = map_fact(__fac)
                __coeff = change_base_ring(base_ring(base_ring(c)), __coeff)
                c *= __coeff
                push!(__vs, __var=>__mul)
            end
            __vs
        end
        @assert AbstractAlgebra.isconstant(g)
        facts = __factor(nn)=>__factor(dd)
        c, map_geom(get_constant(g)), facts
    end

    function _poly(c::ClosedForm)
        first(c), [_poly(t) for t in Recurrences.terms(last(c))]
    end

    res = map(_poly, cs)

    final_vars = map(string, all_vars)
    init_vars = map(Recurrences.initvar, final_vars)
    rec_var = string(var(base_ring(last(first(cs)))))

    mvars = String[rec_var]
    append!(mvars, final_vars)
    append!(mvars, init_vars)
    append!(mvars, string(v) for v in values(geometrics))
    append!(mvars, string(v) for v in values(factorials))
    R, _ = Nemo.PolynomialRing(Nemo.QQ, collect(mvars))
    σ = IdMap(R)
    lcm_global = one(R)

    function _to_mpoly(v::Symbol, terms)
        filter!(x->x!=v, all_vars)
        lcm = one(R)
        res = zero(R)
        for (coeff, geom, (fact_num, fact_den)) in terms
            c, g = σ(coeff), σ(geom)
            fn = reduce(*, σ(first(x)) for x in fact_num; init=one(R))
            fd = reduce(*, σ(first(x)) for x in fact_den; init=one(R))
            AbstractAlgebra.lcm(lcm, denominator(c)*fd)
            res += c*g*(fn//fd)
        end
        AbstractAlgebra.lcm(lcm_global, lcm)
        rhs = lcm*res
        # TODO: compute saturated ideal
        denominator(rhs)*lcm*σ(v) - numerator(rhs)
    end

    polys = map(x->_to_mpoly(x...), res)
    for v in all_vars
        push!(polys, σ(v) - σ(Recurrences.initvar(v)))
    end

    if length(geometrics) > 0
        geoms = [replace(string(g), "//"=>"/") for g in keys(geometrics)]
        gvars = collect(values(geometrics))
        I = dependencies(sideal, geoms; variables = gvars)
        if !isnothing(I)
            aRing, _ = Singular.AsEquivalentAbstractAlgebraPolynomialRing(base_ring(I))
            for p in gens(I)
                push!(polys, σ(aRing(p); force=true))
            end
        end
    end
    @debug "Closed form polynomials" polys
    polys, Iterators.flatten(((v for v in values(geometrics)), (v for v in values(factorials)), [Symbol(rec_var)]))
end
