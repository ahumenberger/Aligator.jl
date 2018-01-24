using Singular
using SymPy

import Singular.PolynomialRing
import Singular.QQ

# const Ideal = Singular.sideal

function Ideal(basis::Array{Sym, 1})
    R, sbasis, varmap = sym2spoly(basis)
    return Singular.Ideal(R, sbasis...), varmap
end

groebner(ideal::Singular.sideal) = std(ideal)

function eliminate(basis::Array{Sym, 1}, elim::Array{Sym, 1})
    ideal, varmap = Ideal(basis)
    vars = [varmap[v] for v in elim]
    return Singular.eliminate(ideal, prod(vars))
end

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
               "Pi"               => :pi,
               "Exp1"             => :e,
               "Infinity"         => :Inf,
               "NegativeInfinity" => :(-Inf),
               "ComplexInfinity"  => :Inf, # error?
               "ImaginaryUnit"    => :im,
               "BooleanTrue"      => :true,
               "BooleanFalse"     => :false
)

function walk_expression(ex; values=Dict(), fns=Dict())

    fns_map = merge(fn_map, fns)
    vals_map = merge(val_map, values)
    
    fn = funcname(ex)
    println("funcname: ", fn)
    
    if fn == "Symbol"
        println(typeof(ex))
        return map_var(vals_map, ex)
    elseif fn == "Function"
        return Symbol("v_$(ex)")
    # elseif fn in ["Integer" , "Float"]
    #     return N(ex)
    # elseif fn == "Rational"
    #     return convert(Int, numer(ex))//convert(Int, denom(ex))
    #     ## piecewise requires special treatment
    # elseif fn == "Piecewise"
    #     return _piecewise([walk_expression(cond) for cond in args(ex)]...)
    # elseif fn == "ExprCondPair"
    #     val, cond = args(ex)
    #     return (val, walk_expression(cond))
    # elseif haskey(fns_map, fn)
    #     return fns_map[fn]
    elseif fn in ["Integer" , "Float"]
        return N(ex)
    elseif fn == "Rational"
        return QQ(convert(Int, numer(ex)))//QQ(convert(Int, denom(ex)))
    elseif haskey(vals_map, fn)
        return vals_map[fn]
    else
        println("not treated: ", fn)
    end

    as = args(ex)

    Expr(:call, map_fn(fn, fns_map), [walk_expression(a, values=values) for a in as]...)
end

function sym2spoly(b::Array{Sym, 1})
    fvars = union(free_symbols.(b)...)
    svars = string.(fvars)
    R, pvars = PolynomialRing(QQ, svars)
    dict = Dict(zip(fvars, pvars))
    basis = [eval(walk_expression(p, values = dict)) for p in b]
    return R, basis, dict
end

function sym2spoly(b::Array{Sym, 1}, varmap)
    # fvars = union(free_symbols.(b)...)
    # svars = string.(fvars)
    # R, pvars = PolynomialRing(QQ, svars)
    # dict = Dict(zip(fvars, pvars))
    basis = [eval(walk_expression(p, values = varmap)) for p in b]
    return basis
end

function variables(b::Array{Sym, 1})
    fvars = union(free_symbols.(b)...)
    return fvars
end

function sym2spoly(p::Sym)
    fvars = free_symbols(p)
    svars = string.(fvars)
    R, pvars = PolynomialRing(QQ, svars)
    dict = Dict(zip(fvars, pvars))
    return R, pvars, eval(walk_expression(p, values = dict))
end

map_fn(key, fn_map) = haskey(fn_map, key) ? fn_map[key] : Symbol(key)
map_var(varmap, key) = get(varmap, key, key)

@syms x y z
expr = x + y * z

b = [x+y, x*2z, z^2-y]

# R, vars = PolynomialRing(QQ, ["x1", "y1", "z1"])

# d = Dict(x => vars[1],y => vars[2],z => vars[3])

function replace_initial_values(ex, funcs)

    # fns_map = merge(fn_map, fns)
    # vals_map = merge(val_map, values)
    
    fn = funcname(ex)
    println("funcname: ", fn, " | ", funcs)
    println(typeof(fn))
    
    as = args(ex)

    if in(fn, funcs)
        println("Asdjfklasdjflkasjdfk")
        x = Symbol("x$(args(ex)[1])")
        return x
    elseif fn == "Symbol"
        return Symbol(ex)
    # elseif fn == "Function"
        
    # elseif fn in ["Integer" , "Float"]
    #     return N(ex)
    # elseif fn == "Rational"
    #     return convert(Int, numer(ex))//convert(Int, denom(ex))
    #     ## piecewise requires special treatment
    # elseif fn == "Piecewise"
    #     return _piecewise([walk_expression(cond) for cond in args(ex)]...)
    # elseif fn == "ExprCondPair"
    #     val, cond = args(ex)
    #     return (val, walk_expression(cond))
    # elseif haskey(fns_map, fn)
    #     return fns_map[fn]
    # elseif fn in ["Integer" , "Float"]
    #     return N(ex)
    # elseif fn == "Rational"
    #     return QQ(convert(Int, numer(ex)))//QQ(convert(Int, denom(ex)))
    # elseif haskey(vals_map, fn)
    #     return vals_map[fn]
    # else
    #     println("not treated: ", fn)
    elseif haskey(val_map, fn)
        return val_map[fn]
    end

    

    Expr(:call, map_fn(fn, fn_map), [replace_initial_values(a, funcs) for a in as]...)
end