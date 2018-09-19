
function rational_form{S}(T::Matrix{S}, σ, σ_inv, δ)
    n = size(T)[1]
    i0 = 1
    i = 1
    B = eye(S, n)
    while i < n
        j = i + 1
        while j <= n && T[i,j] == 0
            j = j + 1
        end
        if j <= n
            transform_lemma2(T, i0, i, j, σ, σ_inv, δ, B)
            i = i + 1
        else
            transform_lemma3(T, i0, i, σ, δ, B)
            i1 = i + 1
            while i1 <= n && T[i1,i0] == 0
                i1 = i1 + 1
            end
            if i1 <= n
                transform_lemma5(T, i0, i, i1, σ, σ_inv, δ, B)
                i = i + 1
            else
                i = i + 1
                i0 = i
            end
        end
    end
    return T, B
end

function transformP{S}(T::Matrix{S}, i0::Int, i::Int, k::Int, B::Matrix{S})
    n = size(T)[1]
    for j in i0:n
        T[j,i], T[j,k] = T[j,k], T[j,i]
        B[j,i], B[j,k] = B[j,k], B[j,i]
    end
    for j in i0:n
        T[i,j], T[k,j] = T[k,j], T[i,j]
    end
    return T, B
end

function transformR{S}(T::Matrix{S}, i0::Int, B::Matrix{S})
    n = size(T)[1]
    c = zeros(S, n)
    for i in i0:n
        c[i] = T[i,n]
    end
    for i in i0:n
        for j in n:-1:i0+1
            T[i,j] = T[i,j-1]
        end
    end
    for i in i0:n
        T[i,i0] = c[i]
    end

    for i in i0:n
        c[i] = T[n,i]
    end
    for j in i0:n
        for i in n:-1:i0+1
            T[i,j] = T[i-1,j]
        end
    end
    for i in i0:n
        T[i0,i] = c[i]
    end

    for i in i0:n
        c[i] = B[i,n]
    end
    for j in n:-1:i0+1
        for i in i0:n
            B[i,j] = B[i,j-1]
        end
    end
    for i in i0:n
        B[i,i0] = c[i]
    end
    return T, B
end

function transform_lemma2{S}(T::Matrix{S}, i0::Int, i::Int, l::Int, σ, σ_inv, δ, B::Matrix{S})
    n = size(T)[1]
    T, B = transformP(T, i0, i+1, l, B)
    a = σ_inv(1/T[i,i+1])
    for j in i:n
        T[j,i+1] = T[j,i+1] * σ(a) # D1
    end
    for j in i0:n
        T[i+1,j] = T[i+1,j] / a # D2
    end
    T[i+1,i+1] = T[i+1,i+1] + δ(a) / a # D3
    for j in i0:n
        B[j,i+1] = B[j,i+1] * a # basis change
    end

    for k in i0:i
        a = σ_inv(-T[i,k])
        for j in i:n
            T[j,k] = T[j,k] + σ(a) * T[j,i+1] # C1
        end
        if k < i
            T[i+1,k+1] = T[i+1,k+1] - a # C2
        else
            for j in i:n
                T[i+1,j] = T[i+1,j] - a * T[i,j]
            end
        end
        T[i+1,k] = T[i+1,k] + δ(a) # C3
        for j in i0:n
            B[j,k] = B[j,k] + a * B[j,i+1] # basis change
        end
    end

    for k = i+2:n
        a = σ_inv(-T[i,k])
        for j in i:n
            T[j,k] = T[j,k] + σ(a) * T[j,i+1] # C1
        end
        for j in i0:n
            T[i+1,j] = T[i+1,j] - a * T[k,j] # C2
        end
        T[i+1,k] = T[i+1,k] + δ(a) # C3
        for j in i0:n
            B[j,k] = B[j,k] + a * B[j,i+1] # basis change
        end
    end
    return T, B
end

