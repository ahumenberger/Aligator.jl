
import Singular.PolynomialRing
import Singular.QQ

#-------------------------------------------------------------------------------

funcname(x) = PyCall.PyObject(x)[:func][:__name__]

fn_map = Dict(
              "Add" => :+,
              "Sub" => :-,
              "Mul" => :*,
              "Div" => :/,
              "Pow" => :^
)

val_map = Dict(
               "Zero"             => (0),
               "One"              => (1),
               "NegativeOne"      => (-1),
               "Half"             => QQ(1)//QQ(2),
            #    "Pi"               => :pi,
            #    "Exp1"             => :e,
            #    "Infinity"         => :Inf,
            #    "NegativeInfinity" => :(-Inf),
            #    "ComplexInfinity"  => :Inf, # error?
            #    "ImaginaryUnit"    => :im,
            #    "BooleanTrue"      => :true,
            #    "BooleanFalse"     => :false
)

# map_fn(fn_map, key)   = get(fn_map, key, key)
# map_var(var_map, key) = get(var_map, key, key)

function replace_sympy(ex, vars::Dict)
    fn = funcname(ex)
    
    if fn == "Symbol"
        return get(vars, string(ex), ex)
    elseif fn in ["Integer" , "Float"]
        return N(ex)
    elseif fn == "Rational"
        return QQ(convert(Int, numer(ex)))//QQ(convert(Int, denom(ex)))
    elseif haskey(val_map, fn)
        return val_map[fn]
    end
    error("should not be visited")
    # Expr(:call, map_fn(fns_map, fn), [replace_sympy(a, values=values) for a in args(ex)]...)
end

@syms x y
const ADD = (x+y).func
const MUL = (x*y).func
const POW = (x^y).func

function sym2spoly(b::Array{Sym, 1})
    fvars = union(free_symbols.(b)...)
    svars = string.(fvars)
    R, pvars = PolynomialRing(QQ, svars)
    dict = Dict(zip(string.(fvars), pvars))
    basis = [shallow_replace(p, dict) for p in b]
    basis = eval.(basis)
    return R, basis, dict
end


function shallow_replace(expr::Sym, vars::Dict)
    fn = funcname(expr)
    # println("Function: ", fn==ADD)
    a = [shallow_replace(arg, vars) for arg in expr.args]
    # println("Start: ", expr)
    # println("Start: ", a)
    if fn == "Add"
        return sum(a)
    elseif fn == "Mul"
        return prod(a)
    elseif fn == "Pow"
        return a[1]^a[2]
    end
    return replace_sympy(expr, vars)
end

# function sym2spoly(p::Sym; vars = Sym[])
#     sym2spoly([p], vars=vars)[1]
# end

function sym2spoly(poly::Sym, varmap::Dict)
    # fns_map = merge(fn_map, fns)
    # vals_map = merge(val_map, varmap)
    eval(shallow_replace(poly, varmap))
end

#-------------------------------------------------------------------------------

# function Ideal(basis::Array{Sym, 1}; vars = Sym[])
#     R, sbasis, varmap = sym2spoly(basis, vars)
#     return Singular.Ideal(R, sbasis...), varmap
# end

function Ideal(basis::Array{Sym, 1})
    R, sbasis, varmap = sym2spoly(basis)
    return Singular.Ideal(R, sbasis...), varmap
end

groebner(ideal::Singular.sideal) = std(ideal)

function eliminate(basis::Array{Sym, 1}, elim::Array{Sym, 1})
    ideal, varmap = Ideal(basis)
    vars = [varmap[string(v)] for v in elim]
    return Singular.eliminate(ideal, vars...)
end
