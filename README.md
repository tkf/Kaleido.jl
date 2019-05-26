# Kaleido: some useful lenses

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://tkf.github.io/Kaleido.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://tkf.github.io/Kaleido.jl/dev)
[![Build Status](https://travis-ci.com/tkf/Kaleido.jl.svg?branch=master)](https://travis-ci.com/tkf/Kaleido.jl)
[![Codecov](https://codecov.io/gh/tkf/Kaleido.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/tkf/Kaleido.jl)
[![Coveralls](https://coveralls.io/repos/github/tkf/Kaleido.jl/badge.svg?branch=master)](https://coveralls.io/github/tkf/Kaleido.jl?branch=master)
[![Aqua QA](https://img.shields.io/badge/Aqua.jl-%F0%9F%8C%A2-aqua.svg)](https://github.com/tkf/Aqua.jl)

Kaleido.jl is a collection of useful
[`Lens`](https://jw3126.github.io/Setfield.jl/latest/index.html#Setfield.Lens)es
and helper functions/macros built on top of
[Setfield.jl](https://github.com/jw3126/Setfield.jl).  For example, it
provides a macro `@batchlens` to update various nested locations in a
complex immutable object:

```julia
julia> using Setfield, Kaleido

julia> lens = @batchlens begin
           _.a.b.c
           _.a.b.d[1]
           _.a.b.d[3] ∘ to𝕀
           _.a.e
       end;

julia> obj = (a = (b = (c = 1, d = (2, 3, 0.5)), e = 5),);

julia> get(obj, lens)
(1, 2, 0.0, 5)

julia> set(obj, lens, (10, 20, Inf, 50))
(a = (b = (c = 10, d = (20, 3, 1.0)), e = 50),)
```

Behind the scene, `@batchlens` composes various `Lens`es from
Setfield.jl and Kaleido.jl to do its job.  Those lenses are also
useful by themselves.  For example, the lens `to𝕀` above (the naming
is borrowed from TransformVariables.jl) can be used to access a
property/field/location of an object using different parametrization.
Those lenses can be composed manually for accessing and modifying of
immutable object in more flexible manner.

```julia
julia> using Setfield, Kaleido

julia> lens = MultiLens((
           (@lens _.x),
           (@lens _.y.z) ∘ toℝ₊,
       ));

julia> @assert get((x=1, y=(z=1.0,)), lens) == (1, 0.0)

julia> @assert set((x=1, y=(z=2,)), lens, ("x", -1)) == (x="x", y=(z=exp(-1),))

julia> lens = MultiLens((
           (@lens _.x) ∘ IndexBatchLens(:a, :b, :c),
           (@lens _.y) ∘ IndexBatchLens(:d, :e),
       )) ∘ FlatLens(3, 2);

julia> @assert get((x=(a=1, b=2, c=3), y=(d=4, e=5)), lens) === (1, 2, 3, 4, 5)

julia> @assert set((x=(a=1, b=2, c=3), y=(d=4, e=5)), lens, (10, 20, 30, 40, 50)) ===
           (x=(a=10, b=20, c=30), y=(d=40, e=50))
```

Kaleido.jl also works with `AbstractTransform` defined in
[TransformVariables.jl](https://github.com/tpapp/TransformVariables.jl):

```julia
julia> using Setfield, Kaleido, TransformVariables

julia> lens = (@lens _.y[2]) ∘ BijectionLens(as𝕀);

julia> obj = (x=0, y=(1, 0.5, 3));

julia> @assert get(obj, lens) == 0

julia> @assert set(obj, lens, Inf).y[2] ≈ 1
```
