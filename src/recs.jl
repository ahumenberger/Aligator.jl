include("zuercher.jl")

using SymPy

struct LinearRecSystem{T,N}
    n::T
    vars::Vector{T}
    mat::Vector{Matrix{T}} # it's a vector in order to model higher order recurrences
    inhom::Vector{T}

    LinearRecSystem{T,N}(n::T, vars::Vector{T}, mat::Vector{Matrix{T}}, inhom::Vector{T}) where {T,N} = N == length(mat) ? new{T,N}(n, vars, mat, inhom) : error("Order mismatch (expected $N, got $(length(mat)))")
end

LinearRecSystem(n::T, vars::Vector{T}, mat::Vector{Matrix{T}}, inhom::Vector{T}) where T = LinearRecSystem{T,length(mat)}(n, vars, mat, inhom) 
LinearRecSystem(n::T, vars::Vector{T}, mat::Vector{Matrix{T}}) where T = LinearRecSystem(n, vars, mat, zeros(T, length(vars))) 
LinearRecSystem(n::T, vars::Vector{T}, mat::Matrix{T}) where T = LinearRecSystem(n, vars, [mat]) 

order(::LinearRecSystem{T,N}) where {T,N} = N

function firstorder(s::LinearRecSystem{T,O}) where {T,O}
    if O == 1
        return s
    end

    n = size(s.mat[1], 1)
    l = length(s.mat)
    vars = [unique(T, (O-1)*n); s.vars]
    Z = zeros(T, (O-1)*n, n)
    I = eye(T, (O-1)*n)
    display(Z)
    display(I)
    M = hcat(Z,I)
    N = hcat(s.mat...)
    display(M)
    display(N)
    mat = vcat(M, N)
    LinearRecSystem(s.n, vars, mat)
end

var_count = 0

function unique(::Type{Sym}, n::Int = 1)
    global var_count += n
    if n == 1
        return Sym("v$var_count")
    end
    return [Sym("v$i") for i in var_count-n+1:var_count]
end

function homogenize(s::LinearRecSystem{T,1}) where T
    if iszero(s.inhom)
        return s
    end
    vars = [s.vars; unique(T)]
    mat = hcat(s.mat[1], s.inhom)
    n = length(vars)
    mat = vcat(mat, zeros(T, 1, n))
    mat[n,n] = 1
    LinearRecSystem(s.n, vars, mat)
end

# ishomog(s::LinearRecSystem) = iszero(s.inhom)

# recvar(rec::Sym, var::Sym, idx::Int) = SymFunction(string(rec))(var + idx)

# # σ_rec(x) = x |> subs(n, n+1)
# # σ_rec_inv(x) = x |> subs(n, n-1)

# # δ(x) = σ_rec(x) - x

function uncouple(s::LinearRecSystem{T,1}) where T
    s = homogenize(s)
    σ = x -> x |> subs(s.n, s.n+1)
    σinv = x -> x |> subs(s.n, s.n+1)
    δ = x -> σ(x) - x
    C, _ = rational_form(s.mat[1], σ, σinv, δ)
    LinearRecSystem(s.n, s.vars, C)
end

# function solve(s::LinearRecSystem{T}) where T
#     # ensure that s.mat is a companion matrix
    
# end

@syms r v n

# lrs = LinearRecSystem(n, [r, v], Rational[1 -1; 0 1], Sym[0, 2])
lrs = LinearRecSystem(n, [r], [hcat(Sym(1)), hcat(Sym(1)),hcat(Sym(1))], Sym[0])
display(order(lrs))
# lrs = LinearRecSystem(n, [r], hcat(Sym(1)))
# display(order(lrs))
# typeof(lrs)
lrs = firstorder(lrs)
lrs = homogenize(lrs)
uncouple(lrs)
# uncouple(lrs)
# display(lrs)