using Clang.cindex

cfile = "/Users/ahumenberger/repo/projects/aligator_mathematica/benchmarks/c/euclidex.c"

top = parse_header(cfile)

function traverse_compound(node::CLCursor)
    println("")
    println(node)

    for child in children(node)
        if isa(child, IfStmt)
            traverse_if(chil)
        else
            traverse(child)
        end
    end
end

function traverse_while(node::CLCursor)
    println("")
    println(node)
    chs = children(node)
    print_token(chs[1]) # loop guard

    if isa(chs[2], CompoundStmt)
        traverse_compound(chs[2])
    else
        println("Not a CompoundStmt: ", chs[2])
    end
    
    # for child in children(node)
    #     # traverse_while(child)
    #     println(child)
        
    # end
end

function traverse(node::CLCursor)
    # println(node)
    for child in children(node)
        traverse(child)
    end
end

function print_token(node::CLCursor)
    for token in tokenize(node)
        print(token, ", ")
    end
    println("")
end


function traverse(node::IfStmt)
    # println("PARENT: ", parent(node))
    chs = children(node)
    println(length(chs))
    println("\n\n\n\n\n\n\n")
    for ch in children(chs[2])
        # println(ch)
        # print_token(ch)
        traverse(ch)
    end
end

function traverse(node::BinaryOperator)
    tok = tokenize(node)
    if tok[2].text != "="
        return # TODO: no assignment
    end

    chs = children(node)
    lhs = tokenize(chs[1])
    println(typeof(lhs))
    rhs = tokenize(chs[2])
    println(symbols(rhs))

    if length(lhs) == 1 && isa(lhs[1], Clang.cindex.Identifier)
    end
end

function traverse(node::CompoundAssignOperator)
    println("FOOUOOUODUDND")
end

function symbols(tl::TokenList)
    return [t.text for t in tl if isa(t, Clang.cindex.Identifier)]
end

# ifs = search(top, IfStmt)

# traverse_if(ifs[1])

traverse(top)

