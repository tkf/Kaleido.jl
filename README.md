# Kaleido: some useful lenses

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://tkf.github.io/Kaleido.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://tkf.github.io/Kaleido.jl/dev)
[![Build Status](https://travis-ci.com/tkf/Kaleido.jl.svg?branch=master)](https://travis-ci.com/tkf/Kaleido.jl)
[![Codecov](https://codecov.io/gh/tkf/Kaleido.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/tkf/Kaleido.jl)
[![Coveralls](https://coveralls.io/repos/github/tkf/Kaleido.jl/badge.svg?branch=master)](https://coveralls.io/github/tkf/Kaleido.jl?branch=master)

Kaleido.jl is a collection of useful
[`Lens`](https://jw3126.github.io/Setfield.jl/latest/index.html#Setfield.Lens)es
that enhance [Setfield.jl](https://github.com/jw3126/Setfield.jl).

```julia
julia> using Setfield, Kaleido

julia> ml = MultiLens((
           (@lens _.x),
           (@lens _.y.z) ∘ toℝ₊,
       ));

julia> @assert get((x=1, y=(z=1.0,)), ml) == (1, 0.0)

julia> @assert set((x=1, y=(z=2,)), ml, ("x", -1)) == (x="x", y=(z=exp(-1),))

julia> l = MultiLens((
           (@lens _.x) ∘ IndexBatchLens(:a, :b, :c),
           (@lens _.y) ∘ IndexBatchLens(:d, :e),
       )) ∘ BijectionLens(
           ((x, y),) -> (x..., y...),
           xs -> (xs[1:3], xs[4:5]),
       );

julia> @assert get((x=(a=1, b=2, c=3), y=(d=4, e=5)), l) === (1, 2, 3, 4, 5)

julia> @assert set((x=(a=1, b=2, c=3), y=(d=4, e=5)), l, (10, 20, 30, 40, 50)) ===
           (x=(a=10, b=20, c=30), y=(d=40, e=50))
```

Kaleido.jl also works with `AbstractTransform` defined in
[TransformVariables.jl](https://github.com/tpapp/TransformVariables.jl):

```julia
julia> using Setfield, Kaleido, TransformVariables

julia> l = (@lens _.y[2]) ∘ BijectionLens(as𝕀);

julia> obj = (x=0, y=(1, 0.5, 3));

julia> @assert get(obj, l) == 0

julia> @assert set(obj, l, Inf).y[2] ≈ 1
```
