module TestKaleido
using Test

@testset "$file" for file in sort([file for file in readdir(@__DIR__) if
                                   match(r"^test_.*\.jl$", file) !== nothing])
    include(file)
end

using Aqua
using Kaleido
#=
Aqua.test_all(Kaleido)
=#
@testset "Aqua" begin
    @testset "Method ambiguity" begin
        # Not including `Base` due to
        # https://github.com/JuliaCollections/DataStructures.jl/pull/511
        Aqua.test_ambiguities(Kaleido)
    end
    @testset "Unbound type parameters" begin
        Aqua.test_unbound_args(Kaleido)
    end
    @testset "Undefined exports" begin
        Aqua.test_undefined_exports(Kaleido)
    end
end

end  # module
