module TestSetters

include("preamble.jl")

@testset "nullsetter" begin
    @test set(1, nullsetter, 2) === 1
    @test string(nullsetter) === "nullsetter"
    err = @test_error get(1, nullsetter)
    @test occursin("Setters do not support `get`", sprint(showerror, err))
end

@testset "ToField" begin
    setter = (@lens _.x) ∘ ToField(@lens _.a)
    @test set((x = 1, y = 2), setter, (a = 10, b = 20)) === (x = 10, y = 2)

    setter = (@lens _.x) ∘ ToField(x -> x.a)
    @test set((x = 1, y = 2), setter, (a = 10, b = 20)) === (x = 10, y = 2)
end

end  # module
