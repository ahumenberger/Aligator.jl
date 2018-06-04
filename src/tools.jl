using Distributions

macro inv(ex)
    return :( $ex == 0 ? nothing : throw(AssertionError($(string(ex)))) )
end

global g_invset = Dict()

macro invset(name, invs...)
    g_invset[name] = invs
end

macro invcheck(name)
    invs = g_invset[name]
    return quote
        for (i, ex) in enumerate($invs)
            # println(ex)
            eval(ex) == 0 ? nothing : println("$($name)[$(i)] does not hold.")
        end
    end
end

macro initvar(var, val)
    sym = Symbol(string(var, "0"))
    println(sym)
    println(val)
    return :($sym = $val)
end

@invset("B1 new", 
    x0*y - x*y,
    -(x0*x^2) + x^3 + 2*x0*x*y0 - 2*x^2*y0,
    y0*y - y^2,
    -(x^2*y0) + 2*x*y0^2 + x^2*y - 2*x*y^2
)

@invset("B2 new",
    x*y - x*y0, 
    -x^2 + x*x0, 
    x0*y^2 - y^3 - x0*y*y0 + y^2*y0, 
    x0^2*y - y^3 - x^2*y0 - x0*y*y0 + y^2*y0 + x*y0^2
)

@invset("B1 old",
    y^2 - y*y0,
    x*y - x0*y, 
    -(x0^2*y) + x^2*y0 + 2*x0*y*y0 - 2*x*y0^2, 
    x^3 - x^2*x0 - 2*x0^2*y + 2*x*x0*y0 + 4*x0*y*y0 - 4*x*y0^2
)

@invset("B2 old",
    -(x0*y^2) + y^3 + x0*y*y0 - y^2*y0, 
    x0^2*y - x0*y^2 - x*x0*y0 + x*y0^2, 
    x*y - x*y0, 
    x^2 - x*x0
)


@invset("NEW",
    x^2*y^2*y0 - x^2*y*y0^2, 
    x^3*y*y0 - x^2*x0*y*y0, 
    x^2*y^3 - x^2*y*y0^2, 
    x^2*x0*y^2 - x^2*x0*y*y0, 
    x^3*y^2 - x^2*x0*y*y0, 
    x^4*y -x^3*x0*y
)

x0 = rand(0:9999999999)
y0 = rand(0:9999999999)

x,y = x0,y0

println(x0)

@invcheck("NEW")

n = 0
while n < 10000

    if rand(Bernoulli(0.5)) == 1
        x = 2*y
        y = 0
    else
        y = x
        x = 0
    end

    # @invcheck("B1 new")
    @invcheck("NEW")
    n = n + 1
end