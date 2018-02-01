
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