module TestConstrainingLens

include("preamble.jl")

@testset begin
    obj = (a = 1, b = 1)
    constraint = constraining() do obj
        @set obj.b = obj.a
    end
    lens = constraint ∘ @lens _.a

    @test get(obj, lens) === 1
    @test set(obj, lens, 2) === (a = 2, b = 2)
end

@testset "show" begin
    @test string(constraining(identity)) == "constraining(identity)"
    @test string(constraining(
        identity;
        onget = false,
    )) == "constraining(identity; onget=false)"
    @test string(constraining(
        identity;
        onset = Val(false),
    )) == "constraining(identity; onset=false)"
end

end  # module
