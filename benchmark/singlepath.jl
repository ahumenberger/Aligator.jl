
simpleloop = """
        x = 1/2*x
        y = 2y
    end
"""

macro petter(n)
    loop = """while true
        x = x + y^$n
        y = y + 1
    end
    """
    eval(Expr(:(=), Symbol("petter$n"), loop))
end

for i in 1:20
    @petter(i)
end

cohencu = """
    while n<=N
        n = n+1
        x = x+y
        y = y+z
        z = z+6
    end
"""

freire1 = """
    while x>r
        x = x-r
        r = r+1
    end
"""

freire2 = """
    while x-s > 0
        x = x-s
        s = s+6*r+3
        r = r+1
    end
"""


paperloop = """
    while true
        if true
            r = r - v
            v = v + 2
        else
            r = r + u
            u = u + 2
        end
    end
"""