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

abstract type RawProgram end

const RawBody = Dict{Sym, Sym} # couple of assignments

struct RawLoop
    body::Array{Union{RawBody, RawLoop}, 1}
end
struct RawCond
    body::Array{Union{RawBody, RawLoop}, 1}
end

function flatten(loop::RawLoop)
    
end


while true
    s5
    if b1
        s4
    end
    s3
    if b2
        s2
    end
    s1
end

while true
    if b1
        s5
        s4
        s3
    end
    if not b1
        s5
        s3
    end
    while true
        s2
    end
    s1
end