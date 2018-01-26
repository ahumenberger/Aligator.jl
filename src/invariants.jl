
abstract type Loop end

const LoopBody = Array{<:Recurrence,1}

type EmptyLoop <: Loop end

struct SingleLoop <: Loop
    body::LoopBody
    # cond::Expr # not used for now
    # init
end

struct MultiLoop <: Loop
    branches::Array{SingleLoop}
    # cond::Expr
    # init
end

Base.length(ideal::Singular.sideal) = ngens(ideal)
Base.start(ideal::Singular.sideal) = 1
Base.next(ideal::Singular.sideal, state) = (ideal[state], state+1)
Base.done(ideal::Singular.sideal, state) = state > ngens(ideal)
Base.eltype(::Singular.sideal) = Singular.spoly

function invariants(loop::MultiLoop)
    error("Multi-path loops are not implemented yet")
end

function invariants(loop::SingleLoop)
    closedforms = [closedform(rec) for rec in loop.body]
    exp = collect(Set(Iterators.flatten([exponentials(cf) for cf in closedforms])))
    println("exp: ", exp)
    expv = symset("v", length(exp))
    dict = Dict(zip(exp, expv))
    println(dict)    
    println("Closed forms: ", closedforms)
    for cf in closedforms
        expvars!(cf, dict)
        println(cf)
    end
    # TODO: handle factorials
    basis = [Sym(string(Sym(cf.f.x))) - init_variables(polynomial(cf), cf.f)[1] for cf in closedforms]

    algdep = dependencies(exp, variables = expv)
    vars = union(free_symbols.(basis)..., expv)
    sideal, varmap = Ideal(basis, vars=vars)

    R = base_ring(sideal)
    basis = [imap(g, R) for g in algdep]
    algdep = Singular.Ideal(R, basis)

    sexpv = [varmap[v] for v in expv]
    return Singular.eliminate(sideal + algdep, prod(sexpv))
end

function init_variables(expr::Sym, f::SymFunction)
    w0   = Wild("w0")
    fns  = Sym.(collect(atoms(expr, AppliedUndef)))
    args = [match(f(w0), fn)[w0] for fn in fns]
    ffns = [f(x) for x in args]
    vars = [Sym("$(string(Sym(f.x)))_$(x)") for x in args]
    dict = Dict(zip(ffns, vars))
    return subs(expr, dict), vars
end