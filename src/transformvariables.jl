using .TransformVariables: AbstractTransform, transform, inverse

setting(xf::AbstractTransform) = _setting(xf)
getting(xf::AbstractTransform) = _getting(xf)

struct XFBijection{INV, T} <: Bijection
    xf::T
end

XFBijection{INV}(xf::T) where {INV, T} = XFBijection{INV, T}(xf)
XFBijection(xf) = XFBijection{false}(xf)

Base.inv(bijection::XFBijection{INV}) where INV = XFBijection{!INF}(bijection.xf)

Bijection(xf::AbstractTransform) = XFBijection(xf)
tofield(b::XFBijection{false}, x) = transform(b.xf, x)
fromfield(b::XFBijection{false}, y) = inverse(b.xf, y)
tofield(b::XFBijection{true}, x) = inverse(b.xf, x)
fromfield(b::XFBijection{true}, y) = transform(b.xf, y)

Base.show(io::IO, lens::BijectionLens{<:XFBijection}) =
    print_apply(io, typeof(lens), _getfields(lens.bijection))
