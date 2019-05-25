module TestBijection

include("preamble.jl")

@testset begin
    l = (@lens _.y[2]) ∘ BijectionLens(x -> x + 1, y -> y - 1)
    obj = (x=0, y=(1, 2, 3))
    @test get(obj, l) == 1
    @test set(obj, l, 10).y[2] == 11
end

end  # module
