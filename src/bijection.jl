"""
    BijectionLens(inward, outward) :: Lens
    BijectionLens(xf::TransformVariables.AbstractTransform) :: Lens

# Examples
```jldoctest
julia> using Setfield, Kaleido

julia> l = (@lens _.y[2]) ∘ BijectionLens(x -> 2x, x -> x/2);

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

struct FunctionPair{TI, TO} <: Bijection
    inward::TI
    outward::TO
end

inward(b::FunctionPair, x) = b.inward(x)
outward(b::FunctionPair, y) = b.outward(y)

struct BijectionLens{TB <: Bijection} <: KaleidoLens
    bijection::TB
end

Setfield.get(obj, l::BijectionLens) = outward(l.bijection, obj)
Setfield.set(::Any, l::BijectionLens, x) = inward(l.bijection, x)

BijectionLens(inward, outward) = BijectionLens(FunctionPair(inward, outward))
BijectionLens(thing) = BijectionLens(Bijection(thing))

Base.show(io::IO, lens::BijectionLens{<:FunctionPair}) =
    print_apply(io, typeof(lens), _getfields(lens.bijection))


# Taken from TransformVariables:
logistic(x::Real) = inv(one(x) + exp(-x))
logit(x::Real) = log(x / (one(x) - x))

"""
    toℝ₊ :: BijectionLens

# Examples
```jldoctest
julia> using Setfield, Kaleido

julia> l = (@lens _.y[2]) ∘ toℝ₊;

julia> obj = (x=0, y=(0, 1, 2));

julia> @assert get(obj, l) == 0.0 == log(obj.y[2])

julia> @assert set(obj, l, -1) == (x=0, y=(0, exp(-1), 2))
```
"""
const toℝ₊ = BijectionLens(exp, log)

"""
    toℝ₋ :: BijectionLens

# Examples
```jldoctest
julia> using Setfield, Kaleido

julia> l = (@lens _.y[2]) ∘ toℝ₋;

julia> obj = (x=0, y=(0, -1, 2));

julia> @assert get(obj, l) == 0.0 == log(-obj.y[2])

julia> @assert set(obj, l, 1) == (x=0, y=(0, -exp(1), 2))
```
"""
const toℝ₋ = BijectionLens((-) ∘ exp, log ∘ -)

"""
    to𝕀 :: BijectionLens

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
const to𝕀 = BijectionLens(logistic, logit)
