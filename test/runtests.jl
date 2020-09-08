module TestKaleido
using Test

@testset "$file" for file in sort([file for file in readdir(@__DIR__) if
                                   match(r"^test_.*\.jl$", file) !== nothing])
    file == "test_doctest.jl" && VERSION < v"1.2" && continue
    include(file)
end

end  # module
