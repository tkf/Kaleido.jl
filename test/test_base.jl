module TestBase

include("preamble.jl")
using Kaleido: prefer_singleton_callable

expressions_block = quote
    MultiLens(((@lens _.x), (@lens _[1])))
    BijectionLens(exp, log)
    MultiLens((BijectionLens(exp, log), BijectionLens(log, exp)))
end
expressions = filter(x -> x isa Expr, expressions_block.args)
@assert length(expressions) == 3

@testset "repr" begin
    @testset for ex in expressions
        l0 = @eval $ex
        code = repr(l0)
        l1 = Base.include_string(@__MODULE__, code)
        @test l1 == l0
    end
end

@testset "show" begin
    @testset for ex in expressions
        l = @eval $ex

        str1 = sprint(show, l)
        @debug """
        Show of $ex:
        $str1
        """
        @test occursin("Kaleido.", str1)

        str2 = sprint(show, l; context=:limit => true)
        @debug """
        Show of $ex:
        $str2
        """
        @test !occursin("Kaleido.", str2)
    end
end

@testset "prefer_singleton_callable" begin
    @test sizeof((Int,)) > 0
    @test sizeof((prefer_singleton_callable(Int),)) == 0
    @test sizeof((prefer_singleton_callable(identity),)) == 0
end

end  # module
