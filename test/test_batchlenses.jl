module TestBatchLenses

include("preamble.jl")

@testset "PropertyBatchLens" begin
    l = PropertyBatchLens(:a, :b, :c)

    @test get((a=1, b=2, c=3), l) === (a=1, b=2, c=3)
    @test set((a=1, b=2, c=3), l, (a=10, b=20, c=30)) === (a=10, b=20, c=30)
end

@testset "KeyBatchLens" begin
    l = KeyBatchLens(:a, :b, :c)

    @test get((a=1, b=2, c=3), l) === (a=1, b=2, c=3)
    @test set((a=1, b=2, c=3), l, Dict(:a=>10, :b=>20, :c=>30)) === (a=10, b=20, c=30)
end

@testset "IndexBatchLens" begin
    l = IndexBatchLens(:a, :b, :c)

    @test get((a=1, b=2, c=3), l) === (1, 2, 3)
    @test set((a=1, b=2, c=3), l, (10, 20, 30)) === (a=10, b=20, c=30)
end

end  # module
