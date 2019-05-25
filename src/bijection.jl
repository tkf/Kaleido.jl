"""
    BijectionLens(inward, outward) :: Lens
    BijectionLens(xf::TransformVariables.AbstractTransform) :: Lens
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
