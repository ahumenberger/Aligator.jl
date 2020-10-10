const RExpr = Union{Expr,Symbol,Number}

replace_post(ex, s, s′) = MacroTools.postwalk(x -> x == s ? s′ : x, ex)
replace_post(ex, dict) = MacroTools.postwalk(x -> x in keys(dict) ? dict[x] : x, ex)

function free_symbols(ex::Expr)
    ls = Symbol[]
    MacroTools.postwalk(x -> x isa Symbol && Base.isidentifier(x) ? push!(ls, x) : x, ex)
    Base.unique(ls)
end

free_symbols(s::Symbol) = [s]
free_symbols(x) = []

multiplication_walk(f, expr) = MacroTools.prewalk(expr) do x
    if @capture(x, g_(a__)) 
        if g == :*
            f(a)
        elseif g == :^
            f(first(a))
        end
    end
    x
end


function find_multiplications(ex::RExpr)
    ex = convert(Expr, expand(convert(Basic, ex)))
    syms = Symbol[]
    multiplication_walk(ex) do vs
        if vs isa Expr
            append!(syms, free_symbols(vs))
        elseif vs isa Vector
            filter!(x->!isa(x, Number), vs)
            if length(vs) > 1
                for v in vs
                    append!(syms, free_symbols(v))
                end
            end
        elseif vs isa Symbol
            push!(syms, vs)
        else
            error("Something else: $vs")
        end
    end
    Base.unique(syms)
end

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

# function iscounter(l::Symbol, r::RExpr)
#     @match r begin
#         $l + c_ => c isa Number
#         c_ + $l => c isa Number
#         $l - c_ => c isa Number
#         c_ - $l => c isa Number
#         _      => false
#     end
# end

function _parallel(lhss::Vector{Symbol}, rhss::Vector{RExpr})
    del = Int[]
    dict = collect(zip(lhss, rhss))
    for (i,v) in enumerate(lhss)
        rhss[i] = replace_post(rhss[i], Dict(dict[1:i-1]))
    end
    _lhss, _rhss = Symbol[], RExpr[]
    for (l, r) in reverse(collect(zip(lhss, rhss)))
        if l ∉ _lhss
            pushfirst!(_lhss, l)
            pushfirst!(_rhss, r)
        end
    end
    _lhss, _rhss
end

# function lrs_sequential(exprs::Vector{Expr}, lc::Symbol = gensym_unhashed(:n))
#     lhss, rhss = _parallel(split_assign(exprs)...)
#     @debug "Splitted and parallel assignments" rhss lhss
    
#     lines = Expr[]
#     mvars = Symbol[]
#     loop_counters = Symbol[]
#     for (l, r) in zip(lhss, rhss)
#         _mvars = find_multiplications(r)
#         filter!(x->x!=l, _mvars)
#         append!(mvars, _mvars)
#         if iscounter(l, r)
#             push!(loop_counters, l)
#         end
#         _l = Recurrences.symbol_walk(x->:($x($(lc)+1)), l)
#         _r = Recurrences.symbol_walk(x->:($x($(lc))), r)
#         push!(lines, :($(_l) = $(_r)))
#     end
#     Recurrences.lrs(lines)
# end

function __transform_body(expr::Expr)
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

function __extract_init(xs::Vector{Expr})
    m = Dict{Symbol, RExpr}()
    for x in xs
        if @capture(x, l_ = r_)
            m[l] = r
        end
    end
    return m
end

function transform(expr::Expr)
    if @capture(expr, (init__; while _ body_ end))
        __extract_init(Vector{Expr}(init)), __transform_body(body)
    end
end