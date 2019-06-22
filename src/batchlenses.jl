"""
    PropertyBatchLens(names)

# Examples
```jldoctest
julia> using Setfield, Kaleido

julia> lens = PropertyBatchLens(:a, :b, :c);

julia> get((a=1, b=2, c=3, d=4), lens)
(a = 1, b = 2, c = 3)

julia> set((a=1, b=2, c=3, d=4), lens, (a=10, b=20, c=30))
(a = 10, b = 20, c = 30, d = 4)
```
"""
PropertyBatchLens

"""
    KeyBatchLens(names)

# Examples
```jldoctest
julia> using Setfield, Kaleido

julia> lens = KeyBatchLens(:a, :b, :c);

julia> get((a=1, b=2, c=3, d=4), lens)
(a = 1, b = 2, c = 3)

julia> set((a=1, b=2, c=3, d=4), lens, Dict(:a=>10, :b=>20, :c=>30))
(a = 10, b = 20, c = 30, d = 4)
```
"""
KeyBatchLens

"""
    IndexBatchLens(names)

# Examples
```jldoctest
julia> using Setfield, Kaleido

julia> lens = IndexBatchLens(:a, :b, :c);

julia> get((a=1, b=2, c=3, d=4), lens)
(1, 2, 3)

julia> set((a=1, b=2, c=3, d=4), lens, (10, 20, 30))
(a = 10, b = 20, c = 30, d = 4)
```
"""
IndexBatchLens

@enum Accessor INDEX KEY PROPERTY

struct BatchLens{names, objacc, valueacc} <: Lens end
const PropertyBatchLens{names} = BatchLens{names, PROPERTY, PROPERTY}
const KeyBatchLens{names} = BatchLens{names, PROPERTY, KEY}
const IndexBatchLens{names} = BatchLens{names, PROPERTY, INDEX}

lenstypenameof(::BatchLens{<:Any, PROPERTY, valueacc}) where valueacc =
    Dict(
        PROPERTY => :PropertyBatchLens,
        KEY => :KeyBatchLens,
        INDEX => :IndexBatchLens,
    )[valueacc]

setter(objacc::Accessor) = setter(Val(objacc))
setter(::Val{INDEX}) = setindices
setter(::Val{KEY}) = setkeys
setter(::Val{PROPERTY}) = setproperties

Setfield.set(obj, ::BatchLens{names, objacc, INDEX}, val) where {names, objacc} =
    setter(objacc)(obj, NamedTuple{names}(Tuple(val)))

Setfield.set(obj, ::BatchLens{names, objacc, KEY}, val) where {names, objacc} =
    setter(objacc)(obj, NamedTuple{names}(map(n -> val[n], names)))

Setfield.set(obj, ::BatchLens{names, objacc, PROPERTY}, val) where {names, objacc} =
    setter(objacc)(obj, NamedTuple{names}(map(n -> getproperty(val, n), names)))

_get(::Val{INDEX}, obj, (i, name)) = getindex(obj, i)
_get(::Val{KEY}, obj, (i, name)) = getindex(obj, name)
_get(::Val{PROPERTY}, obj, (i, name)) = getproperty(obj, name)
_get(acc::Accessor, obj) = x -> _get(Val(acc), obj, x)

getastuple(obj, ::BatchLens{names, objacc}) where {names, objacc} =
    _map(_get(objacc, obj), _enumerate(names))

Setfield.get(obj, lens::BatchLens{<:Any, <:Any, INDEX}) = getastuple(obj, lens)
Setfield.get(obj, lens::Union{BatchLens{names, <:Any, KEY},
                              BatchLens{names, <:Any, PROPERTY}}) where names =
    NamedTuple{names}(getastuple(obj, lens))

BatchLens{<:Any, objacc, valueacc}(names::Vararg{Symbol}) where {objacc, valueacc} =
    BatchLens{names, objacc, valueacc}()

Base.show(io::IO, lens::BatchLens{names, PROPERTY}) where names =
    print_apply(io, Prefixed(prefixof(BatchLens), lenstypenameof(lens)), names)
