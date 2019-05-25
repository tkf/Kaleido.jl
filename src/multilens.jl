const Lenses{N} = NTuple{N, Lens}
const NamedLenses{N, names} = NamedTuple{names, <:Lenses{N}}

struct MultiLens{N, L <: Union{Lenses{N}, NamedLenses{N}}} <: Lens
    lenses::L
end

_getall(obj, lenses) = map(l -> get(obj, l), lenses)

Setfield.get(obj, ml::MultiLens{N, <:Lenses{N}}) where {N} =
    _getall(obj, ml.lenses)
Setfield.get(obj, ml::MultiLens{N, <:NamedLenses{N, names}}) where {N, names} =
    NamedTuple{names}(_getall(obj, ml.lenses))

Setfield.set(obj, ml::MultiLens{N, <:Lenses{N}}, val::NTuple{N, Any}) where N =
    foldl(zip(ml.lenses, val); init=obj) do obj, (l, v)
        set(obj, l, v)
    end

Setfield.set(
    obj,
    ml::MultiLens{N, <:NamedLenses{N}},
    val::NamedTuple{names, <:NTuple{N, Any}}
) where {N, names} =
    foldl(zip(names, val); init=obj) do obj, (n, v)
        set(obj, getfield(ml.lenses, n), v)
    end
