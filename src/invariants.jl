include("src/recurrence.jl")

abstract type Loop end

const LoopBody = Array{Recurrence}

struct SingleLoop <: Loop
    body::LoopBody
    cond::Expr # not used for now
    init
end

struct MultiLoop <: Loop
    branches::Array{SingleLoop}
    cond::Expr
    init
end

function invariants(loop::SingleLoop)
    closedforms = [closedform(rec) for rec in loop.body]
    exponentials = Set([exponentials(cf) for cf in closedforms])
    expvars = [uniquevar() for _ in exponentials]
    dict = Dict(zip(exponentials, expvars))
    for cf in closedforms
        expvars!(cf, dict)
    end
    # TODO: handle factorials
    ideal = [polynomial(cf) for cf in closedforms]
end

r2 = CFiniteRecurrence([Sym(-2),Sym(1)], f, n)
r2 = CFiniteRecurrence([Sym(-2),Sym(1)], f, n)

const RawBody = Dict{Sym, Sym}

struct RawLoop
    body::Array{Union{RawBody, RawLoop}, 1}
end

function flatten(loop::RawLoop)

end