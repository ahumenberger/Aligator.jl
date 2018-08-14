abstract type ClosedForm end

mutable struct CFiniteClosedForm <: ClosedForm
    f::SymFunction
    n::Sym
    exp::Array{Sym}
    coeff::Array{Sym}
    expvars::Array{Sym}
end

mutable struct HyperGeomClosedForm <: ClosedForm
    f::SymFunction
    n::Sym
    exp::Vector{Vector{Sym}}  # contains b for b^n
    fact::Vector{Vector{Sym}} # contains b for factorial(n+b)
    coeff::Vector{Sym}
    expvars::Vector{Vector{Sym}}
    factvars::Vector{Vector{Sym}}
end

struct ClosedFormSystem
    cforms::Array{ClosedForm,1}
    lc::Sym
    vars::Array{Sym,1}
end

#-------------------------------------------------------------------------------

CFiniteClosedForm(f::SymFunction, n::Sym, exp::Array{Sym}, coeff::Array{Sym}) = CFiniteClosedForm(f, n, exp, coeff, [])
HyperGeomClosedForm(f::SymFunction, n::Sym, exp::Vector{Vector{Sym}}, fact::Vector{Vector{Sym}}, coeff::Vector{Sym}) = HyperGeomClosedForm(f, n, exp, fact, coeff, [], [])

function shift(cf::CFiniteClosedForm, sh::Sym)
    coeff = copy(cf.coeff)
    for i in 1:length(cf.exp)
        coeff[i] = coeff[i] |> subs(cf.n, cf.n+sh)
        coeff[i] *= cf.exp[i]^sh
    end
    CFiniteClosedForm(cf.f, cf.n, cf.exp, coeff, cf.expvars)
end

function poly(cf::CFiniteClosedForm)
    return sum([ex^cf.n * c for (ex, c) in zip(cf.exp, cf.coeff)])
end

function poly(cf::HyperGeomClosedForm)
    return sum([prod(e .^ cf.n)*prod(factorial.(f .+ cf.n))*c for (e, f, c) in zip(cf.exp, cf.fact, cf.coeff)])
end

function rhs(cf::ClosedForm)
    poly(cf)
end

function subs!(cf::CFiniteClosedForm, x::Pair...)
    if !isempty(x)
        cf.coeff = [c |> subs(x...) for c in cf.coeff]
    end
    cf
end

function subs!(cf::ClosedForm, x::Pair...)
    if !isempty(x)
        cf.coeff = [c |> subs(x...) for c in cf.coeff]
    end
    cf
end

function polynomial(cf::CFiniteClosedForm) 
    if isempty(cf.expvars)
        return sum(cf.coeff)
    else
        return sum(cf.expvars .* cf.coeff)
    end
    # error("No expvars given. This should not happen.")
end

function polynomial(cf::HyperGeomClosedForm) 
    return sum([prod(e .^ cf.n)*prod(factorial.(f .+ cf.n))*c for (e, f, c) in zip(cf.expvars, cf.factvars, cf.coeff)])
end

exponentials(cf::ClosedForm) = flattenall(cf.exp)

function expvars!(cf::ClosedForm, d::Dict{Sym,Sym})
    cf.expvars = replace(cf.exp, d)
end

factorials(cf::HyperGeomClosedForm) = flattenall(cf.fact)
factorials(cf::CFiniteClosedForm) = Vector{Sym}([])

function factvars!(cf::HyperGeomClosedForm, d::Dict{Sym,Sym})
    cf.factvars = replace(cf.fact, d)
end
function factvars!(cf::CFiniteClosedForm, d::Dict{Sym,Sym})
end

function Base.show(io::IO, cf::ClosedForm)
    print(io, "$(cf.f(cf.n)) = $(poly(cf))")
end

function Base.show(io::IO, cfs::Aligator.ClosedFormSystem)
    if get(io, :compact, false)
        show(io, cfs.cforms)
    else
        println(io, "$(length(cfs.cforms))-element $(typeof(cfs)):")
        for cf in cfs.cforms
            print(io, " ")
            showcompact(io, cf)
            print(io, "\n")
        end
    end
end