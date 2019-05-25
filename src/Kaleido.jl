module Kaleido

export MultiLens, BijectionLens

using Setfield

include("base.jl")
include("multilens.jl")
include("bijection.jl")

end # module
