
struct BranchIterator
    bs::Vector{sideal}
    vars::Vector{String}
    auxvars::Vector{String}
    length::Int
end

function BranchIterator(bs::Vector{Vector{Basic}}, vars::Vector{Basic}, auxvars::Vector{Basic})
    vs = [vars; map(initvar, vars); auxvars]
    R, _ = PolynomialRing(QQ, map(string, vs))
    ideals = [Singular.Ideal(R, map(R, b)) for b in bs]
    @info "" ideals
    len = length(ideals) == 1 ? 1 : length(ideals) * (length(vars) + 1)
    BranchIterator(ideals, map(string, vars), map(string, auxvars), len)
end

nbranches(iter::BranchIterator) = length(iter.bs)

function (R::PolyRing)(x::Expr)
    vs = [:($(Symbol(string(g))) = $g) for g in gens(R)]
    qq = quote
        let $(vs...)
            $x
        end
    end
    eval(qq)
end
(R::PolyRing)(x::Basic) = R(convert(Expr, x))

splitgens(R, lss...) = let sf = Iterators.Stateful(gens(R))
    (collect(Iterators.take(sf, length(ls))) for ls in lss)
end

function stateideal(iter::BranchIterator, I::sideal, state::Int)
    is = [initvar(v, 0) for v in iter.vars]
    ms = [initvar(v, state+1) for v in iter.vars]
    fs = [initvar(v, state+2) for v in iter.vars]
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
    vs = [vars; is]
    R, _ = PolynomialRing(QQ, vs)
    bcount = nbranches(biter)
    I = Singular.Ideal(R)
    T = initial_ideal(vars)
    for (i, (J, elim)) in enumerate(biter)
        @info "Fixed point iterations $i" T J
        S = base_ring(J)
        T = imap(T, S) # map old ideal to new ring via variable name
        T = Singular.eliminate(T + J, elim...)

        if i % bcount == 0
            fs = [initvar(v, i+1) for v in vars]
            RR, _ = PolynomialRing(QQ, [fs; is])
            II = std(fetch(imap(T, RR), R)) # map current ideal to final ring
            @info "Check if ideals are equal" T II I R isequal(I,II)
            if isequal(I, II)
                return I
            end
            I = II
        end
    end
    error("Fixed-point computation failed. Should not happen.")
end