
const ValueMap = Dict{Symbol,Union{Int,Rational}}
const RExprMap = Dict{Symbol,RExpr}
const ExprVec = Vector{Expr}

function extract(branches::Vector{Expr}, init::ValueMap)
    [__extract_single(ExprVec(b.args), init) for b in branches]
end

# Extract recurrence system from single-path loop
function __extract_single(exprs::Vector{Expr}, init::ValueMap, lc::Symbol = Recurrences.gensym_unhashed(:n))
    lhss, rhss = _parallel(split_assign(exprs)...)
    @debug "Splitted and parallel assignments" rhss lhss
    
    lines = Expr[]
    mvars = Symbol[]
    loop_counters = Dict{Symbol,RExpr}()
    for (l, r) in zip(lhss, rhss)
        _mvars = find_multiplications(r)
        filter!(x->x!=l, _mvars)
        append!(mvars, _mvars)
        cform = __is_loop_counter(l, r, init, lc)
        if !isnothing(cform)
            loop_counters[l] = cform
        end
    end
    # if !isempty(setdiff(mvars, keys(loop_counters)))
    #     @info "" mvars loop_counters
    #     error("Unsupported multiplication between variables")
    # end
    replacelc = !isempty(mvars)
    for (l, r) in zip(lhss, rhss)
        # skip loop counters
        # haskey(loop_counters, l) && continue
        _r = r
        for (v, cform) in loop_counters
            _r = Recurrences.symbol_walk(x->:($x($(lc))), r)
        end
        _l = Recurrences.symbol_walk(x->:($x($(lc)+1)), l)
        _r = Recurrences.symbol_walk(r) do x
            if x != l && haskey(loop_counters, x) && replacelc
                loop_counters[x]
            else
                :($x($(lc)))
            end
        end
        push!(lines, :($(_l) = $(_r)))
    end
    @debug "Lines for rec system creation" lines
    lrs = Recurrences.lrs(lines)
    Recurrences.invertible_system!(lrs)
    cfs = Recurrences.solve(lrs)
    return cfs
end

function __is_loop_counter(l::Symbol, r::RExpr, init::ValueMap, lc::Symbol)
    inc = Basic(r) - Basic(l)
    if isempty(SymEngine.free_symbols(inc)) && haskey(init, l)
        return :($(init[l]) + $(convert(Expr, inc))*($lc))
    end
    return nothing
end