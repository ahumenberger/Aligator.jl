# Aligator.jl
> **A**utomated **L**oop **I**nvariant **G**eneration by **A**lgebraic **T**echniques **O**ver the **R**ationals.

Aligator.jl is a Julia package for the automated generation of loop invariants. It supersedes the Mathematica package [Aligator](https://github.com/ahumenberger/aligator).

## Installation

```julia

pkg> add https://github.com/ahumenberger/Recurrences.jl
pkg> add https://github.com/ahumenberger/AlgebraicDependencies.jl
pkg> add https://github.com/ahumenberger/Aligator.jl
```

## Quick Start

```julia
julia> using Aligator
julia> loop = quote
         while true
           x = 2*x
           y = 1/2*y
         end
       end
julia> aligator(loop)
```

## Publications

1. A. Humenberger, M. Jaroschek, L. Kovács. Invariant Generation for Multi-Path Loops with Polynomial Assignments. In *Verification, Model Checking, and Abstract Interpretation (VMCAI)*, 2018.
<https://arxiv.org/abs/1801.03967>

1. A. Humenberger, M. Jaroschek, L. Kovács. Aligator.jl - A Julia Package for Loop Invariant Generation. In *Intelligent Computer Mathematics (CICM)*, 2018.
<https://arxiv.org/abs/1808.05394>

1. A. Humenberger, M. Jaroschek, L. Kovács. Automated Generation of Non-Linear Loop Invariants Utilizing Hypergeometric Sequences. In *International Symposium on Symbolic and Algebraic Computation (ISSAC)*, 2017.
<https://arxiv.org/abs/1705.02863>

2. L. Kovács. A Complete Invariant Generation Approach for P-solvable Loops. In *Proceedings of the International Conference on Perspectives of System Informatics (PSI)*, volume 5947 of *LNCS*, pages 242–256, 2009.

3. L. Kovács. Reasoning Algebraically About P-solvable Loops. In *Proceedings of the International Conference on Tools and Algorithms for the Construction and Analysis of Systems (TACAS)*, volume 4963 of *LNCS*, pages 249–264, 2008.

4. L. Kovács. Aligator: A Mathematica Package for Invariant Generation (System Description). In *Proceedings of the International Joint Conference on Automated Reasoning (IJCAR)*, volume 5195 of *LNCS*, pages 275–282, 2008.

5. L. Kovács. Invariant Generation with Aligator. In *Proceedings of Austrian-Japanese Workshop on Symbolic Computation in Software Science (SCCS)*, number 08-08 in *RISC-Linz Report Series*, pages 123–136, 2008.

6. L. Kovács. Aligator: a Package for Reasoning about Loops. In *Proceedings of the International Conference on Logic for Programming, Artificial Intelligence and Reasoning – Short Papers (LPAR-14)*, pages 5–8, 2007.
