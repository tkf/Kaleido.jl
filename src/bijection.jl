"""
    BijectionLens(fromfield, tofield) :: Lens
    BijectionLens(xf::TransformVariables.AbstractTransform) :: Lens

# Examples
```jldoctest
julia> using Setfield, Kaleido

julia> l = (@lens _.y[2]) ∘ BijectionLens(x -> x/2, x -> 2x);

julia> obj = (x=0, y=(1, 2, 3));

julia> @assert get(obj, l) == 1.0 == 2/2

julia> @assert set(obj, l, 0.5) == (x=0, y=(1, 1.0, 3))
```

```jldoctest
julia> using Setfield, Kaleido, TransformVariables

julia> l = (@lens _.y[2]) ∘ BijectionLens(as𝕀);

julia> obj = (x=0, y=(1, 0.5, 3));

julia> @assert get(obj, l) == 0

julia> @assert set(obj, l, Inf).y[2] ≈ 1

julia> @assert set(obj, l, -Inf).y[2] ≈ 0.0
```
"""
BijectionLens

abstract type Bijection end

struct FunctionPair{TO, TI} <: Bijection
    fromfield::TO
    tofield::TI
end

tofield(b::FunctionPair, x) = b.tofield(x)
fromfield(b::FunctionPair, y) = b.fromfield(y)

struct BijectionLens{TB <: Bijection} <: KaleidoLens
    bijection::TB
end

Setfield.get(obj, l::BijectionLens) = fromfield(l.bijection, obj)
Setfield.set(::Any, l::BijectionLens, x) = tofield(l.bijection, x)

BijectionLens(fromfield, tofield) = BijectionLens(FunctionPair(fromfield, tofield))
BijectionLens(thing) = BijectionLens(Bijection(thing))

Base.show(io::IO, lens::BijectionLens{<:FunctionPair}) =
    print_apply(io, typeof(lens), _getfields(lens.bijection))


# Taken from TransformVariables:
logistic(x::Real) = inv(one(x) + exp(-x))
logit(x::Real) = log(x / (one(x) - x))

"""
    toℝ₊ :: BijectionLens

This is a stripped-down version of `BijectionLens(TransformVariables.asℝ₊)`
that works without TransformVariables.jl.

# Examples
```jldoctest
julia> using Setfield, Kaleido

julia> l = (@lens _.y[2]) ∘ toℝ₊;

julia> obj = (x=0, y=(0, 1, 2));

julia> @assert get(obj, l) == 0.0 == log(obj.y[2])

julia> @assert set(obj, l, -1) == (x=0, y=(0, exp(-1), 2))
```
"""
const toℝ₊ = BijectionLens(log, exp)

"""
    toℝ₋ :: BijectionLens

This is a stripped-down version of `BijectionLens(TransformVariables.asℝ₋)`
that works without TransformVariables.jl.

# Examples
```jldoctest
julia> using Setfield, Kaleido

julia> l = (@lens _.y[2]) ∘ toℝ₋;

julia> obj = (x=0, y=(0, -1, 2));

julia> @assert get(obj, l) == 0.0 == log(-obj.y[2])

julia> @assert set(obj, l, 1) == (x=0, y=(0, -exp(1), 2))
```
"""
const toℝ₋ = BijectionLens(log ∘ -, (-) ∘ exp)

"""
    to𝕀 :: BijectionLens

This is a stripped-down version of `BijectionLens(TransformVariables.as𝕀)`
that works without TransformVariables.jl.

# Examples
```jldoctest
julia> using Setfield, Kaleido

julia> l = (@lens _.y[2]) ∘ to𝕀;

julia> obj = (x=0, y=(0, 0.5, 2));

julia> @assert get(obj, l) == 0.0

julia> @assert set(obj, l, Inf).y[2] ≈ 1

julia> @assert set(obj, l, -Inf).y[2] ≈ 0
```
"""
const to𝕀 = BijectionLens(logit, logistic)
