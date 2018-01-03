# module Petkovsek

using SymPy

# export algpoly

macro log(var)
    println("$var: ", eval(var))
    return eval(var)
end

function fallingfactorial(x, j)
    result = 1
    for i in 0:j - 1
        result *= (x - i)
    end
    return result
end

function algpoly(polylist, f, n)
    # Construct polynomials qj that arise from treating the shift operator
	# as the difference operator plus the identity operator.
    qlist = []
    for j in 0:length(polylist)-1
        qj = 0 * n
        for i in j:length(polylist)-1
            qj += binomial(i, j) * polylist[i+1]
        end
        push!(qlist, qj)
    end
    
    # Find all candidates for the degree bound on output polynomial.
    b = maximum([(degree(poly, n) - (j - 1)) for (j, poly) in enumerate(qlist)])
    first = degree(f, n) - b
    second = -1 * b - 1
    lc = [LC(Poly(p,n)) for p in qlist]

    alpha = 0 * n
    for j in 0:length(qlist)-1
        if (degree(qlist[j+1], n) - j) == b
            alpha += lc[j+1] * fallingfactorial(n, j)
        end
    end

    deg = polyroots(alpha)
    third = maximum(keys(deg))
    d = max(first, second, third, 0) |> Int64
    # Use method of undetermined coefficients to find the output polynomial.
    varlist = symset("a", d+1)
    pol = 0 * n
    for i in 0:d
        pol += n^i * varlist[i+1]
    end
    solution = -1 * f
    for (i, poly) in enumerate(polylist)
        solution += subs(pol, (n, n + (i-1))) * poly
    end
    coef = coeffs(Poly(solution, n))
    filter!(e->e!=n*0, coef)
    if isempty(coef)
        return Dict([v => v for v in varlist])
    end
    return solve(coef, varlist)
end

function factors(expr)
    c, list = factor_list(expr)
    result = [x^y for (x,y) in list]
    if c != 1
        push!(result, c)
    end
    return result
end

function alghyper(polylist, n)
    p = polylist[1]
    alist = factors(p)
    for (i,p) in enumerate(alist)
        alist[i] /= LC(Poly(p, n))
    end
    if !(1*n^0 in alist)
        push!(alist, 1*n^0)
    end

    d = length(polylist)
    p = subs(polylist[end], (n,n-d+2))
    blist = factors(p)
    for (i,p) in enumerate(blist)
        blist[i] /= LC(Poly(p,n))
    end
    if !(1*n^0 in blist)
        push!(blist, 1*n^0)
    end

    solutions = []
    for aelem in alist
        for belem in blist
            plist = []
            for i in 0:d-1 
                pi = polylist[i+1]
                for j in 0:i-1
                    pi *= subs(aelem, (n, n+j))
                end
                for j in i:d-1
                    pi *= subs(belem, (n, n+j))
                end
                push!(plist, pi)
            end

            m = maximum([degree(Poly(p, n)) for p in plist])
            alpha = [coeff(expand(p), n^m) for p in plist]
            @syms z
            zpol = 0*z
            for i in 0:length(alpha) - 1
                zpol += alpha[i+1]*z^i
            end

            vals = [key for (key,val) in polyroots(zpol) if key != 0]

            for x in vals
                polylist2 = [x^(i-1)*p for (i,p) in enumerate(plist)]
                polysols = algpoly(polylist2, 0*n, n)
                if isempty(polysols)
                    continue
                end
                polysols = collect(values(polysols))
                filter!(e->e!=n*0, polysols)
                if length(polysols) > 0
                    c = 0*n
                    for (i,p) in enumerate(polysols)
                        c += n^(i-1) * p
                    end
                    s = x * aelem/belem * subs(c, (n, n+1))/c
                    push!(solutions, simplify(s))
                end
            end
        end
    end
    return solutions
end

function tohg(sol, n)
    facts = factors(sol)
    result = []
    for f in facts
        if has(f, n)
            f = f |> subs(n, n-1)
            c = coeff(f, n)
            f = f / c
            push!(result, factorial(f))
            if c != 1
                push!(result, c^n)
            end
        else
            push!(result, f^n)
        end
    end
    return prod(result)
end

function hyper()

# end # module

# using SymPy
# using Petkovsek

@syms n y

alghyper([2*n*(n+1), -(n^2 +3*n-2), n-1], n)

# algpoly([3, -n, n-1], 0*n, n)
# algpoly([n-1, -n, 3], 0*n, n)
println("alghyper: ", [tohg(sol, n) for sol in alghyper([2*n*(n+1), -(n^2 +3*n-2), n-1], n)])
println("algpoly: ", algpoly([n*(n + 1), -1*n^2 - 3*n + 2, 2*n - 2], 0*n,n))