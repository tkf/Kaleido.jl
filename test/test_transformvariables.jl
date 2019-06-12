module TestTransformVariables

include("preamble.jl")
using TransformVariables

@testset begin
    l = (@lens _.y[2]) ∘ setting(asℝ₊)
    obj = (x=0, y=(0, 1, 2))
    @test get(obj, l) == 0
    @test set(obj, l, -1).y[2] == exp(-1)
end

end  # module
