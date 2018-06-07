abstract type ClosedForm end

mutable struct CFiniteClosedForm <: ClosedForm
    f::SymFunction
    n::Symbolic
    exp::Array{Symbolic}
    coeff::Array{Symbolic}
    expvars::Array{Symbolic}
end

struct HyperClosedForm <: ClosedForm
    exp::Array{Symbolic} # TODO: do exponentials contain loop counter?
    fact::Array{Symbolic}
    coeff::Array{Symbolic}
end

struct ClosedFormSystem
    cforms::Array{ClosedForm,1}
    lc::Symbolic
    vars::Array{Symbolic,1}
end

#-------------------------------------------------------------------------------

CFiniteClosedForm(f::SymFunction, n::Symbolic, exp::Array{Symbolic}, coeff::Array{Symbolic}) = CFiniteClosedForm(f, n, exp, coeff, [])

function shift(cf::CFiniteClosedForm, sh::Symbolic)
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

function rhs(cf::CFiniteClosedForm)
    poly(cf)
end

function subs!(cf::CFiniteClosedForm, x::Pair...)
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

exponentials(cf::ClosedForm) = cf.exp

function expvars!(cf::ClosedForm, d::Dict{Symbolic,Symbolic})
    cf.expvars = replace(cf.exp, d)
end 

function Base.show(io::IO, cf::ClosedForm)
    print(io, "$(cf.f(cf.n)) = $(poly(cf))")
end

# function Base.show(io::IO, cfs::Aligator.ClosedFormSystem)
#     if get(io, :compact, false)
#         show(io, cfs.cforms)
#     else
#         println(io, "$(length(cfs.cforms))-element $(typeof(cfs)):")
#         for cf in cfs.cforms
#             print(io, " ")
#             showcompact(io, cf)
#             print(io, "\n")
#         end
#     end
# end