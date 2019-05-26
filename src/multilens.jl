"""
    MultiLens([castout,] lenses::Tuple)
    MultiLens([castout,] lenses::NamedTuple)

# Examples
```jldoctest
julia> using Setfield, Kaleido

julia> ml = MultiLens((
           (@lens _.x),
           (@lens _.y.z),
       ));

julia> @assert get((x=1, y=(z=2,)), ml) === (1, 2)

julia> @assert set((x=1, y=(z=2,)), ml, ("x", "y.z")) === (x="x", y=(z="y.z",))

julia> ml = MultiLens((
           a = (@lens _.x),
           b = (@lens _.y.z),
       ));

julia> @assert get((x=1, y=(z=2,)), ml) === (a=1, b=2)

julia> @assert set((x=1, y=(z=2,)), ml, (a=:x, b="y.z")) === (x=:x, y=(z="y.z",))

julia> @assert set((x=1, y=(z=2,)), ml, (b="y.z", a=:x)) === (x=:x, y=(z="y.z",))

julia> using StaticArrays

julia> ml = MultiLens(
           SVector,
           (
               (@lens _.x),
               (@lens _.y.z),
           )
       );

julia> @assert get((x=1, y=(z=2,)), ml) === SVector(1, 2)
```
"""
MultiLens

const Lenses{N} = NTuple{N, Lens}
const NamedLenses{N, names} = NamedTuple{names, <:Lenses{N}}
const AnyLenses{N} = Union{Lenses{N}, NamedLenses{N}}

struct MultiLens{N, TL <: AnyLenses{N}, TO} <: KaleidoLens
    castout::TO
    lenses::TL

    global _MultiLens(castout::TO, lenses::TL) where {N, TL <: AnyLenses{N}, TO} =
        new{N, TL, TO}(castout, lenses)
end

MultiLens(castout, lenses) =
    _MultiLens(prefer_singleton_callable(castout), lenses)

MultiLens(lenses::Lenses) = MultiLens(identity, lenses)
MultiLens(lenses::NamedTuple{names, <:Lenses}) where names =
    MultiLens(NamedTuple{names}, lenses)

_getall(obj, lenses) = map(l -> get(obj, l), lenses)

Setfield.get(obj, ml::MultiLens) = ml.castout(_getall(obj, ml.lenses))

Setfield.set(obj, ml::MultiLens, val) = _set(obj, ml, val)

_set(
    obj,
    ml::MultiLens{N, <:Lenses{N}},
    val::Union{NTuple{N, Any}, AbstractArray}
) where N =
    _foldl(_zip(ml.lenses, val), obj) do obj, (l, v)
        set(obj, l, v)
    end

_set(
    obj,
    ml::MultiLens{N, <:NamedLenses{N, names}},
    val::Union{NamedTuple{<:Any, <:NTuple{N, Any}}, AbstractDict}
) where {N, names} =
    _set(
        obj,
        MultiLens(Tuple(ml.lenses)),
        map(n -> val[n], names) :: Tuple,
    )
