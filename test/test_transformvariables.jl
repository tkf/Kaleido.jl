module TestTransformVariables

include("preamble.jl")
using TransformVariables

@testset "setting(asℝ₊)" begin
    l = (@lens _.y[2]) ∘ setting(asℝ₊)
    obj = (x=0, y=(0, 1, 2))
    @test get(obj, l) == 0
    @test set(obj, l, -1).y[2] == exp(-1)
end

@testset "getting(as𝕀)" begin
    l = (@lens _.y[2]) ∘ getting(as𝕀)
    obj = (x=0, y=(0, -Inf, 2))
    @test get(obj, l) == 0
    @test set(obj, l, 0.5).y[2] == 0.0
end

end  # module
