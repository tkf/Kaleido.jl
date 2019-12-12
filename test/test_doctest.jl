module TestDoctest

using Documenter
using Kaleido
using Test

@testset "doctest" begin
    doctest(Kaleido; manual = true)
end

end  # module
