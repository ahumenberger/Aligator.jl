
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
               "Zero"             => :(0),
               "One"              => :(1),
               "NegativeOne"      => :(-1),
               "Half"             => :(1/2),
            #    "Pi"               => :pi,
            #    "Exp1"             => :e,
            #    "Infinity"         => :Inf,
            #    "NegativeInfinity" => :(-Inf),
            #    "ComplexInfinity"  => :Inf, # error?
            #    "ImaginaryUnit"    => :im,
            #    "BooleanTrue"      => :true,
            #    "BooleanFalse"     => :false
)

map_fn(fn_map, key)   = get(fn_map, key, key)
map_var(var_map, key) = get(var_map, key, key)

function replace_sympy(ex; values=Dict(), fns=Dict())
    fns_map = merge(fn_map, fns)
    vals_map = merge(val_map, values)
    
    fn = funcname(ex)
    
    if fn == "Symbol"
        # println(typeof(ex))
        return map_var(vals_map, ex)
    elseif fn == "Function"
        return Symbol("v_$(ex)")
    elseif fn in ["Integer" , "Float"]
        return N(ex)
    elseif fn == "Rational"
        return QQ(convert(Int, numer(ex)))//QQ(convert(Int, denom(ex)))
    elseif haskey(vals_map, fn)
        return vals_map[fn]
    end

    error("should not be visited")
    Expr(:call, map_fn(fns_map, fn), [replace_sympy(a, values=values) for a in args(ex)]...)
end

@syms x y
const ADD = func(x+y)
const MUL = func(x*y)
const POW = func(x^y)

function sym2spoly(b::Array{Sym, 1}; vars = Sym[])
    fvars = union(free_symbols.(b)..., vars)
    svars = string.(fvars)
    R, pvars = PolynomialRing(QQ, svars)
    dict = Dict(zip(fvars, pvars))
    println("+++++ replace: ", b)
    basis = @time [shallow_replace(p, values = dict) for p in b]
    println("+++++ eval")
    basis = @time eval.(basis)
    return R, basis, dict
end

function shallow_replace(expr::Sym; values = Dict())
    fn = func(expr)
    # println("Function: ", fn==ADD)
    a = [shallow_replace(arg, values=values) for arg in args(expr)]
    # println("Start: ", expr)
    println("Result: ", a)
    println("Result: ", typeof.(a))
    println("Map: ", values)
    if fn == ADD
        return sum(a)
    elseif fn == MUL
        return prod(a)
    elseif fn == POW
        return a[1]^a[2]
    end
    return replace_sympy(expr, values=values)
end

function sym2spoly(p::Sym; vars = Sym[])
    sym2spoly([p], vars=vars)[1]
end

function sym2spoly(poly::Sym, varmap::Dict)
    eval(shallow_replace(poly, values = varmap))
end

#-------------------------------------------------------------------------------

function Ideal(basis::Array{Sym, 1}; vars = Sym[])
    R, sbasis, varmap = sym2spoly(basis, vars=vars)
    return Singular.Ideal(R, sbasis...), varmap
end

groebner(ideal::Singular.sideal) = std(ideal)

function eliminate(basis::Array{Sym, 1}, elim::Array{Sym, 1})
    ideal, varmap = Ideal(basis)
    vars = [varmap[v] for v in elim]
    return Singular.eliminate(ideal, prod(vars))
end
