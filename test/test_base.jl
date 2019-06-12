module TestBase

include("preamble.jl")
using Kaleido: prefer_singleton_callable, BijectionLens

lenses_as_shown = include("lenses_as_shown.jl") :: Array
desired_show = filter(x -> !occursin(x, "[]"),
                      readlines(joinpath(@__DIR__, "lenses_as_shown.jl")))
desired_show = strip.(desired_show)

struct ShowTestCase
    lens::Lens
    source::String
    desired_show::Bool
end

Base.show(io::IO, case::ShowTestCase) = print(io, case.source)

showtestcases = ShowTestCase.(lenses_as_shown, desired_show, Ref(true))

@testset "repr" begin
    @testset for case in showtestcases
        l0 = case.lens
        code = repr(l0)
        l1 = Base.include_string(@__MODULE__, code)
        @test l1 == l0
    end
end

@testset "show" begin
    @testset for case in showtestcases
        l = case.lens

        str1 = sprint(show, l)
        @debug """
        Show of $(case.source):
        $str1
        """
        @test occursin("Kaleido.", str1)

        str2 = sprint(show, l; context=:limit => true)
        @debug """
        Show of $(case.source):
        $str2
        """
        @test !occursin("Kaleido.", str2)
        if case.desired_show
            @test str2 == case.source
        end
    end
end

@testset "prefer_singleton_callable" begin
    @test sizeof((Int,)) > 0
    @test sizeof((prefer_singleton_callable(Int),)) == 0
    @test sizeof((prefer_singleton_callable(identity),)) == 0
end

end  # module
