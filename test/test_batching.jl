module TestBatching

include("preamble.jl")
using Kaleido: SingletonLens

lens = @batchlens begin
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
    end) == lens
end

@testset "`batch`ed lenses" begin
    @test (@batchlens begin
        _.a
        _.b
    end) ==
        IndexBatchLens(:a, :b)

    @test (@batchlens begin
        _.a.b
        _.a.c
    end) ==
        IndexBatchLens(:a) ∘ MultiLens((
            (@lens _[1]) ∘ IndexBatchLens(:b, :c),
        )) ∘ FlatLens(2)

    @test (@batchlens begin
        _.a.b.c
        _.a.b.d
        _.a.e
    end) ==
        IndexBatchLens(:a) ∘ MultiLens((
            (@lens _[1]) ∘ IndexBatchLens(:b, :e) ∘ MultiLens((
                (@lens _[1]) ∘ IndexBatchLens(:c, :d),
                (@lens _[2]) ∘ Kaleido.SingletonLens(),
            )) ∘ FlatLens(2, 1),
        )) ∘ FlatLens(3)

    @test (@batchlens begin
        _.a.b.c.d
        _.a.b.c.e
        _.a.b.f
        _.a.g
    end) ==
        IndexBatchLens(:a) ∘ MultiLens((
            (@lens _[1]) ∘ IndexBatchLens(:b, :g) ∘ MultiLens((
                (@lens _[1]) ∘ IndexBatchLens(:c, :f) ∘ MultiLens((
                    (@lens _[1]) ∘ IndexBatchLens(:d, :e),
                    (@lens _[2]) ∘ SingletonLens(),
                )) ∘ FlatLens(2, 1),
                (@lens _[2]) ∘ SingletonLens(),
            )) ∘ FlatLens(3, 1),
        )) ∘ FlatLens(4)

    @test (@batchlens begin
        _.a.b.c
        _.a.b.d[1]
        _.a.b.d[3]
        _.a.e
    end) ==
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

end  # module
