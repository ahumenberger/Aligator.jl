
using BenchmarkTools
using Aligator

include("multipath.jl")

multipath = [:euclidex, :fermat, :lcm, :mannadiv, :wensley]

const suite = BenchmarkGroup()

for loop in multipath
    loopstr = eval(loop)
    suite[string(loop)] = @benchmarkable aligator($(loopstr))
end 

tune!(suite)
result = run(suite)