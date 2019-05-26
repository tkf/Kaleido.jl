module TestFlatLens

include("preamble.jl")

@testset begin
    l = FlatLens(2, 3, 4)
    @test get(((1, 2), (3, 4, 5), (6, 7, 8, 9)), l) ==
        (1, 2, 3, 4, 5, 6, 7, 8, 9)
    @test set(nothing, l, (1, 2, 3, 4, 5, 6, 7, 8, 9)) ==
        ((1, 2), (3, 4, 5), (6, 7, 8, 9))
end

end  # module