function transform_lemma3{S}(T::Matrix{S}, i0::Int, i::Int, σ, δ, B::Matrix{S})
    n = size(T)[1]
    for l in i:-1:i0+1
        for k in i+1:n
            a = T[k,l]
            for j in i+1:n
                T[j,l-1] = T[j,l-1] + σ(a) * T[j,k] # C1
            end
            T[k,l] = 0 # C2
            T[k,l-1] = T[k,l-1] + δ(a) # C3
            for j in i0:n
                B[j,l-1] = B[j,l-1] + a * B[j,k]
            end
        end
    end
    return T, B
end

function transform_lemma4{S}(T::Matrix{S}, i0::Int, i::Int, k::Int, σ, σ_inv, δ, B::Matrix{S})
    n = size(T)[1]
    for l in i0:k
        a = σ_inv(-T[k,l])
        T[k,l] = 0 # C1
        T[k+1,l] = T[k+1,l] + σ(a) * T[k+1,k+1]
        if k < i
            T[i+1,l] = T[i+1,l] + σ(a) * T[i+1,k+1]
        end
        if l < k
            T[k+1,l+1] = T[k+1,l+1] - a # C2
        else
            for j in i0:k+1
                T[k+1,j] = T[k+1,j] - a * T[k,j]
            end
            for j in i+2:n
                T[k+1,j] = T[k+1,j] - a * T[k,j]
            end
        end
        T[k+1,l] = T[k+1,l] + δ(a) # C3
        for j in i0:n
            B[j,l] = B[j,l] + a * B[j,k+1] # basis change
        end
    end

    for l in i+2:n
        a = σ_inv(-T[k,l])
        T[k,l] = 0 # C1
        T[k+1,l] = T[k+1,l] + σ(a) * T[i+1,k+1]
        if k < i
            T[i+1,l] = T[i+1,l] + σ(a) * T[i+1,k+1]
        end
        T[k+1,i0] = T[k+1,i0] - a * T[l,i0] # C2
        for j in i+2:n
            T[k+1,j] += a * T[l,j]
        end
        T[k+1,l] += δ(a) # C3
        for j in i0:n
            B[j,l] += a * B[j,k+1] # basis change
        end
    end
    return T, B
end

function transform_lemma5{S}(T::Matrix{S}, i0::Int, i::Int, k::Int, σ, σ_inv, δ, B::Matrix{S})
    n = size(T)[1]
    T, B = transformP(T, i0, k, n, B)

    a = T[n,i0]
    for j in i+1:n
        T[j,n] *= σ(a) # D1
    end
    T[n,i0] = 1 # D2
    for j in i+1:n
        T[n,j] /= a
    end
    T[n,n] += δ(a) / a # D3
    for j in i0:n
        B[j,n] *= a # basis change
    end

    for l in i+1:n
        if T[l,i0] != 0
            a = T[l,i0]
            for j in i+1:n
                T[j,n] += σ(a) * T[j,l] # C1
            end
            T[l,i0] -= a # C2
            for j in i+1:n
                T[l,j] -= a * T[n,j]
            end
            T[l,n] += δ(a) # C3
            for j in i0:n
                B[j,n] += a * B[j,l] # basis change
            end
        end
    end

    T, B = transformR(T, i0, B)
    for j in i0:i
        T, B = transform_lemma4(T, i0, i, j, σ, σ_inv, δ, B)
    end
    
    return T, B
end

# @syms n



# A0 = Rational{Int}[1 -1 0; 0 1 2; 0 0 1]
# A = copy(A0)

# @syms n

# AA = Sym[1 0 1; n 1 0; 0 0 1]

# # T = A - eye(size(A)[1])

# # eigvecs(A)

# # println(A)
# # println(T)

# T, B = rational_form(AA, σ_rec, σ_rec_inv, δ)
# display(T)
# display(B)
# T, B = rational_form(A0, σ_rec, σ_rec_inv, δ)

# # println(A0)
# display(T)
# display(B)

