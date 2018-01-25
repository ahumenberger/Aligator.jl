
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
               "Pi"               => :pi,
               "Exp1"             => :e,
               "Infinity"         => :Inf,
               "NegativeInfinity" => :(-Inf),
               "ComplexInfinity"  => :Inf, # error?
               "ImaginaryUnit"    => :im,
               "BooleanTrue"      => :true,
               "BooleanFalse"     => :false
)

map_fn(fn_map, key)   = get(fn_map, key, key)
map_var(var_map, key) = get(var_map, key, key)

function replace_sympy(ex; values=Dict(), fns=Dict())
    fns_map = merge(fn_map, fns)
    vals_map = merge(val_map, values)
    
    fn = funcname(ex)
    
    if fn == "Symbol"
        println(typeof(ex))
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

    Expr(:call, map_fn(fns_map, fn), [replace_sympy(a, values=values) for a in args(ex)]...)
end

function sym2spoly(b::Array{Sym, 1})
    fvars = union(free_symbols.(b)...)
    svars = string.(fvars)
    R, pvars = PolynomialRing(QQ, svars)
    dict = Dict(zip(fvars, pvars))
    basis = [eval(replace_sympy(p, values = dict)) for p in b]
    return R, basis, dict
end

function sym2spoly(p::Sym)
    fvars = free_symbols(p)
    svars = string.(fvars)
    R, pvars = PolynomialRing(QQ, svars)
    dict = Dict(zip(fvars, pvars))
    return R, pvars, eval(replace_sympy(p, values = dict))
end

#-------------------------------------------------------------------------------

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
