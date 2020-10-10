struct IdMap
    R::AbstractAlgebra.MPolyRing
    map::Dict{Symbol,AbstractAlgebra.MPolyElem}

    function IdMap(R::AbstractAlgebra.MPolyRing)
        vars = gens(R)
        new(R, Dict(zip(map(Symbol ∘ string, vars), vars)))
    end
end

function(m::IdMap)(s::Symbol; force=false)
    !haskey(m.map, s) && force && return zero(m.R)
    m.map[s]
end

(m::IdMap)(s::String; force=false) = m(Symbol(s); force=force)

function(m::IdMap)(p::PolyElem; force=false)
    v = m(var(parent(p)); force=force)
    res = zero(m.R)
    for i in 0:length(p)-1
        c = AbstractAlgebra.coeff(p, i)
        res += m(c; force=force) * v^(i)
    end
    res
end

function(m::IdMap)(p::MPolyElem; force=false)
    vs = [m(s, force=force) for s in AbstractAlgebra.symbols(parent(p))]
    res = zero(m.R)
    for (cc, mm) in zip(AbstractAlgebra.coeffs(p), AbstractAlgebra.monomials(p))
        res += m(cc; force=force) * evaluate(mm, vs)
    end
    res
end

function(m::IdMap)(f::FracElem; force=false)
    m(numerator(f); force=force) // m(denominator(f); force=force)
end

function(m::IdMap)(f::FieldElem; force)
    f
end

function(m::IdMap)(f::RingElem; force)
    f
end

struct IndexMap
    R::AbstractAlgebra.MPolyRing

    function IndexMap(R::AbstractAlgebra.MPolyRing)
        new(R)
    end
end

function(m::IndexMap)(p::MPolyElem; force=false)
    R = parent(p)
    x = length(AbstractAlgebra.symbols(R))
    y = length(AbstractAlgebra.symbols(m.R))

    !force && x != y && error("Number of arguments have to match")
    args = gens(m.R)
    if x > y
        append!(args, zeros(m.R, y-x))
    elseif y > x
        args = args[1:x]
    end
    evaluate(p, args)
end

function(m::Union{IndexMap,IdMap})(I::sideal)
    iszero(I) && return Singular.Ideal(m.R)
    Singular.Ideal(m.R, [m(p; force=true) for p in gens(I)])
end

function imap(I::sideal, R::MPolyRing)
    IdMap(R)(I)
end

function fetch(I::sideal, R::MPolyRing)
    IndexMap(R)(I)
end