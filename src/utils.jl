
function symset(v::String, j::Int64)
    return Sym[Sym("$v$i") for i in 1:j]
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
# function Base.show(io::IO, f::SymPy.SymFunction)
#     return show(io, Sym(f.x))
# end

function flattenall(a::AbstractArray)
    while any(x->typeof(x)<:AbstractArray, a)
        a = collect(Iterators.flatten(a))
    end
    return a
end

function coeff_rem(expr::Sym, t::Sym)
    c = SymPy.coeff(expr, t)
    return c, expr - c*t
end

function summands(expr::Sym)
    expr = expand(expr)
    if funcname(expr) == "Add"
        return args(expr)
    end
    Tuple{Sym}(expr)
end

function factors2(expr::Sym)
    expr = expand(expr)
    if funcname(expr) == "Mul"
        return args(expr)
    end
    Tuple{Sym}(expr)
end

function factors_summands(expr::Sym)
    sargs = summands(expr) |> collect
    fargs = flattenall([factors2(arg) |> collect for arg in sargs])
    if sargs == fargs
        return fargs
    end
    flattenall([factors_summands(arg) for arg in fargs])
end

function clear_denom(expr::Sym)
    ls = summands(expr)
    ds = denom.(ls)
    val = lcm2(ds...)
    expr *= val
    simplify(expr)
end

function lcm2(n::Sym, rest::Sym...)
    lcm(n, lcm2(rest...))
end

function lcm2()
    1
end