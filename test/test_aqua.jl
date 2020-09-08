module TestAqua

using Aqua
using Kaleido
using Test

Aqua.test_all(
    Kaleido;
    ambiguities = false,
    project_extras = true,
    stale_deps = true,
    deps_compat = true,
    project_toml_formatting = true,
)

@testset "Method ambiguity" begin
    # Not including `Base` due to
    # https://github.com/JuliaCollections/DataStructures.jl/pull/511
    Aqua.test_ambiguities(Kaleido)
end

@testset "Compare test/Project.toml and test/environments/main/Project.toml" begin
    @test Text(read(joinpath(@__DIR__, "Project.toml"), String)) ==
          Text(read(joinpath(@__DIR__, "environments", "main", "Project.toml"), String))
end

end  # module
