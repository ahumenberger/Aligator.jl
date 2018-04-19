# Aligator.jl
> Automated Loop Invariant Generation by Algebraic Techniques Over the Rationals.

Aligator.jl is a Julia package for the automated generation of loop invariants. It supersedes the Mathematica package [Aligator](https://github.com/ahumenberger/aligator).

## Installation

```julia
julia> Pkg.add("Cxx")
julia> Pkg.add("Nemo")
julia> Pkg.checkout("Nemo")
julia> Pkg.clone("https://github.com/oscar-system/Singular.jl")
julia> Pkg.build("Singular")

julia> Pkg.clone("https://github.com/ahumenberger/Aligator.jl")
```

## Quick Start

```julia
julia> using Aligator
julia> loop = """
         while true
           x = 2x
           y = 1/2y
         end
       """
julia> aligator(loop)
```

## Experimental results

The following tables compare `Aligator.jl` to the Mathematica package [Aligator](https://github.com/ahumenberger/aligator).
The most time in `Aligator.jl` is consumed by solving the recurrences. Experiments indicated that using to symbolic manipulation library `SymEngine.jl` (instead of `SymPy.jl`) improves the performance drastically.

<table border="0">
<tr><th></th><th></th></tr>
<tr><td>

| Single-path | Mathematica | Julia |
| ----------- | ----------- | ----- |
| `cohencu`     | `0.072`       | `2.879` |
| `freire1`     | `0.016`       | `1.159` |
| `freire2`     | `0.062`       | `2.540` |
| `petter1`     | `0.015`       | `0.876` |
| `petter2`     | `0.026`       | `1.500` |
| `petter3`     | `0.035`       | `2.080` |
| `petter4`     | `0.042`       | `3.620` |

</td><td>

| Multi-path | Mathematica | Julia |
| ---------- | ----------- | ----- |
| `divbin`     |    `0.134`     | `1.760`  |
| `euclidex`   |    `0.433`     | `3.272`  |
| `fermat`     |    `0.045`     | `2.159`  |
| `knuth`      |    `55.791`    | `12.661` |
| `lcm`        |    `0.051`     | `2.089`  |
| `mannadiv`   |    `0.022`     | `1.251`  |
| `wensley`    |    `0.124`     | `1.969`  |

</td></tr>
</table>

## Publications

1. A. Humenberger, M. Jaroschek, L. Kovács. Invariant Generation for Multi-Path Loops with Polynomial Assignments. In *Verification, Model Checking, and Abstract Interpretation (VMCAI)*, 2018.
<https://arxiv.org/abs/1801.03967>

1. A. Humenberger, M. Jaroschek, L. Kovács. Automated Generation of Non-Linear Loop Invariants Utilizing Hypergeometric Sequences. In *International Symposium on Symbolic and Algebraic Computation (ISSAC)*, 2017.
<https://arxiv.org/abs/1705.02863>

2. L. Kovács. A Complete Invariant Generation Approach for P-solvable Loops. In *Proceedings of the International Conference on Perspectives of System Informatics (PSI)*, volume 5947 of *LNCS*, pages 242–256, 2009.

3. L. Kovács. Reasoning Algebraically About P-solvable Loops. In *Proceedings of the International Conference on Tools and Algorithms for the Construction and Analysis of Systems (TACAS)*, volume 4963 of *LNCS*, pages 249–264, 2008.

4. L. Kovács. Aligator: A Mathematica Package for Invariant Generation (System Description). In *Proceedings of the International Joint Conference on Automated Reasoning (IJCAR)*, volume 5195 of *LNCS*, pages 275–282, 2008.

5. L. Kovács. Invariant Generation with Aligator. In *Proceedings of Austrian-Japanese Workshop on Symbolic Computation in Software Science (SCCS)*, number 08-08 in *RISC-Linz Report Series*, pages 123–136, 2008.

6. L. Kovács. Aligator: a Package for Reasoning about Loops. In *Proceedings of the International Conference on Logic for Programming, Artificial Intelligence and Reasoning – Short Papers (LPAR-14)*, pages 5–8, 2007.
