# using SymPy

import Base.push!
import Base: push!, isempty, start, next, done, in

# struct AssignPair
#     lhs::Symbol
#     rhs::Union{Symbol, Expr, Int}
# end
abstract type Stmt end

struct AssignPair <: Stmt
    lhs::Symbol
    rhs::Union{Symbol, Expr, Int}
end

function Base.show(io::IO, p::AssignPair)
    print(io, (lhs(p), rhs(p)))
end

# const CompoundStmt = Array{AssignPair,1}

struct CompoundStmt
    pairs::Array{AssignPair,1}
end

assignments(cs::CompoundStmt) = cs.pairs

push!(cs::CompoundStmt, p::AssignPair) = push!(cs.pairs, p)
isempty(cs::CompoundStmt) = isempty(cs.pairs)

CompoundStmt() = CompoundStmt(Array{AssignPair,1}())
CompoundStmt(cs::CompoundStmt...) = CompoundStmt(vcat(assignments.(cs)))

start(x::CompoundStmt) = false
next(x::CompoundStmt, state) = (x, true)
done(x::CompoundStmt, state) = state
in(x::CompoundStmt, y::CompoundStmt) = x == y

function Base.show(io::IO, cs::CompoundStmt)
    print(io, "Compound(")
    for p in cs.pairs
        print(io, p)
    end
    print(io, ")")
end

# const AssignBlock = Array{AssignPair,1}

struct IfStmt <: Stmt
    tbranch
    ebranch
end

exists_else(stmt::IfStmt) = stmt.ebranch != nothing

IfStmt(b) = IfStmt(b, nothing)

else_branch(is::IfStmt) = is.ebranch
then_branch(is::IfStmt) = is.tbranch

struct AssignBlock <:Stmt
    stmts::Array{Union{CompoundStmt,IfStmt},1}
end

stmts(b::AssignBlock) = b.stmts

function Base.show(io::IO, b::IfStmt)
    print(io, "{THEN} ")
    print(io, then_branch(b))
    print(io, " {ELSE} ")
    print(io, else_branch(b))
end

AssignBlock() = AssignBlock(Array{Union{CompoundStmt,IfStmt},1}())

function Base.show(io::IO, b::AssignBlock)
    # print(io, "BLOCK")
    for stmt in b.stmts
        print(io, stmt)
    end
end

push!(b::AssignBlock, stmt::Union{CompoundStmt,IfStmt}) = push!(b.stmts, stmt)

lhs(a::AssignPair) = a.lhs
rhs(a::AssignPair) = a.rhs

variables(a::CompoundStmt) = lhs.(a.pairs)

struct SymbolicAssign
    fn::SymPy.SymFunction # symbolic function for recursively changed variable
    lc::SymPy.Sym         # symbol for loop counter
    lhs::SymPy.Sym
    rhs::SymPy.Sym
end

#-------------------------------------------------------------------------------

function transform(stmt::CompoundStmt, before::CompoundStmt, after::CompoundStmt)
    [before; stmt; after]
end

function transform(stmt::IfStmt, before::CompoundStmt, after::CompoundStmt)
    if exists_else(stmt)
        [transform(then_branch(stmt), before, after), transform(else_branch(stmt), before, after)]
    else
        [transform(then_branch(stmt), before, after), transform(CompoundStmt(), before, after)]
    end
end

function transform(block::AssignBlock, before::CompoundStmt, after::CompoundStmt)
    transform(stmts(block)..., before, after)
end

function transform(c1::CompoundStmt, stmt::IfStmt, before::CompoundStmt, after::CompoundStmt)
    transform(stmt, [before; c1], after)
end

function transform(c1::CompoundStmt, stmt::IfStmt, c2::CompoundStmt, before::CompoundStmt, after::CompoundStmt)
    transform(stmt, [before; c1], [c1; after])
end

function transform(stmt::IfStmt, c2::CompoundStmt, before::CompoundStmt, after::CompoundStmt)
    transform(stmt, before, [c1; after])
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
        return IfStmt([extract_assign(expr.args[i],level+2) for i in 2:length(expr.args)]...)
        # abc = [extract_assign(expr.args[1],level+2), extract_assign(expr.args[2],level+2)]
        # println("Abc: ", abc)
        return IfStmt(abc...)
    elseif h == "block"
        block = AssignBlock()
        cmps = CompoundStmt()
        for arg in expr.args
            stmt = extract_assign(arg, level+2)
            if isa(stmt, AssignPair)
                push!(cmps, stmt)
            elseif isa(stmt, IfStmt)
                if !isempty(cmps)
                    push!(block, cmps)
                end
                cmps = CompoundStmt()
                push!(block, stmt)
            end
        end
        if !isempty(cmps)
            push!(block, cmps)
        end
        return block
    elseif h == "="
        return AssignPair(expr.args[1], expr.args[2])
    end
end

# function flatten(loops)

