
using BenchmarkTools
using Aligator

include("singlepath.jl")
include("multipath.jl")

singlepath = [:cohencu, :freire1, :freire2, :petter1, :petter2, :petter3, :petter4]
multipath = [:divbin, :euclidex, :fermat, :lcm, :mannadiv, :wensley]

const ijcar18 = BenchmarkGroup()
ijcar18["singlepath"] = BenchmarkGroup()
ijcar18["multipath"] = BenchmarkGroup()

macro createbenchmarks(suite, instances)
    for loop in instances
        loopstr = eval(loop)
        suite[string(loop)] = @benchmarkable aligator($(loopstr))
    end 
end

@createbenchmarks ijcar18["singlepath"] singlepath
@createbenchmarks ijcar18["multipath"] multipath