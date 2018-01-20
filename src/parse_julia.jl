const UnaryExpr = String

struct BinaryExpr
    op::BinaryOp
    lhs::Union{BinaryExpr, UnaryExpr}
    rhs::Union{BinaryExpr, UnaryExpr}
end

# abstract type BinaryOp end

# struct AddOp <: BinarayOp
#     data::String
# end

# struct SubOp <: BinarayOp
#     data::String
# end

# struct MulOp <: BinarayOp
#     data::String
# end

# struct DivOp <: BinarayOp
#     data::String
# end

# struct EqOp <: BinarayOp
#     data::String
# end

# function binop(op::String)
#     if op == "="
#         return EqOp(op)
#     elseif op == "+"
#         return AddOp(op)
#     elseif op == "-"
#         return SubOp(op)
#     elseif op == "*"
#         return MulOp(op)
#     elseif op == "/"
#         return DivOp(op)
#     else
#         error("unknown binary operator")
# end


loop = """
    while true
        x = x + 1
        y = y - 1
    end
"""

ast = parse(loop)

function traverse(expr::Expr)
    println(expr.head)
    if expr.head == Symbol("while")
        # ignore loop condition in expr.args[1]
        traverse(expr.args[2])
    elseif expr.head == Symbol("block")
        for arg in expr.args
            traverse(arg)
        end
    elseif expr.head == Symbol("=")
        println("assignment found")
        println(expr.args[1])
    end
    # traverse(expr)
end


traverse(ast)

# println(ast)