using .TransformVariables: AbstractTransform, transform, inverse

struct XFBijection{T} <: Bijection
    xf::T
end

Bijection(xf::AbstractTransform) = XFBijection(xf)
inward(b::XFBijection, x) = transform(b.xf, x)
outward(b::XFBijection, y) = inverse(b.xf, y)

Base.show(io::IO, lens::BijectionLens{<:XFBijection}) =
    print_apply(io, typeof(lens), _getfields(lens.bijection))
