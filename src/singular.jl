function imap(I::sideal, R::Singular.PolyRing)
    basis = [Singular.imap(g, R) for g in I]
    if isempty(basis)
        return Singular.Ideal(R)
    end
    Singular.Ideal(R, basis)
end
 
function fetch(I::sideal, R::Singular.PolyRing)
    basis = [Singular.fetch(g, R) for g in I]
    if isempty(basis)
        return Singular.Ideal(R)
    end
    Singular.Ideal(R, basis)
end

Base.length(ideal::Singular.sideal) = ngens(ideal)
Base.iterate(ideal::Singular.sideal) = ngens(ideal) > 0 ? (ideal[1], 1) : nothing
Base.iterate(ideal::Singular.sideal, state) = state < ngens(ideal) ? (ideal[state+1], state+1) : nothing
Base.eltype(::Singular.sideal) = Singular.spoly

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