#     nest = [loops]
#     flat = []
#     while !isempty(nest)
#         nest = nest |> Iterators.flatten |> collect
#         nest = reverse(nest)
#         if isa(nest[1], Dict) && isa(nest[2], Dict)
#             flat = [flat; nest]
#             return flat
#         else            
#             flat = [flat; [pop!(nest)]]
#         end
#     end
#     return flat
# end

#-------------------------------------------------------------------------------

function symbolic(loop::CompoundStmt, lc::Sym, recvars::Array{Sym,1})
    [symbolic(expr, lc, recvars) for expr in assignments(loop)]
end

function symbolic(expr::AssignPair, lc::Sym, recvars::Array{Sym,1})
    fn = SymFunction(string(lhs(expr)))
    return SymbolicAssign(fn, lc, symbolic(lhs(expr), fn, lc+1, recvars), symbolic(rhs(expr), fn, lc, recvars))
end

function symbolic(s::Symbol, f::SymFunction, lc::Sym, recvars::Array{Sym,1})
    if Sym(string(s)) in recvars
        
        f = SymFunction(string(s))
        return f(lc)
    end
    return SymPy.Sym(string(s))
end

function symbolic(i::Int, f::SymFunction, lc::Sym, recvars::Array{Sym,1})
    return Sym(i)
end

function symbolic(expr::Expr, f::SymFunction, lc::Sym, recvars::Array{Sym,1})
    if expr.head == :call && expr.args[1] in (:+, :-, :*, :/, :^)
        return eval(Expr(:call, expr.args[1], symbolic(expr.args[2], f, lc, recvars), symbolic(expr.args[3], f, lc, recvars)))
    else
        error("Not supported rhs in assignment")
    end
end

#-------------------------------------------------------------------------------

function recurrence(expr::SymbolicAssign)
    rec = expr.lhs - expr.rhs
    eq2rec(rec, expr.fn, expr.lc)
end

function eq2rec(eq::Sym, fn::SymFunction, lc::Sym)
    fns = symfunctions(eq)
    w0 = Wild("w0")
    ord = Int(maximum([get(match(fn(lc + w0), f), w0, 0) for f in fns]))
    coeffs = Sym[]
    for i in 0:ord
        c, eq = coeff_rem(eq, fn(lc + i))
        coeffs = [coeffs; c]
    end
    return CFiniteRecurrence(coeffs, fn, lc, eq)
end

#-------------------------------------------------------------------------------

function canonical!(loops::Array{CompoundStmt,1})
    vars = union(variables.(loops)...)
    for i in 1:length(loops)
        vmiss = setdiff(vars, variables(loops[i]))
        if length(vmiss) > 0
            amiss = [AssignPair(v, v) for v in vmiss]
            push!(loops[i], amiss...)
        end
    end
    loops
end

#-------------------------------------------------------------------------------

function flattenall(a::AbstractArray)
    while any(x->typeof(x)<:AbstractArray, a)
        a = collect(Iterators.flatten(a))
    end
    return a
end

function extract_loop(str::String)
    loops = extract_assign(parse(str), 0)
    loops = transform(loops, CompoundStmt(), CompoundStmt())
    loops = flattenall(loops)
    loops = filter(x -> !isempty(x), loops)

    if all(isa.(loops, CompoundStmt))
        loops = canonical!(Array{CompoundStmt,1}(loops))
    else
        error("Something went wrong while flattening the loop.")
    end

    recvars = Sym.(union(variables.(loops)...))

    ls = SingleLoop[]
    for (i, loop) in enumerate(loops)
        lc = Sym("n_$(i)")
        recs = recurrence.(symbolic(loop, lc, recvars))
        loop = SingleLoop(LoopBody(recs), lc, Sym.(string.(variables(loop))))
        push!(ls, loop)
    end
    # recs = [ for (i, loop) in enumerate(loops)]
    # loops = SingleLoop.(LoopBody.(recs))
    if length(ls) == 0
        return EmptyLoop()
    elseif length(ls) == 1
        return ls[1]
    else
        return MultiLoop(ls, ls[1].vars)
    end

    # if isa(loops, AssignBlock)
    #     # single-path loop
    #     loops = [loops]
    # else
    #     # multi-path loop -> flattening needed
    #     loops = Array{AssignBlock,1}(flatten(loops))
    #     canonical!(loops)
    # end
    # println("Loops: ", loops)
    # recs = [recurrence.(symbolic(loop, Sym("n_$(i)"))) for (i, loop) in enumerate(loops)]
    # loops = SingleLoop.(LoopBody.(recs))
    # if length(loops) == 0
    #     return EmptyLoop()
    # elseif length(loops) == 1
    #     return loops[1]
    # else
    #     return MultiLoop(loops)
    # end
end

ml1 = """
    while a != b
        if a > b
            a = a - b
            p = p - q
            r = r - s
        else
            b = b - a
            q = q - p
            s = s - r
        end
    end
"""

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

# extract_loop(ml1)