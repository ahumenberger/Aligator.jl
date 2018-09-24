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
LinearRecSystem(n::T, vars::Vector{T}, mat::Matrix{T}, inhom::Vector{T}) where T = LinearRecSystem(n, vars, [mat], inhom) 
LinearRecSystem(n::T, vars::Vector{T}, mat::Matrix{T}) where T = LinearRecSystem(n, vars, [mat]) 

order(::LinearRecSystem{T,N}) where {T,N} = N

"Transform the LRS `s` of arbitrary order into a system of order 1."
function firstorder(s::LinearRecSystem{T,O}) where {T,O}
    if O == 1
        return s
    end

    n = size(s.mat[1], 1)
    l = length(s.mat)
    vars = [unique(T, (O-1)*n); s.vars]
    Z = zeros(T, (O-1)*n, n)
    I = eye(T, (O-1)*n)
    M = hcat(Z,I)
    N = hcat(s.mat...)
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

"Uncouple the LRS by using Zürchers algorithm."
function uncouple(s::LinearRecSystem{T,1}) where T
    s = homogenize(s)
    σ = x -> x |> subs(s.n, s.n+1)
    σinv = x -> x |> subs(s.n, s.n+1)
    δ = x -> σ(x) - x
    C, A = rational_form(copy(s.mat[1]), σ, σinv, δ)
    println("A")
    display(A)
    # display(inv(A))
    # display(s.mat[1])
    println("something")
    display(inv(A)*s.mat[1]*A)
    LinearRecSystem(s.n, s.vars, C)
end

iseye(m::Matrix) = iszero(m - eye(m))

isuncoupled(lrs::LinearRecSystem) = all([iseye(m) for m in lrs.mat])

"Get the recurrence corresponding to the index `i."
function get(l::LinearRecSystem{T}, i::Int) where T

end

"Get the recurrence corresponding to variable `var`."
get(l::LinearRecSystem{T}, var::T) where T = get(l, findfirst(x -> x == var, l.vars))

# "Get closed forms of recurrences corresponding to variables in `vars`."
# function solve(s::LinearRecSystem{T}, vars::Vector{T}) where T
    
# end

# "Compute all closed forms."
# solve(s::LinearRecSystem{T}) = solve(s, s.vars)

@syms r v n

# lrs = LinearRecSystem(n, [r, v], Sym[1 -1; 0 1], Sym[0, 2])
# lrs = LinearRecSystem(n, [r], [hcat(Sym(1)), hcat(Sym(1)),hcat(Sym(1))], Sym[0])
# lrs = LinearRecSystem(n, [r, v], Sym[1 1; 1 2])
# display(order(lrs))

@syms x i j y

A = Sym[2 1 0 1; 0 1 0 0; 2 1 1 1; 0 0 0 1]
v = Sym[0, 1, 0, 0]
vars = [x, i, j, y]
lrs = LinearRecSystem(n, vars, A, v)
display(lrs)

# lrs = LinearRecSystem(n, [r], hcat(Sym(1)))
# display(order(lrs))
# typeof(lrs)
lrs = firstorder(lrs)
display(lrs)

lrs = homogenize(lrs)
display(lrs.mat[1])

lrs = uncouple(lrs)
display(lrs.mat[1])

# uncouple(lrs)
# display(lrs)

"Compute thetas; coeffs are given in decreasing order"
function closedform(coeffs::Vector{T}, n::T) where T
    # println("Original: ", orig)
    # r = homogeneous(orig)
    # # println("Homogeneous: ", r)
    
    # shift = order(r) - order(orig)
    # rh = rhs(orig)
    # ord = order(orig)
    # init = Dict{Sym,Sym}([(orig.f(i), rh |> SymPy.replace(orig.n, i-ord)) for i in ord:shift+ord-1])
    # # init = rewrite(init)

    # rel = relation(r)
    # # println("Homogeneous: ", homogeneous(r))
    # w0  = Wild("w0")

    order = length(coeffs)
    lbd = unique(T)
    cpoly = sum([c*lbd^i-1 for (i, c) in enumerate(reverse(coeffs))])
    # println("CPoly: ", cpoly |> simplify)
    # factors = factor_list(cpoly)
    roots   = polyroots(cpoly)
    unknowns = T[]
    store_unique() = (v = unique(T); push!(unknowns, v); v)
    ansatz = sum([sum([store_unique() * n^i * z^n for i in 0:m - 1]) for (z, m) in roots])

    display(unknowns)
    system = [Eq(unique(T), ansatz |> subs(n, i)) for i in 0:order - 1]
    sol = solve(system, unknowns)
    display(system)
    sol = ansatz |> subs(sol)
    display(sol)
    # if !isempty(init)
    #     tmp = nothing
    #     while true
    #         tmp = (sol |> subs(init)) |> simplify
    #         if tmp == sol
    #             break
    #         end
    #         sol = tmp
            
    #     end
    #     sol = simplify(tmp)
    # end
    
    # exp = [z for (z, _) in roots]
    # exp = filter(x -> x!=Sym(1), exp)
    # push!(exp, Sym(1))
    # coeff = exp_coeffs(sol, [z^r.n for z in exp])
    # return CFiniteClosedForm(r.f, r.n, exp, coeff)
end

# closedform(Sym[1,2], n)

# x = 1;y = 1;for i in 1:10
#     x = x + y
#     y = y + x
#     # println("x = $x")
#     println("y = $y")
# end

# function evalrec(coeffs, ivals, n)
#     order = length(ivals)
#     vals = ivals
#     coeffs = reverse(coeffs)
#     for i in order:n
#         val = sum(coeffs .* vals[end-order+1:end])
#         append!(vals, val)
#     end

#     display(vals)
# end

# x' = x + y
# y' = y + x' = y + x + y
