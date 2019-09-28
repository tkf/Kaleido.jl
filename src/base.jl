"""
    KaleidoLens <: Lens

Internal abstract type for Kaleido.jl.
"""
abstract type KaleidoLens <: Lens end

_getfields(obj) = map(n -> getfield(obj, n), fieldnames(typeof(obj))) :: Tuple

struct Prefixed
    prefix::String
    name::Symbol
end

prefixof(f) = join(fullname(parentmodule(f)), '.')
prefixof(f::Prefixed) = f.prefix
Base.nameof(f::Prefixed) = f.name

function print_apply(io, f, args)
    if !get(io, :limit, false)
        # Don't show full name in REPL etc.:
        print(io, prefixof(f), '.')
    end
    print(io, nameof(f))
    if length(args) == 1
        print(io, '(')
        show(io, args[1])
        print(io, ')')
    else
        show(io, args)
    end
    return
end

_default_show(io, obj) = print_apply(io, typeof(obj), _getfields(obj))

Base.show(io::IO, lens::KaleidoLens) = _default_show(io, lens)
Base.show(io::IO, ::MIME"text/plain", lens::KaleidoLens) = prettylens(io, lens)

_constructor_of(x) = Setfield.constructor_of(x)
_constructor_of(::Type{<:NamedTuple{names}}) where names = NamedTuple{names}
_constructor_of(::Type{<:Tuple}) = Tuple

"""
    prefer_singleton_callable(f)

Convert `f` to an callable singleton object if possible.  Useful if `f`
is a `Type`.

# Examples
```jldoctest
julia> using Kaleido: prefer_singleton_callable

julia> sizeof((Int,))
8

julia> sizeof((prefer_singleton_callable(Int),))
0

julia> prefer_singleton_callable(Int)(1.0)
1
```
"""
prefer_singleton_callable(::Type{T}) where T = SingletonCallable{T}()
prefer_singleton_callable(f) = f

struct SingletonCallable{T} end
(::SingletonCallable{T})(x) where T = T(x)

@nospecialize
_singleton_callable(::SingletonCallable{T}) where T = T
_singleton_callable(f) = f
@specialize

## Specialized foldl

_tail(t) = Base.tail(t)
_tail(t::NamedTuple{names}) where names = NamedTuple{Base.tail(names)}(t)

struct _Zip{T1, T2}
    it1::T1
    it2::T2
end

const EmptyTuple = Union{Tuple{}, NamedTuple{(),Tuple{}}}
const EmptyItr = Union{EmptyTuple, _Zip{<:EmptyTuple, <:EmptyTuple}}
const AnyItr = Union{Tuple, NamedTuple, _Zip}
const _zip = _Zip

@inline _tail(it::_Zip) = _Zip(_tail(it.it1), _tail(it.it2))
@inline Base.getindex(it::_Zip, i) = (it.it1[i], it.it2[i])

@inline _mapfoldl(::Any, ::Any, ::EmptyItr, init) = init
@inline _mapfoldl(f, op, xs::AnyItr, init) =
    _mapfoldl(f, op, _tail(xs), op(init, f(xs[1])))

@inline _foldl(op, xs, init) = _mapfoldl(identity, op, xs, init)

_enumerate(xs) = _zip(ntuple(identity, length(xs)), xs)

_push(xs, x) = (xs..., x)
_map(f, xs) = _mapfoldl(f, _push, xs, ())

_cat() = ()
_cat(xs, tuples...) = (xs..., _cat(tuples...)...)

headtail(xs) = _headtail(xs...)
_headtail(x1, xs...) = (x1, xs)

newpartition(x, by) = (
    key = by(x),
    values = (x,),
    by = by,
)

function partitionby(values::Tuple, by)
    x, rest = headtail(values)
    return _foldl(_partitionstep, rest, (newpartition(x, by),))
end

_partitionstep(partitions, x) =
    if partitions[end].by(x) == partitions[end].key
        modify(partitions, @lens _[length(partitions)].values) do values
            _push(values, x)
        end
    else
        _push(partitions, newpartition(x, partitions[end].by))
    end
