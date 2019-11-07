# Kaleido: some useful lenses

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://tkf.github.io/Kaleido.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://tkf.github.io/Kaleido.jl/dev)
[![Build Status](https://travis-ci.com/tkf/Kaleido.jl.svg?branch=master)](https://travis-ci.com/tkf/Kaleido.jl)
[![Codecov](https://codecov.io/gh/tkf/Kaleido.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/tkf/Kaleido.jl)
[![Coveralls](https://coveralls.io/repos/github/tkf/Kaleido.jl/badge.svg?branch=master)](https://coveralls.io/github/tkf/Kaleido.jl?branch=master)
[![Aqua QA](https://img.shields.io/badge/Aqua.jl-%F0%9F%8C%A2-aqua.svg)](https://github.com/tkf/Aqua.jl)
[![GitHub commits since tagged version](https://img.shields.io/github/commits-since/tkf/Kaleido.jl/v0.2.1.svg?style=social&logo=github)](https://github.com/tkf/Kaleido.jl)

Kaleido.jl is a collection of useful
[`Lens`](https://jw3126.github.io/Setfield.jl/latest/index.html#Setfield.Lens)es
and helper functions/macros built on top of
[Setfield.jl](https://github.com/jw3126/Setfield.jl).

## Features

### Summary

* Batched/multi-valued update.  See `@batchlens`, `MultiLens`.
* Get/set multiple and nested fields as a `StaticArray` or any
  arbitrary multi-valued container.  See `getting`.
* Get/set fields with different parametrizations.
  See `converting`, `setting`, `getting`.
* Computing other fields during `set` and `get`; i.e., adding
  constraints between fields.  See `constraining`.
* Get/set dynamically computed locations.  See `FLens`.

### Batched/multi-valued update

Macro `@batchlens` can be used to update various nested locations in a
complex immutable object:

```julia
julia> using Setfield, Kaleido

julia> lens_batch = @batchlens begin
           _.a.b.c
           _.a.b.d[1]
           _.a.b.d[3] ∘ settingas𝕀
           _.a.e
       end;

julia> obj = (a = (b = (c = 1, d = (2, 3, 0.5)), e = 5),);

julia> get(obj, lens_batch)
(1, 2, 0.0, 5)

julia> set(obj, lens_batch, (10, 20, Inf, 50))
(a = (b = (c = 10, d = (20, 3, 1.0)), e = 50),)
```

(See below for what `settingas𝕀` does.)

### Get/set multiple and nested fields as a `StaticArray`

It is often useful to get the values of the fields as a vector (e.g.,
when optimizing a composite object with Optim.jl).  This can be done
with `getting(f)` where `f` is a constructor.

```julia
julia> using StaticArrays

julia> lens_vec = lens_batch ∘ getting(SVector);

julia> @assert get(obj, lens_vec) === SVector(1, 2, 0.0, 5)

julia> set(obj, lens_vec, SVector(10, 20, Inf, 50))
(a = (b = (c = 10.0, d = (20.0, 3, 1.0)), e = 50.0),)
```

### Get/set fields with different parametrizations

Kaleido.jl comes with lenses `settingasℝ₊`, `settingasℝ₋`, and
`settingas𝕀` to manipulating fields that have to be restricted to be
positive, negative, and in `[0, 1]` interval, respectively.  Similarly
there are lenses `gettingasℝ₊`, `gettingasℝ₋`, and `gettingas𝕀` to get
values in those domains.  The naming is borrowed from
[TransformVariables.jl](https://github.com/tpapp/TransformVariables.jl).

```julia
julia> lens = (@lens _.x) ∘ settingasℝ₊;

julia> get((x=1.0,), lens)  # log(1.0)
0.0

julia> set((x=1.0,), lens, -Inf)
(x = 0.0,)
```

Kaleido.jl also works with `AbstractTransform` defined in
[TransformVariables.jl](https://github.com/tpapp/TransformVariables.jl):

```julia
julia> using TransformVariables

julia> lens = (@lens _.y[2]) ∘ setting(as𝕀);

julia> obj = (x=0, y=(1, 0.5, 3));

julia> get(obj, lens)
0.0

julia> @assert set(obj, lens, Inf).y[2] ≈ 1
```

It also is quite easy to define ad-hoc converting accessors using
`converting`:

```julia
julia> lens = (@lens _.y[2]) ∘
           converting(fromfield=x -> parse(Int, x), tofield=string);

julia> obj = (x=0, y=(1, "5", 3));

julia> get(obj, lens)
5

julia> set(obj, lens, 1)
(x = 0, y = (1, "1", 3))
```

### Computing other fields during `set` and `get`

It is easy to add constraints between fields using `constraining`.
For example, you can impose that field `.c` must be a sum of `.a` and
`.b` by:

```julia
julia> obj = (a = 1, b = 2, c = 3);

julia> constraint = constraining() do obj
           @set obj.c = obj.a + obj.b
       end;

julia> lens = constraint ∘ MultiLens((
           (@lens _.a),
           (@lens _.b),
       ));

julia> get(obj, lens)
(1, 2)

julia> set(obj, lens, (100, 20))
(a = 100, b = 20, c = 120)
```

Notice that `.c` is updated as well in the last line.

### Get/set dynamically computed locations

You can use `FLens` to `get` and `set`, e.g., the last entry of a
linked list.
