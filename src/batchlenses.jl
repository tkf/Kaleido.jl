"""
    PropertyBatchLens(names)

"""
PropertyBatchLens

"""
    KeyBatchLens(names)

"""
KeyBatchLens

"""
    IndexBatchLens(names)

"""
IndexBatchLens

@enum Accessor INDEX KEY PROPERTY

struct BatchLens{names, objacc, valueacc} <: KaleidoLens end
const PropertyBatchLens{names} = BatchLens{names, PROPERTY, PROPERTY}
const KeyBatchLens{names} = BatchLens{names, PROPERTY, KEY}
const IndexBatchLens{names} = BatchLens{names, PROPERTY, INDEX}

BatchLens{<:Any, objacc, valueacc}(names::Vararg{Symbol}) where {objacc, valueacc} =
    BatchLens{names, objacc, valueacc}()

Setfield.set(obj, ::BatchLens{names, PROPERTY, INDEX}, val) where names =
    setproperties(obj, NamedTuple{names}(val))

Setfield.set(obj, ::BatchLens{names, PROPERTY, KEY}, val) where names =
    setproperties(obj, NamedTuple{names}(map(n -> val[n], names)))

Setfield.set(obj, ::BatchLens{names, PROPERTY, PROPERTY}, val) where names =
    setproperties(obj, NamedTuple{names}(map(n -> getproperty(val, n), names)))

_get(::Val{INDEX}, obj, x) = getindex(obj, x)
_get(::Val{KEY}, obj, x) = getindex(obj, x)
_get(::Val{PROPERTY}, obj, x) = getproperty(obj, x)
_get(acc::Accessor, obj) = x -> _get(Val(acc), obj, x)

getastuple(obj, ::BatchLens{names, objacc}) where {names, objacc} =
    map(_get(objacc, obj), names)

Setfield.get(obj, lens::BatchLens{<:Any, <:Any, INDEX}) = getastuple(obj, lens)
Setfield.get(obj, lens::Union{BatchLens{names, <:Any, KEY},
                              BatchLens{names, <:Any, PROPERTY}}) where names =
    NamedTuple{names}(getastuple(obj, lens))
