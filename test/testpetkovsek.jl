using Petkovsek
using SymPy

@syms n y

@test algpoly([3, n, n-1], 0*n, n) == 0

@test alghyper([2*n*(n+1), -(n^2 +3*n-2), n-1], n) == [n+1, 2]