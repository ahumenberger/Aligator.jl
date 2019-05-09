
using BenchmarkTools
using Aligator

include("singlepath.jl")
include("multipath.jl")

# singlepath = [:cohencu, :freire1, :freire2, :(petter(1)), :(petter(2)), :(petter(3)), :(petter(4))]
# multipath = [:divbin, :euclidex, :fermat, :knuth, :lcm, :mannadiv, :wensley]

singlepath = [:cohencu, :freire1, :freire2]
multipath = [:euclidex, :fermat, :knuth, :lcm, :wensley]

const ijcar18 = BenchmarkGroup()
ijcar18["singlepath"] = BenchmarkGroup()
ijcar18["multipath"] = BenchmarkGroup()

macro createbenchmarks(suite, instances)
    for loop in eval(instances)
        loopstr = eval(loop)
        suite = eval(suite)
        suite[string(loop)] = @benchmarkable aligator($(loopstr))
    end
end

@createbenchmarks ijcar18["singlepath"] singlepath
@createbenchmarks ijcar18["multipath"] multipath

tune!(ijcar18)
results = run(ijcar18)

res = show(results)

# results["singlepath"]
# results["multipath"]