abstract type Mutability end
struct Immutable <: Mutability end
struct Mutable <: Mutability end

Mutability(::Any) = Mutable()
Mutability(::Union{Tuple, NamedTuple}) = Immutable()

setindices(obj, batch) = setindices(Mutability(obj), obj, batch)
setkeys(obj, batch) = setkeys(Mutability(obj), obj, batch)

_eachindex(x) = eachindex(x)
_eachindex(x::NamedTuple) = Base.OneTo(length(x))

function setindices(::Mutable, obj, batch)
    out = copy(obj)
    for i in _eachindex(batch)
        out[i] = batch[i]
    end
    return out
end

setindices(::Immutable, obj, batch) =
    _mapfoldl(i -> (i, batch[i]),
              (obj′, (i, v)) -> set(obj′, (@lens _[i]), v),
              Tuple(_eachindex(batch)),
              obj)

function setkeys(::Mutable, obj, batch)
    out = copy(obj)
    for (k, v) in pairs(batch)
        out[k] = v
    end
    return out
end

setkeys(::Immutable, obj, batch) =
    _foldl(Tuple(pairs(batch)), obj) do obj, (k, v)
        set(obj, (@lens _[k]), v)
    end
