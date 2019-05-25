module TestKaleido
using Test

@testset "$file" for file in [
        "test_multilens.jl"
        ]
    include(file)
end

end  # module
