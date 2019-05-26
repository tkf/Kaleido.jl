"""
    MultiLens(lenses::Tuple)
    MultiLens(lenses::NamedTuple)

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
```
"""
MultiLens

const Lenses{N} = NTuple{N, Lens}
const NamedLenses{N, names} = NamedTuple{names, <:Lenses{N}}

struct MultiLens{N, L <: Union{Lenses{N}, NamedLenses{N}}} <: KaleidoLens
    lenses::L
end

_getall(obj, lenses) = map(l -> get(obj, l), lenses)

Setfield.get(obj, ml::MultiLens{N, <:Lenses{N}}) where {N} =
    _getall(obj, ml.lenses)
Setfield.get(obj, ml::MultiLens{N, <:NamedLenses{N, names}}) where {N, names} =
    NamedTuple{names}(_getall(obj, ml.lenses))

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
