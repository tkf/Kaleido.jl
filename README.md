# Kaleido: some useful lenses

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://tkf.github.io/Kaleido.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://tkf.github.io/Kaleido.jl/dev)
[![Build Status](https://travis-ci.com/tkf/Kaleido.jl.svg?branch=master)](https://travis-ci.com/tkf/Kaleido.jl)
[![Codecov](https://codecov.io/gh/tkf/Kaleido.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/tkf/Kaleido.jl)
[![Coveralls](https://coveralls.io/repos/github/tkf/Kaleido.jl/badge.svg?branch=master)](https://coveralls.io/github/tkf/Kaleido.jl?branch=master)

Kaleido.jl is a collection of useful
[`Lens`](https://jw3126.github.io/Setfield.jl/latest/index.html#Setfield.Lens)es
that enhance [Setfield.jl](https://github.com/jw3126/Setfield.jl).

```jldoctest
julia> using Setfield, Kaleido

julia> ml = MultiLens((
           (@lens _.x),
           (@lens _.y.z) ∘ toℝ₊,
       ));

julia> @assert get((x=1, y=(z=1.0,)), ml) == (1, 0.0)

julia> @assert set((x=1, y=(z=2,)), ml, ("x", -1)) == (x="x", y=(z=exp(-1),))
```

Kaleido.jl also works with `AbstractTransform` defined in
[TransformVariables.jl](https://github.com/tpapp/TransformVariables.jl):

```jldoctest
julia> using Setfield, Kaleido, TransformVariables

julia> l = (@lens _.y[2]) ∘ BijectionLens(as𝕀);

julia> obj = (x=0, y=(1, 0.5, 3));

julia> @assert get(obj, l) == 0

julia> @assert set(obj, l, Inf).y[2] ≈ 1
```
