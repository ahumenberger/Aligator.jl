abstract type ClosedForm end

mutable struct CFiniteClosedForm <: ClosedForm
    f::SymFunction
    n::Sym
    exp::Array{Sym}
    coeff::Array{Sym}
    expvars::Array{Sym}
end

struct HyperClosedForm <: ClosedForm
    exp::Array{Sym} # TODO: do exponentials contain loop counter?
    fact::Array{Sym}
    coeff::Array{Sym}
end

#-------------------------------------------------------------------------------

CFiniteClosedForm(f::SymFunction, n::Sym, exp::Array{Sym}, coeff::Array{Sym}) = CFiniteClosedForm(f, n, exp, coeff, [])

function poly(cf::CFiniteClosedForm)
    return sum([ex^cf.n * c for (ex, c) in zip(cf.exp, cf.coeff)])
end

function Base.show(io::IO, cf::CFiniteClosedForm)
    print(io, cf.f(cf.n), " Exp: $(cf.exp) Coeff: $(cf.coeff)\n", sympy["pretty"](poly(cf)), "\n")
end

function polynomial(cf::CFiniteClosedForm) 
    if isempty(cf.expvars)
        return sum(cf.coeff)
    else
        return sum(cf.expvars .* cf.coeff)
    end
    # error("No expvars given. This should not happen.")
end

exponentials(cf::ClosedForm) = cf.exp

function expvars!(cf::ClosedForm, d::Dict{Sym,Sym})
    cf.expvars = replace(cf.exp, d)
end 