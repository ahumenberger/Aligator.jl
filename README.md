# Aligator.jl
> Automated Loop Invariant Generation by Algebraic Techniques Over the Rationals.

Aligator.jl is a Julia package for the automated generation of loop invariants. It supersedes the Mathematica package [Aligator](https://github.com/ahumenberger/aligator).

## Installation

```julia
pkg> add ContinuedFractions#master
pkg> add https://github.com/ahumenberger/Singular.jl

pkg> add https://github.com/ahumenberger/Aligator.jl
```

## Quick Start

```julia
julia> using Aligator
julia> loop = """
         while true
           x = 2*x
           y = 1/2*y
         end
       """
julia> aligator(loop)
```

## Experimental results

The following tables compare `Aligator.jl` to the Mathematica package [Aligator](https://github.com/ahumenberger/aligator). The running time is given in seconds.

<table border="0">
<tr><th></th><th></th></tr>
<tr><td>

| Single-path | Mathematica | Julia |
| ----------- | ----------- | ----- |
| cohencu     | 0.072       | 2.879 |
| freire1     | 0.016       | 1.159 |
| freire2     | 0.062       | 2.540 |
| petter1     | 0.015       | 0.876 |
| petter2     | 0.026       | 1.500 |
| petter3     | 0.035       | 2.080 |
| petter4     | 0.042       | 3.620 |

</td><td>

| Multi-path | Mathematica | Julia |
| ---------- | ----------- | ----- |
| divbin     |    0.134     | 1.760  |
| euclidex   |    0.433     | 3.272  |
| fermat     |    0.045     | 2.159  |
| knuth      |    55.791    | 12.661 |
| lcm        |    0.051     | 2.089  |
| mannadiv   |    0.022     | 1.251  |
| wensley    |    0.124     | 1.969  |

</td></tr>
</table>

The most time in `Aligator.jl` is consumed by solving the recurrences. Experiments indicated that using the symbolic manipulation library `SymEngine.jl` (instead of `SymPy.jl`) improves the performance drastically.

## Why Julia?

The first version of Aligator was implemented in the computer algebra system Mathematica. Mathematica provides high-speed implementations of symbolic computation techniques and was therefore a perfect choice for a proof-of-concept implementation of Aligator.

However, there are a number of disadvantages when Mathematica. First, as Mathematica is a proprietary software, Aligator is not open source; this prevents the integration and use of Aligator in open-source verification frameworks. Second, does not provide any capabilities for directly processing source code which should be supported when analyzing programs and inferring invariants.  

To make Aligator better suited for program analysis and invariant generation, we decided to redesign Aligator in one of the following three ecosystems: C/C++, [SAGE](http://www.sagemath.org/) and [Julia](https://julialang.org/). SAGE is a free and open-source computer algebra system and is a basically a collection of various computer algebra libraries. It is based on Python and calls external libraries for symbolic computations. As SAGE hosts its own Python version, it is rather complicated to combine SAGE with other Python libraries (e.g. for parsing C files). Even though C/C++ is very efficient, it has very little (if any) support for symbolic computation and is therefore not suitable for prototyping our research which is heavily dependent on symbolic computation. We therefore decided to use Julia for reimplementing Aligator. We believe Julia is the perfect mix between efficiency, extensibility and convenience in terms of programming and symbolic computations. 

The extensibility of Julia is given by its simple and efficient interface for calling C/C++ and Python code. This allows us to resort to already existing computer algebra libraries, such as Singular and SymPy. Julia also provides a built-in package manager that eases the use of other packages and enables others to use Julia packages, including our Aligator.jl package. 

There are also efforts to create a completely new computer algebra system in Julia called [Oscar](http://wbhart.blogspot.co.at/2016/11/new-computer-algebra-system-oscar_20.html).


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
