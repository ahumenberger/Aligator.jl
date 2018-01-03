struct LoopBody
    recs::Array{Recurrence}
end

struct Loop
    body::LoopBody
    cond::Expr # not used for now
    init
end
