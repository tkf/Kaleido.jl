module TestBatchLenses

include("preamble.jl")
using Kaleido: BatchLens, INDEX, KEY, PROPERTY

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
    @test get((b=2, a=1, c=3), l) === (1, 2, 3)
    @test get((b=2, c=3, a=1), l) === (1, 2, 3)
    @test set((a=1, b=2, c=3), l, (10, 20, 30)) === (a=10, b=20, c=30)
end

@testset "get" begin
    names = (:a, :b, :c)
    nt = (d=4, c=3, b=2, a=1)
    @testset "BatchLens{_, $objacc, _}" for (objacc, desired) in [
        (INDEX, (4, 3, 2))
        (KEY, (1, 2, 3))
        (PROPERTY, (1, 2, 3))
    ]
        lens = BatchLens{names, objacc, INDEX}()
        @test get(nt, lens) == desired
        if objacc === KEY
            @test get(Dict(pairs(nt)), lens) == desired
        end
    end
end

end  # module
