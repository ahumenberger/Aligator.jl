
abstract type Loop end

const LoopBody = Vector{<:Recurrence}

struct EmptyLoop <: Loop end

struct SingleLoop <: Loop
    body::LoopBody
    lc::Sym
    vars::Array{Sym,1}
end

struct MultiLoop <: Loop
    branches::Array{SingleLoop}
    vars::Array{Sym,1}
end

#-------------------------------------------------------------------------------

function Base.show(io::IO, body::LoopBody)
    print(io, "[")
    join(io, body, ", ")
    println(io, "]")
end

function Base.show(io::IO, loop::SingleLoop)
    if get(io, :compact, false)
        Base.show(io, loop.body)
    else
        println(io, "$(length(loop.body))-element $(typeof(loop)):")
        for l in loop.body
            print(io, "  $(l)\n")
        end
    end
end

function Base.show(io::IO, loop::MultiLoop)
    println(io, "$(length(loop.branches))-element $(typeof(loop)):")
    for l in loop.branches
        print(io, " ")
        showcompact(io, l)
        # print(io, "\n")
    end
end

function closed_forms(loop::MultiLoop)
    [ClosedFormSystem(rec_solve(l.body), l.lc, l.vars) for l in loop.branches]
end

function closed_forms(loop::SingleLoop)
    ClosedFormSystem(rec_solve(loop.body), loop.lc, loop.vars)
end
