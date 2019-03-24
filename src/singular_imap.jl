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