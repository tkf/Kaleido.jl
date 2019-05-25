module TestKaleido
using Test

@testset "$file" for file in [
        "test_multilens.jl"
        "test_bijection.jl"
        ]
    include(file)
end

end  # module
