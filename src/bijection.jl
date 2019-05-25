"""
    BijectionLens(inward, outward) :: Lens
"""
BijectionLens

struct BijectionLens{TI, TO} <: Lens
    inward::TI
    outward::TO
end

Setfield.get(obj, l::BijectionLens) = l.outward(obj)
Setfield.set(::Any, l::BijectionLens, x) = l.inward(x)
