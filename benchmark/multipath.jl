
euclidex = quote
    while a != b
        if a > b
            a = a - b
            p = p - q
            r = r - s
        else
            q = q - p
            b = b - a
            s = s - r
        end
    end
end

fermat = quote
    while r != 0
        if r > 0
            r = r - v
            v = v + 2
        else
            r = r + u
            u = u + 2
        end
    end
end

wensley = quote
    while d>= E
        if P < a+b
            b = b/2
            d = d/2
        else
            a = a+b
            y = y+d/2
            b = b/2
            d = d/2
        end
    end
end

lcm = quote
    while x != y
        if x > y
            x = x - y
            v = v + u
        else
            y = y - x
            u = u + v
        end
    end
end

knuth = quote
    while (s >= d) && (r != 0)
        if 2*r-rp+q < 0
        t  = r
        r  = 2*r-rp+q+d+2
        rp = t
        q  = q+4
        d  = d+2
        elseif (2*r-rp+q >= 0) && (2*r-rp+q < d+2)
        t  = r
        r  = 2*r-rp+q
        rp = t
        d  = d+2
        elseif (2*r-rp+q >= 0) && (2*r-rp+q >= d+2) && (2*r-rp+q < 2*d+4)
        t  = r
        r  = 2*r-rp+q-d-2
        rp = t
        q  = q-4
        d  = d+2
        else # ((2*r-rp+q >= 0) && (2*r-rp+q >= 2*d+4))
        t  = r
        r  = 2*r-rp+q-2*d-4
        rp = t
        q  = q-8
        d  = d+2
        end
    end
end

mannadiv = quote
    while y3 != 0
        if y2 + 1 == x2
            y1 = y1 + 1
            y2 = 0
            y3 = y3 - 1
        else
            y2 = y2 + 1
            y3 = y3 - 1
        end
    end
end

divbin = quote
    while b != B
        x = 2*x
        b = b/2
        if r >= b
            x = x+1
            r = r-b
        end
    end
end

extpsolv2 = quote
    n = 1
    while true
        if true
            a = 2*(n+1)*(n+3/2)*a
            b = 4*(n+1)*b
            c = 1/2*(n+3/2)*c
            n = n+1
        else
            a = 2*a
            b = 4*b
            c = 1/2*c
        end
    end
end

extpsolv3 = quote
    n1, n2 = 1, 1
    while true
        if true
            a = 2*(n1+1)*(n1+3/2)*a
            b = 4*(n1+1)*b
            c = 1/2*(n1+3/2)*c
            n1 = n1+1
        elseif c>0
            a = 2*a
            b = 4*b
            c = 1/2*c
        else
            a = 2*(n2+1)^3*(n2+3/2)^3*a
            b = 4*(n2+1)^3*b
            c = 1/2*(n2+3/2)^3*c
            n2 = n2+1
        end
    end
end

extpsolv4 = quote
    n1, n2 = 1, 1
    while true
        if true
            a = 2*(n1+1)*(n1+3/2)*a
            b = 4*(n1+1)*b
            c = 1/2*(n1+3/2)*c
            n1 = n1+1
        elseif c>0
            a = 2*a
            b = 4*b
            c = 1/2*c
        elseif c<0
            a = 2*(n2+1)^3*(n2+3/2)^3*a
            b = 4*(n2+1)^3*b
            c = 1/2*(n2+3/2)^3*c
            n2 = n2+2
        else
            a = 6*a
            b = 36*b
            c = 1/6*c
        end
    end
end

extpsolv10 = quote
    n1, n2, n3, n4, n5 = 1, 1, 1, 1, 1
    while true
        if true
            a = 2*(n1+1)*(n1+3/2)*a
            b = 4*(n1+1)*b
            c = 1/2*(n1+3/2)*c
            n1 = n1+1
        elseif c>0
            a = 2*a
            b = 4*b
            c = 1/2*c
        elseif c<0
            a = 2*(n2+1)^3*(n2+3/2)^3*a
            b = 4*(n2+1)^3*b
            c = 1/2*(n2+3/2)^3*c
            n2 = n2+1
        elseif c<0
            a = 6*a
            b = 36*b
            c = 1/6*c
        elseif c<0
            a = 2*(n3+1)^5*(n3+3/2)^5*a
            b = 4*(n3+1)^5*b
            c = 1/2*(n3+3/2)^5*c
            n3 = n3+1
        elseif c<0
            a = 3*a
            b = 9*b
            c = 1/3*c
        elseif c<0
            a = 2*(n4+1)^7*(n4+3/2)^7*a
            b = 4*(n4+1)^7*b
            c = 1/2*(n4+3/2)^7*c
            n4 = n4+1
        elseif c<0
            a = 5*a
            b = 25*b
            c = 1/5*c      
        elseif c<0
            a = 2*(n5+1)^9*(n5+3/2)^9*a
            b = 4*(n5+1)^9*b
            c = 1/2*(n5+3/2)^9*c
            n5 = n5+1
        else
            a = 4*a
            b = 16*b
            c = 1/4*c
        end
    end
end
