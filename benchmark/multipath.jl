
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

psolv2m = quote
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

psolv3m = quote
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

psolv4m = quote
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

psolv10m = quote
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

prodbin = quote
    while y!=0  
        if y % 2 ==1 
            z = z+x;
            y = y-1;
        end
        x = 2*x;
        y = y/2;
    end
end

dijkstra = quote
    while q!=1
        q=q/4;
        h=p+q;
        p=p/2;
        if r>=h
            p=p+q;
            r=r-h;
        end
    end
end

z3sqrt = quote
    while 2*p*r >= e 
        if 2*r-2*q-p >= 0 
            r = 2*r-2*q-p;
            q = q+p;
            p = p/2;
        else
            r = 2*r;
            p = p/2;
        end
    end
end

writers = quote
    r = 0;
    w = 0;
    k = 14;
    # c1 = 3;
    # c2 = 2;
    while true
        global r, w, k, c1, c2
        if w == 0
            r = r+1;
            k = k-c1;
        elseif r == 0
            w = w+1;
            k = k-c2;
        elseif w==0
            r = r-1;
            k = k+c1;
        elseif r==0
            w = w-1;
            k = k+c2;
        end
        @info  2*w+k+3*r-14==0
    end
end