module TestMultiLens

include("preamble.jl")

@testset "Tuple" begin
    ml = MultiLens((
        (@lens _.x),
        (@lens _.y.z),
    ))

    @test get((x=1, y=(z=2,)), ml) === (1, 2)
    @test get((y=(z=2,), x=1, a=0), ml) === (1, 2)

    @test set((x=1, y=(z=2,)), ml, ("x", "y.z")) === (x="x", y=(z="y.z",))
    @test set((x=1, y=(z=2,)), ml, (:x, "y.z")) === (x=:x, y=(z="y.z",))
    @test set((y=(z=2,), x=1, a=0), ml, ("x", "y.z")) ===
        (y=(z="y.z",), x="x", a=0)
end

@testset "NamedTuple" begin
    ml = MultiLens((
        a = (@lens _.x),
        b = (@lens _.y.z),
    ))

    @test get((x=1, y=(z=2,)), ml) === (a=1, b=2)
    @test get((y=(z=2,), x=1, a=0), ml) === (a=1, b=2)

    @testset for val in [(a="x", b="y.z")
                         (b="y.z", a="x")]
        @test set((x=1, y=(z=2,)), ml, val) === (x="x", y=(z="y.z",))
        @test set((y=(z=2,), x=1, a=0), ml, val) === (y=(z="y.z",), x="x", a=0)
    end
    @test set((x=1, y=(z=2,)), ml, (a=:x, b="y.z")) === (x=:x, y=(z="y.z",))
end

end  # module
