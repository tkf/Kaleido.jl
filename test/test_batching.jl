module TestBatching

include("preamble.jl")
using Kaleido: SingletonLens

lens_created_in_global_scope = @batchlens begin
    _.a.b.c.d
    _.a.b.c.e
    _.a.b.f
    _.a.g
end

@testset "`@batchlens` inside `@test`" begin
    # Inside of `@test` macro, `LineNumberNode`s are missing.  Make
    # sure that `@batchlens` can handle that:
    @test (@batchlens begin
        _.a.b.c.d
        _.a.b.c.e
        _.a.b.f
        _.a.g
    end) == lens_created_in_global_scope
end

@testset begin
    lens = @batchlens begin
        _.a
        _.b
    end

    obj = (a=1, b=2)
    @test get(obj, lens) == (1, 2)
    @test set(obj, lens, (10, 20)) == (a=10, b=20)

    @test lens == IndexBatchLens(:a, :b)
end

@testset begin
    lens = @batchlens begin
        _.a.b
        _.a.c
    end

    obj = (a=(b=1, c=2),)
    @test get(obj, lens) == (1, 2)
    @test set(obj, lens, (10, 20)) == (a=(b=10, c=20),)

    @test lens ==
        IndexBatchLens(:a) ∘ MultiLens((
            (@lens _[1]) ∘ IndexBatchLens(:b, :c),
        )) ∘ FlatLens(2)
end

@testset begin
    lens = @batchlens begin
        _.a.b.c
        _.a.b.d
        _.a.e
    end

    obj = (a=(b=(c=1, d=2), e=3),)
    @test get(obj, lens) == (1, 2, 3)
    @test set(obj, lens, (10, 20, 30)) == (a=(b=(c=10, d=20), e=30),)

    @test lens ==
        IndexBatchLens(:a) ∘ MultiLens((
            (@lens _[1]) ∘ IndexBatchLens(:b, :e) ∘ MultiLens((
                (@lens _[1]) ∘ IndexBatchLens(:c, :d),
                (@lens _[2]) ∘ Kaleido.SingletonLens(),
            )) ∘ FlatLens(2, 1),
        )) ∘ FlatLens(3)
end

@testset begin
    lens = @batchlens begin
        _.a.b.c.d
        _.a.b.c.e
        _.a.b.f
        _.a.g
    end

    obj = (a=(b=(c=(d=1, e=2), f=3), g=4),)
    @test get(obj, lens) == (1, 2, 3, 4)
    @test set(obj, lens, (10, 20, 30, 40)) ==
        (a=(b=(c=(d=10, e=20), f=30), g=40),)

    @test lens ==
        IndexBatchLens(:a) ∘ MultiLens((
            (@lens _[1]) ∘ IndexBatchLens(:b, :g) ∘ MultiLens((
                (@lens _[1]) ∘ IndexBatchLens(:c, :f) ∘ MultiLens((
                    (@lens _[1]) ∘ IndexBatchLens(:d, :e),
                    (@lens _[2]) ∘ SingletonLens(),
                )) ∘ FlatLens(2, 1),
                (@lens _[2]) ∘ SingletonLens(),
            )) ∘ FlatLens(3, 1),
        )) ∘ FlatLens(4)
end

@testset begin
    lens = @batchlens begin
        _.a.b.c
        _.a.b.d[1]
        _.a.b.d[3]
        _.a.e
    end

    obj = (a=(b=(c=1, d=(2, 3, 4)), e=5),)
    @test get(obj, lens) == (1, 2, 4, 5)
    @test set(obj, lens, (10, 20, 40, 50)) ==
        (a=(b=(c=10, d=(20, 3, 40)), e=50),)

    @test lens ==
        IndexBatchLens(:a) ∘ MultiLens((
            (@lens _[1]) ∘ IndexBatchLens(:b, :e) ∘ MultiLens((
                (@lens _[1]) ∘ IndexBatchLens(:c, :d) ∘ MultiLens((
                    (@lens _[1]) ∘ Kaleido.SingletonLens(),
                    (@lens _[2]) ∘ MultiLens((
                        (@lens _[1]), (@lens _[3]),
                    )),
                )) ∘ FlatLens(1, 2),
                (@lens _[2]) ∘ Kaleido.SingletonLens())) ∘ FlatLens(3, 1),
        )) ∘ FlatLens(4)
end

@testset begin
    lens = @batchlens begin
        _.a.b.c
        _.a.b.d
        _.a.e
        _.a.b.f
        _.a.b.g
    end

    obj = (a=(b=(c=1, d=2, f=3, g=4), e=5),)
    @test get(obj, lens) == (1, 2, 5, 3, 4)
    @test_broken set(obj, lens, (10, 20, 50, 30, 40)) ==
        (a=(b=(c=10, d=20, f=30, g=40), e=50),)

    @test lens ==
        IndexBatchLens(:a) ∘ MultiLens((
            (@lens _[1]) ∘
            IndexBatchLens(:b, :e, :b) ∘  # TODO: this is wrong; fix it
            MultiLens((
                (@lens _[1]) ∘ IndexBatchLens(:c, :d),
                (@lens _[2]) ∘ Kaleido.SingletonLens(),
                (@lens _[3]) ∘ IndexBatchLens(:f, :g)
            )) ∘ FlatLens(2, 1, 2),
        )) ∘ FlatLens(5)
end

end  # module
