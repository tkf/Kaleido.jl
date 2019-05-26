module TestKaleido
using Test

@testset "$file" for file in [
        "test_base.jl"
        "test_batchlenses.jl"
        "test_multilens.jl"
        "test_bijection.jl"
        "test_transformvariables.jl"
        ]
    include(file)
end

end  # module
