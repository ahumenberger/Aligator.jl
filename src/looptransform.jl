function transform(expr::Expr)
    expr = MacroTools.postwalk(x->x isa Expr && x.head == :elseif ? Expr(:if, x.args...) : x, expr)
    branches = _transform(MacroTools.striplines(expr))

    vars = Base.unique(Iterators.flatten(map(free_symbols, branches)))
    for b in branches
        lhss, _ = split_assign(Vector{Expr}(b.args))
        left = setdiff(vars, lhss)
        for v in left
            push!(b.args, :($v = $v))
        end
    end
    branches
end

merge(x::Expr, ys::Vector{Expr}) = [merge(x, y) for y in ys]
merge(xs::Vector{Expr}, y::Expr) = [merge(x, y) for x in xs]
merge(xs::Vector{Expr}, ys::Vector{Expr}) = [merge(x, y) for x in xs for y in ys]
merge(x) = x

function merge(x::Expr, y::Expr)
    @assert x.head == :block && y.head == :block
    Expr(:block, x.args..., y.args...)
end

function _transform(expr)
    res = @match expr begin
        if _ x_ end         => [_transform(x); Expr(:block)]
        if _ x_ else y_ end => [_transform(x); _transform(y)]
        (x_ = y_)           => [block(expr)]
    end
    if res == nothing
        if expr isa Expr && expr.head == :block
            res = merge(reduce(merge, _transform.(expr.args)))
        else
            @error("Unsupported program construct: $expr")
            res = Expr(:block)
        end
    end
    return res
end

function extract_loop(expr::Expr)
    @assert expr.head == :for || expr.head == :while "Not a loop"
    branches = transform(expr.args[2])
    @info "" branches

    ls = SingleLoop[]
    for b in branches
        lc = gensym_unhashed(:n)
        lrs, vars = lrs_sequential(Vector{Expr}(b.args), lc)
        loop = SingleLoop(lrs, sympify(lc), sympify.(vars))
        push!(ls, loop)
    end

    if length(ls) == 0
        return EmptyLoop()
    elseif length(ls) == 1
        return ls[1]
    else
        return MultiLoop(ls, ls[1].vars)
    end
end

# ------------------------------------------------------------------------------

replace_post(ex, s, s′) = MacroTools.postwalk(x -> x == s ? s′ : x, ex)
gensym_unhashed(s::Symbol) = Symbol(Base.replace(string(gensym(s)), "#"=>""))
function free_symbols(ex::Expr)
    ls = Symbol[]
    MacroTools.postwalk(x -> x isa Symbol && Base.isidentifier(x) ? push!(ls, x) : x, ex)
    Base.unique(ls)
end

const RExpr = Union{Expr,Symbol,Number}

function split_assign(xs::Vector{Expr})
    ls = Symbol[]
    rs = RExpr[]
    for x in xs
        @capture(x, l_ = r_)
        push!(ls, unblock(l))
        push!(rs, unblock(r))
    end
    ls, rs
end

function _parallel(lhss::Vector{Symbol}, rhss::Vector{RExpr})
    del = Int[]
    for (i,v) in enumerate(lhss)
        j = findnext(x->x==v, lhss, i+1)
        l = j === nothing ? lastindex(lhss) : j
        for k in i+1:l
            rhss[k] = replace_post(rhss[k], v, rhss[i])
        end
        if j != nothing
            push!(del, i)
        end
    end
    
    if !isempty(del)
        deleteat!(lhss, Tuple(del))
        deleteat!(rhss, Tuple(del))
    end
    lhss, rhss
end

function lrs_sequential(exprs::Vector{Expr}, lc::Symbol = gensym_unhashed(:n))
    lhss, rhss = _parallel(split_assign(exprs)...)
    @debug "Splitted and parallel assignments" rhss lhss
    _lrs_parallel(lhss, rhss, lc)
end


function lrs_parallel(exprs::Vector{Expr}, lc::Symbol = gensym_unhashed(:n))
    lhss, rhss = split_assign(exprs)
    _lrs_parallel(lhss, rhss, lc)
end

function _lrs_parallel(lhss::AbstractVector{Symbol}, rhss::AbstractVector{RExpr}, lc::Symbol)
    # linear = findall(x->_islinear(x, lhss), rhss)
    # nonlinear = setdiff(eachindex(lhss), linear)
    # rest = (view(lhss, nonlinear), view(rhss, nonlinear))
    # _lhss, _rhss = view(lhss, linear), view(rhss, linear)
    _lhss, _rhss = lhss, rhss
    for (i, rhs) in enumerate(_rhss)
        _rhss[i] = MacroTools.postwalk(x -> x isa Symbol && x in _lhss ? :($x($lc)) : x, rhs)
    end
    # _lhss = [Expr(:call, v, Expr(:call, :+, lc, 1)) for v in _lhss]
    recs = Recurrence[]
    for (l,_r) in zip(lhss, _rhss)
        _l = Expr(:call, l, Expr(:call, :+, lc, 1))
        rec = eq2rec(sympify(string(_l))-sympify(string(_r)), SymFunction(string(l)), sympify(lc))
        push!(recs, rec)
    end
    recs, _lhss
end

# ------------------------------------------------------------------------------

function eq2rec(eq::Sym, fn::SymFunction, lc::Sym)
    fns = symfunctions(eq)
    w0 = Wild("w0")
    args = [get(match(fn(lc + w0), f), w0, nothing) for f in fns]
    args = filter(x -> x!=nothing, args)
    minidx = convert(Int, minimum(args))
    if minidx < 0
        eq = eq |> subs(lc, lc - minidx)
    else
        minidx = 0
    end
    ord = convert(Int, maximum(args)) - minidx
    coeffs = Sym[]
    for i in 0:ord
        c, eq = coeff_rem(eq, fn(lc + i))
        coeffs = [coeffs; c]
    end
    return CFiniteRecurrence(coeffs, fn, lc, eq)
end