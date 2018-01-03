function symset(v::String, j::Int64)
    return [Sym("$v$i") for i in 1:j]
end

unique_var_count = 0

function uniquevar(v="v")
    global unique_var_count += 1
    return Sym(Symbol("$v$unique_var_count"))
end

function replace!{T}(a::Array{T}, d::Dict{T,T})
    for (k, v) in d
        a[a .== k] = v
    end
end

function replace{T}(a::Array{T}, d::Dict{T,T})
    b = copy(a)
    replace!(b, d)
    return b
end