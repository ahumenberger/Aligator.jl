using PyCall

function symset(v::String, j::Int64)
    return [Sym("$v$i") for i in 1:j]
end

unique_var_count = 0

function uniquevar(v="v")
    global unique_var_count += 1
    return Sym(Symbol("$v$unique_var_count"))
end

function replace!{T}(a::Array{T}, d::Dict{T,T})
    for (k, v) in d
        a[a .== k] = v
    end
end

function replace{T}(a::Array{T}, d::Dict{T,T})
    b = copy(a)
    replace!(b, d)
    return b
end

AppliedUndef = PyCall.pyimport_conda("sympy.core.function", "sympy")["AppliedUndef"]

function symfunctions(expr::Sym)
    return Sym.(collect(atoms(expr, AppliedUndef)))
end

# override show for SymPy.SymFunction
function Base.show(io::IO, f::SymPy.SymFunction)
    return show(io, Sym(f.x))
end

function coeff_rem(expr::Sym, t::Sym)
    c = SymPy.coeff(expr, t)
    return c, expr - c*t
end