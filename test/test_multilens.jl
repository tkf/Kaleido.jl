module TestMultiLens

include("preamble.jl")
using InteractiveUtils

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

function codegen_multilens_tuple()
    obj = (
        a = (b = :x,),
        c = (:y, :z),
    )
    lens = MultiLens((
        (@lens _.a.b),
        # (@lens _.c[1]),
        # (@lens _.c[2]),
        (@lens _.c[$1]),
        (@lens _.c[$2]),
    ))
    x = (1, 2, 3)
    return sum(get(set(obj, lens, x), lens))
end

function codegen_multilens_namedtuple()
    obj = (
        a = (b = :x,),
        c = (:y, :z),
    )
    lens = MultiLens((
        i = (@lens _.a.b),
        j = (@lens _.c[$1]),
        k = (@lens _.c[$2]),
    ))
    x = (k = 1, i = 2, j = 3)
    return sum(get(set(obj, lens, x), lens))
end

@testset "Gode gen: $(nameof(f))" for f in [
    codegen_multilens_tuple
    # codegen_multilens_namedtuple
]
    llvm = sprint(code_llvm, f, Tuple{})
    @test occursin(r"i(32|64) 6\b", llvm)
end

end  # module
