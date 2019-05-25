@doc read(joinpath(dirname(@__DIR__), "README.md"), String) ->
module Kaleido

export MultiLens, BijectionLens, toℝ₊, toℝ₋, to𝕀

using Setfield
using Requires

include("base.jl")
include("multilens.jl")
include("bijection.jl")

function __init__()
    @require(TransformVariables="84d833dd-6860-57f9-a1a7-6da5db126cff",
             include("transformvariables.jl"))
end

end # module
