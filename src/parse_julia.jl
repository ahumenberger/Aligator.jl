using SymPy

include("utils.jl")
include("recurrence.jl")

#-------------------------------------------------------------------------------

struct ExprAssign
    lhs::Symbol
    rhs::Union{Symbol, Expr, Int}
end

struct SymbolicAssign
    fn::SymPy.SymFunction # symbolic function for recursively changed variable
    lc::SymPy.Sym         # symbol for loop counter
    lhs::SymPy.Sym
    rhs::SymPy.Sym
end

#-------------------------------------------------------------------------------

function extract_assign(expr::Expr, level)
    # println(expr.head)
    h = string(expr.head)
    println(string([" " for i in 1:level]...), "head: ", h)
    if h == "while"
        # ignore guard in expr.args[1]
        return extract_assign(expr.args[2], level+2)
    elseif h == "if"
        # ignore guard in expr.args[1]
        return [extract_assign(expr.args[i],level+2) for i in 2:length(expr.args)]
    elseif h == "block"
        rec = ExprAssign[]
        for arg in expr.args
            rec = [rec; extract_assign(arg, level+2)]
        end
        return rec
    elseif h == "="
        return ExprAssign(expr.args[1], expr.args[2])
    end
    return ExprAssign[]
end

function flatten(loops)
    # println(loops |> )
    # just do some simple flattening
    nest = [loops]
    flat = Array{Array{ExprAssign,1},1}[]
    while !isempty(nest)
        nest = nest |> Iterators.flatten |> collect
        nest = reverse(nest)
        println("Nest: ", nest)
        if isa(nest[1], ExprAssign)
            flat = [flat; [[pop!(nest)]]]
        else            
            flat = [flat; [pop!(nest)]]
        end
    end
    return flat
end

#-------------------------------------------------------------------------------

function symbolic(loop::Array{ExprAssign,1}, lc::Sym)
    return [symbolic(expr, lc) for expr in loop]
end

function symbolic(expr::ExprAssign, lc::Sym)
    fn = SymFunction(string(expr.lhs))
    return SymbolicAssign(fn, lc, symbolic(expr.lhs, fn, lc+1), symbolic(expr.rhs, fn, lc))
end

function symbolic(s::Symbol, f::SymFunction, lc::Sym)
    if string(s) == string(Sym(f.x))
        return f(lc)
    end
    return SymPy.Sym(string(s))
end

function symbolic(i::Int, f::SymFunction, lc::Sym)
    return Sym(i)
end

function symbolic(expr::Expr, f::SymFunction, lc::Sym)
    if expr.head == :call && expr.args[1] in (:+, :-, :*, :/)
        return eval(Expr(:call, expr.args[1], symbolic(expr.args[2], f, lc), symbolic(expr.args[3], f, lc)))
    else
        error("Not supported rhs in assignment")
    end
end

#-------------------------------------------------------------------------------

function recurrence(expr::SymbolicAssign)
    rec = expr.lhs - expr.rhs
    fns = symfunctions(rec)
    w0 = Wild("w0")
    ord = Int(maximum([match(expr.fn(expr.lc + w0), fn)[w0] for fn in fns]))
    coeffs = Sym[]
    for i in 0:ord
        c, rec = coeff_rem(rec, expr.fn(expr.lc + i))
        coeffs = [coeffs; c]
    end
    return CFiniteRecurrence(coeffs, expr.fn, expr.lc, rec)
end

#-------------------------------------------------------------------------------

function aligator(str::String)
    loops = extract_assign(parse(str), 0)
    println("Type: ", typeof(loops))
    if isa(loops, Array{ExprAssign,1})
        # single-path loop
        loops = [loops]
    else
        # multi-path loop -> flattening needed
        loops = Array{Array{ExprAssign,1},1}(flatten(loops))  
    end

    recs = [recurrence.(symbolic(loop, Sym("n_$(i)"))) for (i, loop) in enumerate(loops)]
    return recs
end

#-------------------------------------------------------------------------------

loop = """
    while true
        if y > 1
            x = x + 1
            y = y - 1
            z = 1
            a = b
        elseif t > 1
            x1 = x1 + 1
            y1 = y1 - 1
            z1 = 1
            a1 = b1
        else
            abc = a2
        end
    end
"""

loop2 = """
    while true
        x = 1/2*x + 1
        y = y - 1
        z = 1
        a = b
    end
"""

aligator(loop2)
