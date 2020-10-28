
using BenchmarkTools
using Aligator

include("singlepath.jl")
include("multipath.jl")

# singlepath = [:cohencu, :freire1, :freire2, :(petter(1)), :(petter(2)), :(petter(3)), :(petter(4))]
# multipath = [:divbin, :euclidex, :fermat, :knuth, :lcm, :mannadiv, :wensley]

singlepath = [:cubes, :eucliddiv, :freire1, :freire2, :(petter(2)), :(petter(3)), :(petter(4)), :(petter(22)), :(petter(23)), :psolv1s, :psolv2s]
multipath = [:euclidex, :fermat, :knuth, :lcm, :wensley, :divbin, :psolv2m, :psolv3m, :psolv4m, :psolv10m]

group = BenchmarkGroup()
group["singlepath"] = BenchmarkGroup()
group["multipath"] = BenchmarkGroup()

function create(suite, instances)
    for loop in instances
        suite[string(loop)] = @benchmarkable aligator($loop) samples=1 seconds=60 evals=5
    end
end

create(group["singlepath"], singlepath)
create(group["multipath"], multipath)

# tune!(group)
# results = run(group)

# res = show(results)

# results["singlepath"]
# results["multipath"]