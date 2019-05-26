module TestBatchLenses

include("preamble.jl")
using Kaleido: BatchLens, INDEX, KEY, PROPERTY

@testset "PropertyBatchLens" begin
    l = PropertyBatchLens(:a, :b, :c)

    @test get((a=1, b=2, c=3), l) === (a=1, b=2, c=3)
    @test set((a=1, b=2, c=3), l, (a=10, b=20, c=30)) === (a=10, b=20, c=30)
end

@testset "KeyBatchLens" begin
    l = KeyBatchLens(:a, :b, :c)

    @test get((a=1, b=2, c=3), l) === (a=1, b=2, c=3)
    @test set((a=1, b=2, c=3), l, Dict(:a=>10, :b=>20, :c=>30)) === (a=10, b=20, c=30)
end

@testset "IndexBatchLens" begin
    l = IndexBatchLens(:a, :b, :c)

    @test get((a=1, b=2, c=3), l) === (1, 2, 3)
    @test get((b=2, a=1, c=3), l) === (1, 2, 3)
    @test get((b=2, c=3, a=1), l) === (1, 2, 3)
    @test set((a=1, b=2, c=3), l, (10, 20, 30)) === (a=10, b=20, c=30)
end

@testset "get" begin
    names = (:a, :b, :c)
    nt = (d=4, c=3, b=2, a=1)
    @testset "BatchLens{_, $objacc, _}" for (objacc, desired) in [
        (INDEX, (4, 3, 2))
        (KEY, (1, 2, 3))
        (PROPERTY, (1, 2, 3))
    ]
        lens = BatchLens{names, objacc, INDEX}()
        @test get(nt, lens) == desired
        if objacc === KEY
            @test get(Dict(pairs(nt)), lens) == desired
        end
    end
end

const Associative = Union{AbstractDict, NamedTuple}

eq(x, y) = x == y
eq(x::Associative, y::Associative) =
    sort(collect(keys(x))) == sort(collect(keys(y))) &&
    all(eq.(getindex.(Ref(x), keys(x)),
            getindex.(Ref(y), keys(x))))
eq(x::Tuple, y::NamedTuple) = x == Tuple(y)
eq(x::NamedTuple, y::Tuple) = Tuple(x) == y

@testset "laws" begin
    @testset "$obj" for (obj, objacc_list) in [
        ((a=1, b=2, c=3, d=4), [PROPERTY]),
        ((1, 2, 3, 4), [INDEX]),
        (Dict(:a=>1, :b=>2, :c=>3, :d=>4), [KEY]),
    ]
        @testset "BatchLens{_, $objacc, $valueacc}" for
                objacc in objacc_list,
                (valueacc, val_list) in [
                    (INDEX, [
                        (1, 2, 3),
                        (c=4, b=5, a=6),
                    ]),
                    (KEY, [
                        (a=1, b=2, c=3),
                        (c=4, b=5, a=6),
                        Dict(:a=>7, :b=>8, :c=>9),
                    ]),
                ]

            lens = BatchLens{(:a, :b, :c), objacc, valueacc}()

            @testset "You get what you set." begin
                @testset for val in val_list
                    @debug(
                        "eq(get(set(obj, lens, val), lens), val)",
                        obj,
                        lens,
                        lhs = get(set(obj, lens, val), lens),
                        rhs = val,
                    )
                    @test eq(get(set(obj, lens, val), lens), val)
                end
            end

            @testset "Setting what was already there changes nothing." begin
                @test set(obj, lens, get(obj, lens)) == obj
            end

            @testset "The last set wins." begin
                val1 = val_list[1]
                @testset for val2 in val_list
                    @test set(set(obj, lens, val1), lens, val2) ==
                        set(obj, lens, val2)
                end
            end
        end
    end
end

end  # module
