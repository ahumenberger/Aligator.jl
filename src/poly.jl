
abstract type Poly end

struct UPoly <: Poly
    unknown::Basic
    coeffs::Vector{Basic}
end

function Base.show(io::IO, p::UPoly)
    expr = [p.unknown^(i-1) * c for (i, c) in enumerate(p.coeffs)]
    print(io, sum(expr))
end

function solve_poly_linear(coeffs::Vector{Basic})
    if length(coeffs) != 2
        error("Expected polynomial of degree 1.")
    end
    
    root = coeffs[1] / coeffs[2]
    [root]
end

function solve_poly_quadratic(coeffs::Vector{Basic})
    if length(coeffs) != 3
        error("Expected polynomial of degree 2.")
    end

    a = coeffs[3]
    b = coeffs[2] / a
    c = coeffs[1] / a

    if c == 0
        root1 = -b
        root2 = 0
    elseif b == 0
        root1 = sqrt(-c)
        root2 = -root1
    else
        discriminant = b^2 - 4*c
        lterm = -b / 2
        rterm = sqrt(discriminant) / 2
        root1 = lterm + rterm
        root2 = lterm - rterm
    end

    [root1, root2]
end

function solve_poly_cubic(coeffs::Vector{Basic})
    if length(coeffs) != 4
        error("Expected polynomial of degree 3.")
    end

    a = coeffs[4]
    b = coeffs[3] / a
    c = coeffs[2] / a
    d = coeffs[1] / a

    if d == 0
        root1 = 0
        roots = solve_poly_quadratic([c, b, 1])
        if length(roots) == 2
            root2 = roots[1]
            root3 = roots[2]
        else
            root2 = root3 = roots[1]
        end
    else
        delta0 = b^2 - 3*c
        delta1 = b^3*2 - 9*b*c + 27*d
        delta = (delta0^3*4 - delta1^2) / 27
        if delta == 0
            if delta0 == 0
                root1 = root2 = root3 = -b/3
            else
                root1 = root2 = (9*d - b*c) / 2*delta0
                root3 = (4*b*c - (9*d + b^3)) / delta0
            end
        else
            tmp = sqrt(-27*delta)
            Cexpr = (delta1 + tmp) / 2
            if Cexpr == 0
                Cexpr = (delta1 - tmp) / 2
            end
            C = Cexpr^(1/3)
            root1 = -(b + C + delta0/C) / 3
            coef = 3*I / 2
            tmp = -1/2
            cbrt1 = tmp + coef
            cbrt2 = tmp - coef
            root2 = (b + cbrt1*C + delta0 / cbrt1*C) / -3
            root3 = (b + cbrt2*C + delta0 / cbrt2*C) / -3
        end
    end

    [root1, root2, root3]
end

function solve_poly_quartic(coeffs::Vector{Basic})
    if length(coeffs) != 5
        error("Expected polynomial of degree 4.")
    end

    lc = coeffs[5]
    a = coeffs[4] / lc
    b = coeffs[3] / lc
    c = coeffs[2] / lc
    d = coeffs[1] / lc

    roots = []

    if d == 0
        roots = solve_poly_cubic([c, b, a, 1])
    else
        # substitute x = y-a/4 to get equation of the form y**4 + e*y**2 + f + g = 0
        sqa = a^2
        cba = sqa * a
        aby4 = a / 4
        e = b - 3*sqa/8
        ff = c + cba/8 - a*b/2
        g = (d + sqa*b/16) - (a*c/4 + 3*cba*a/256)

        # two special cases
        if g == 0
            rcubic = solve_poly_cubic([ff, e, 0, 1])
            roots = rcubic .- aby4
            append!(roots, -aby4)
        elseif ff == 0
            rquad = solve_poly_quadratic([g, e, 1])
            for r in rquad
                sqrtr = sqrt(r)
                append!(roots, sqrtr - aby4)
                append!(roots, -sqrtr - aby4)
            end
        else
            # Leonhard Euler's method
            newcoeffs = [
                -ff^2/64,
                (e^2 - 4*g) / 16,
                e/2,
                1
            ]
            rcubic = solve_poly_cubic(newcoeffs)
            p = sqrt(rcubic[1])
            q = sqrt(rcubic[2])
            r = -ff / 8 / p / q
            roots = [
                p + q + r - aby4,
                p - q - r - aby4,
                -p + q - r - aby4,
                -p - q + r - aby4
            ]
        end
    end

    roots
end

function solve_poly_heuristics(coeffs::Vector{Basic})
    degree = length(coeffs) - 1
    if degree == 0
        return []
    elseif degree == 1
        return solve_poly_linear(coeffs)
    elseif degree == 2
        return solve_poly_quadratic(coeffs)
    elseif degree == 3
        return solve_poly_cubic(coeffs)
    elseif degree == 4
        return solve_poly_quartic(coeffs)
    else
        error("Cannot yet handly polynomials with degree > 4")
    end
end

function solve(poly::UPoly)
    solve_poly_heuristics(poly.coeffs)
end