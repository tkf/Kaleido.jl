"""
    converting(; fromfield, tofield) :: Lens

# Examples
```jldoctest
julia> using Setfield, Kaleido

julia> l = (@lens _.y[2]) ∘ converting(fromfield = x -> x/2, tofield = x -> 2x);

julia> obj = (x=0, y=(1, 2, 3));

julia> @assert get(obj, l) == 1.0 == 2/2

julia> set(obj, l, 0.5)
(x = 0, y = (1, 1.0, 3))
```
"""
converting

"""
    setting(xf::TransformVariables.AbstractTransform) :: Lens

Lens to set value transformed by `xf` (and get value via the inverse
transformation).

# Examples
```jldoctest
julia> using Setfield, Kaleido, TransformVariables

julia> l = (@lens _.y[2]) ∘ setting(as𝕀);

julia> obj = (x=0, y=(1, 0.5, 3));

julia> get(obj, l)
0.0

julia> @assert set(obj, l, Inf).y[2] ≈ 1

julia> @assert set(obj, l, -Inf).y[2] ≈ 0.0
```
"""
function setting end

"""
    getting(xf::TransformVariables.AbstractTransform) :: Lens

Lens to get value transformed by `xf` (and set value via the inverse
transformation).
"""
function getting end

abstract type Bijection end

struct FunctionPair{TO, TI} <: Bijection
    fromfield::TO
    tofield::TI
end

Base.inv(bijection::FunctionPair) =
    FunctionPair(bijection.tofield, bijection.fromfield)

tofield(b::FunctionPair, x) = b.tofield(x)
fromfield(b::FunctionPair, y) = b.fromfield(y)

struct BijectionLens{TB <: Bijection} <: KaleidoLens
    bijection::TB
end

Setfield.get(obj, l::BijectionLens) = fromfield(l.bijection, obj)
Setfield.set(::Any, l::BijectionLens, x) = tofield(l.bijection, x)

BijectionLens(fromfield, tofield) = BijectionLens(FunctionPair(fromfield, tofield))
# TODO: remove `BijectionLens(fromfield, tofield)`

converting(; fromfield, tofield) =
    BijectionLens(FunctionPair(
        prefer_singleton_callable(fromfield),
        prefer_singleton_callable(tofield),
    ))

_setting(thing) = BijectionLens(Bijection(thing))
_getting(thing) = BijectionLens(inv(Bijection(thing)))

Base.show(io::IO, lens::BijectionLens{<:FunctionPair}) =
    print_apply(io, typeof(lens), _getfields(lens.bijection))

# Taken from TransformVariables:
logistic(x::Real) = inv(one(x) + exp(-x))
logit(x::Real) = log(x / (one(x) - x))

logneg(x) = log(-x)
negexp(x) = -exp(x)

"""
    settingasℝ₊ :: BijectionLens

This is a stripped-down version of `setting(asℝ₊)` that works without
TransformVariables.jl.

# Examples
```jldoctest
julia> using Setfield, Kaleido

julia> l = (@lens _.y[2]) ∘ settingasℝ₊;

julia> obj = (x=0, y=(0, 1, 2));

julia> @assert get(obj, l) == 0.0 == log(obj.y[2])

julia> @assert set(obj, l, -1) == (x=0, y=(0, exp(-1), 2))
```
"""
const settingasℝ₊ = converting(fromfield=log, tofield=exp)
const gettingasℝ₊ = converting(fromfield=exp, tofield=log)

"""
    settingasℝ₋ :: BijectionLens

This is a stripped-down version of `setting(asℝ₋)` that works without
TransformVariables.jl.

# Examples
```jldoctest
julia> using Setfield, Kaleido

julia> l = (@lens _.y[2]) ∘ settingasℝ₋;

julia> obj = (x=0, y=(0, -1, 2));

julia> @assert get(obj, l) == 0.0 == log(-obj.y[2])

julia> @assert set(obj, l, 1) == (x=0, y=(0, -exp(1), 2))
```
"""
const settingasℝ₋ = converting(fromfield=logneg, tofield=negexp)
const gettingasℝ₋ = converting(fromfield=negexp, tofield=logneg)

"""
    settingas𝕀 :: BijectionLens

This is a stripped-down version of `setting(as𝕀)` that works without
TransformVariables.jl.

# Examples
```jldoctest
julia> using Setfield, Kaleido

julia> l = (@lens _.y[2]) ∘ settingas𝕀;

julia> obj = (x=0, y=(0, 0.5, 2));

julia> get(obj, l)
0.0

julia> @assert set(obj, l, Inf).y[2] ≈ 1

julia> @assert set(obj, l, -Inf).y[2] ≈ 0
```
"""
const settingas𝕀 = converting(fromfield=logit, tofield=logistic)
const gettingas𝕀 = converting(fromfield=logistic, tofield=logit)
