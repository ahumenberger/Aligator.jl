
euclidex = """
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
"""

fermat = """
    while r != 0
        if r > 0
            r = r - v
            v = v + 2
        else
            r = r + u
            u = u + 2
        end
    end
"""

wensley = """
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
"""

lcm = """
    while x != y
        if x > y
            x = x - y
            v = v + u
        else
            y = y - x
            u = u + v
        end
    end
"""

knuth = """
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
"""

mannadiv = """
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
"""

divbin = """
    while b != B
        x = 2*x
        b = b/2
        if r >= b
            x = x+1
            r = r-b
        end
    end
"""