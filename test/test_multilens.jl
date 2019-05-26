module TestMultiLens

include("preamble.jl")
using InteractiveUtils
using StaticArrays

function test_positional_set(ml)
    @test set((x=1, y=(z=2,)), ml, ("x", "y.z")) === (x="x", y=(z="y.z",))
    @test set((x=1, y=(z=2,)), ml, (:x, "y.z")) === (x=:x, y=(z="y.z",))
    @test set((y=(z=2,), x=1, a=0), ml, ("x", "y.z")) ===
        (y=(z="y.z",), x="x", a=0)

    for val in Any[
        (10, 20),
        [10, 20],
        [10, 20]',
        Broadcast.broadcasted(x -> 10x, [1, 2]),
        SVector(10, 20),
        SMatrix{1, 2}(10, 20),
    ]
        @test set((x=1, y=(z=2,)), ml, val) === (x=10, y=(z=20,))
    end
end

@testset "Tuple" begin
    ml = MultiLens((
        (@lens _.x),
        (@lens _.y.z),
    ))

    @test get((x=1, y=(z=2,)), ml) === (1, 2)
    @test get((y=(z=2,), x=1, a=0), ml) === (1, 2)

    test_positional_set(ml)
end

function test_namedtuple_set(ml)
    @testset for val in [(a="x", b="y.z")
                         (b="y.z", a="x")]
        @test set((x=1, y=(z=2,)), ml, val) === (x="x", y=(z="y.z",))
        @test set((y=(z=2,), x=1, a=0), ml, val) === (y=(z="y.z",), x="x", a=0)
    end
    @test set((x=1, y=(z=2,)), ml, (a=:x, b="y.z")) === (x=:x, y=(z="y.z",))
end

@testset "NamedTuple" begin
    ml = MultiLens((
        a = (@lens _.x),
        b = (@lens _.y.z),
    ))

    @test get((x=1, y=(z=2,)), ml) === (a=1, b=2)
    @test get((y=(z=2,), x=1, a=0), ml) === (a=1, b=2)

    test_namedtuple_set(ml)
end

@testset "castout = Tuple" begin
    # Input is a `NamedTuple`; Output is a `Tuple`
    ml = MultiLens(
        Tuple,
        (
            a = (@lens _.x),
            b = (@lens _.y.z),
        )
    )

    @test get((x=1, y=(z=2,)), ml) === (1, 2)
    @test get((y=(z=2,), x=1, a=0), ml) === (1, 2)

    test_namedtuple_set(ml)
end

@testset "castout = SVector ∘ Tuple" begin
    # Input is a `NamedTuple`; Output is a `SVector`
    ml = MultiLens(
        SVector ∘ Tuple,
        (
            a = (@lens _.x),
            b = (@lens _.y.z),
        )
    )

    @test get((x=1, y=(z=2,)), ml) === SVector(1, 2)
    @test get((y=(z=2,), x=1, a=0), ml) === SVector(1, 2)

    test_namedtuple_set(ml)
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
    return sum(Tuple(get(set(obj, lens, x), lens)))
end

function codegen_multilens_svector()
    obj = (
        a = (b = :x,),
        c = (:y, :z),
    )
    lens = MultiLens(
        SVector,
        (
            (@lens _.a.b),
            (@lens _.c[$1]),
            (@lens _.c[$2]),
        )
    )
    x = (1, 2, 3)
    return sum(get(set(obj, lens, x), lens))
end

@testset "Gode gen: $(nameof(f))" for f in [
    codegen_multilens_tuple
    codegen_multilens_namedtuple
    codegen_multilens_svector
]
    @test f() == 6
    llvm = sprint(code_llvm, f, Tuple{})
    @test occursin(r"i(32|64) 6\b", llvm)
end

end  # module
