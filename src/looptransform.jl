function transform(expr::Expr)
    expr = MacroTools.postwalk(x->x isa Expr && x.head == :elseif ? Expr(:if, x.args...) : x, expr)
    branches = _transform(MacroTools.striplines(expr))

    vars = Base.unique(Iterators.flatten(map(Recurrences.free_symbols, branches)))
    for b in branches
        lhss, _ = Recurrences.split_assign(Vector{Expr}(b.args))
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
    if res === nothing
        if expr isa Expr && expr.head == :block
            res = merge(reduce(merge, _transform.(expr.args)))
        else
            @error("Unsupported program construct: $expr")
            res = Expr(:block)
        end
    end
    return res
end

function extract_loops(expr::Expr)
    @assert expr.head == :for || expr.head == :while "Not a loop"
    transform(expr.args[2])
end