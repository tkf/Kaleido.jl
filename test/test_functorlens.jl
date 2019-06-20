module TestFunctorLens

include("preamble.jl")

using Kaleido: fmap, fcompose

@testset begin
    fst = FLens((f, obj) -> fmap(x -> (x, obj[2:end]...), f(obj[1])))
    @test get((1, 2, 3), fst) == 1
    @test set((1, 2, 3), fst, 100) == (100, 2, 3)
    @test modify(string, (1, 2, 3), fst) == ("1", 2, 3)
end

asflens(lens::Lens) =
    FLens((f, obj) -> fmap(x -> set(obj, lens, x), f(get(obj, lens))))

function test_lenses(obj, lens, flens)
    @test get(obj, lens) === get(obj, flens)
    @test set(obj, lens, 100) === set(obj, flens, 100)
    @test modify(string, obj, lens) === modify(string, obj, flens)
end

@testset for (obj, lens) in [
    ((1, 2), @lens _[1])
    ((a=1, b=2), @lens _.a)
]
    flens = asflens(lens)
    test_lenses(obj, lens, flens)
end

@testset begin
    obj = ((a=1, b=nothing), nothing)
    l1 = asflens(@lens _[1])
    l2 = asflens(@lens _.a)
    lens = l1 ∘ l2
    flens = fcompose(l1, l2)
    test_lenses(obj, lens, flens)
end

end  # module
