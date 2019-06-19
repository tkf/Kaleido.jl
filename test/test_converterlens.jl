module TestConverterLens

include("preamble.jl")
using StaticArrays

@testset begin
    obj = (x = ((0, 1, 2), "A"), y = "B");
    lens = (@lens _.x[1]) ∘ getting(SVector)
    @test get(obj, lens) === SVector(obj.x[1])
    @test set(obj, lens, SVector(3, 4, 5)) ===
        (x = ((3, 4, 5), "A"), y = "B")
end

@testset begin
    obj = (x = ((a = 0, b = 1, c = 2), "A"), y = "B");
    @testset for lens in [
        (@lens _.x[1]) ∘ getting(Base.splat(SVector))
        (@lens _.x[1]) ∘ getting(Tuple) ∘ getting(SVector)
    ]
        @test get(obj, lens) === SVector(obj.x[1]...)
        @test set(obj, lens, SVector(3, 4, 5)) ===
            (x = ((a = 3, b = 4, c = 5), "A"), y = "B")
    end
end

struct CustomType{T}
    a::T
    b::T
    c::T
end

CustomType(x::SVector) = CustomType(x...)
StaticArrays.SVector(obj::CustomType) = SVector(obj.a, obj.b, obj.c)

@testset begin
    obj = (x = (CustomType(0, 1, 2), "A"), y = "B");
    lens = (@lens _.x[1]) ∘ getting(SVector)
    @test get(obj, lens) === SVector(obj.x[1])
    @test set(obj, lens, SVector(3, 4, 5)) ===
        (x = (CustomType(3, 4, 5), "A"), y = "B")
end

end  # module
