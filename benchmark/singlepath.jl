
simpleloop = quote
    while true
        x = 1/2*x
        y = 2y
    end
end

petter(n) = quote
    x, y = 1, 0
    while true
        x = x + y^$n
        y = y + 1
    end
end

cohencu = quote
    while n<=N
        n = n+1
        x = x+y
        y = y+z
        z = z+6
    end
end

freire1 = quote
    while x>r
        x = x-r
        r = r+1
    end
end

freire2 = quote
    while x-s > 0
        x = x-s
        s = s+6*r+3
        r = r+1
    end
end

psolv1s = quote
    k = 0
    t1, t2, a, b, c, d = 1, 1, 1, 1, 1, 1
    while true
        t1 = t2
        t2 = a
        a = 5*(k+2)*t2+6*(k^2+3k + 2)*t1
        b = 2*b
        c = 3*(k+2)*c
        d = (k+2)*d
        k = k+1
    end
end

psolv2s = quote
    t1 = 1; t2 = 1;
    s1 = 1; s2 = 2;
    a = 3; b = 1;
    c = 1; d = 3;
    e = 2; f = 5
    n = 1
    while true
        a = 3*(n+3/2)*a
        s1 = s2; s2 = b
        b = 5*(n+3/2)*s2- 3/2*(1+2*n)*(3+2*n)*s1
        t1 = t2; t2 = d
        d = 4*(4 + n)*t2 - 3*(3 + n)*(4 + n)*t1
        e = (n + 4)*e
        f = 2*f
        c = -3*c + 2
        n = n+1
    end
end

intcbrt = quote
    while true
        x = x-s
        s = s + 6r + 3
        r = r + 1
    end
end

cubes = quote
    c, k, m, n = 0, 1, 6, 0
    while true
        c = c + k
        k = k + m
        m = m + 6
        n = n + 1
    end
end

eucliddiv = quote
    while true
        r = r - y
        q = q + 1
    end
end