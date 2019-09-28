module TestSetters

include("preamble.jl")

@testset "nullsetter" begin
    @test set(1, nullsetter, 2) === 1
    @test string(nullsetter) === "nullsetter"
end

@testset "ToField" begin
    setter = (@lens _.x) ∘ ToField(@lens _.a)
    @test set((x = 1, y = 2), setter, (a = 10, b = 20)) === (x = 10, y = 2)
end

end  # module
