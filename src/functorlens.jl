"""
    FLens(functor_based_lens) :: Lens

`FLens` provides an alternative ("isomorphic") way to create a `Lens`.
It is useful for accessing dynamically determined "field" such as the
last item in the linked list.

(Note: it's probably better to look at Examples first.)

`FLens` converts `functor_based_lens` (a two-argument callable) to the
`Lens` defined in `Setfield`.  The callable `functor_based_lens`
accepts the following two arguments:

1. `setter`: a one-argument callable that accepts a value in the
   "field" and return an object that can be passed to the second
   argument of `Kaleido.fmap`.

2. `obj`: an object whose "field" is accessed.

_Informally_ the signature of the functions appeared above may be written as

```julia
FLens(functor_based_lens) :: Lens
functor_based_lens(setter, obj)
setter(field::A) :: F{A} where {F <: Functor}
fmap(f, ::F{A}) :: F{B} where {F <: Functor}
f(field::A) :: B
```

(note: there is no `Functor` in actual code)


# Examples

Here is an implementation of `@lens _[1]` using `FLens`

```jldoctest
julia> using Setfield

julia> using Kaleido: FLens, fmap

julia> fst = FLens((f, obj) -> fmap(x -> (x, obj[2:end]...), f(obj[1])));

julia> get((1, 2, 3), fst)
1

julia> set((1, 2, 3), fst, 100)
(100, 2, 3)
```

A typical `FLens` usage has the form

```julia
FLens((f, obj) -> fmap(x -> SET(obj, x), f(GET(obj))))
```

where

* `SET(obj, x)` sets the "field" of the `obj` to the value `x`.
* `GET(obj)` gets the value of the "field."

What `GET` and `SET` does may look like similar to `Setfield.get` and
`Setfield.set`.  In fact, any lens can be converted into `FLens`:

```jldoctest
julia> using Setfield

julia> using Kaleido: FLens, fmap

julia> asflens(lens::Lens) =
           FLens((f, obj) -> fmap(x -> set(obj, lens, x), f(get(obj, lens))));

julia> dot_a = asflens(@lens _.a);

julia> get((a=1, b=2), dot_a)
1

julia> set((a=1, b=2), dot_a, 100)
(a = 100, b = 2)
```

If `FLens` is "isomorphic" to usual `Lens`, why not directly define
`Setfield.get` and `Setfield.set`?  (They are easier to understand.)

This is because `FLens` is useful if the "field" of interest can only
be dynamically determined.  For example, a lens to the last item of
linked lists can be defined as follows:

```jldoctest
julia> using Setfield

julia> using Kaleido: FLens, fmap

julia> struct Cons{T, S}
           car::T
           cdr::S
       end

julia> last_impl(f, list, g) =
           if list.cdr === nothing
               h = x -> g(Cons(x, nothing))
               fmap(h, f(list.car))
           else
               h = x -> g(Cons(list.car, x))
               last_impl(f, list.cdr, h)
           end;

julia> lst = FLens((f, list) -> last_impl(f, list, identity));

julia> list = Cons(1, Cons(2, Cons(3, nothing)));

julia> get(list, lst)
3

julia> set(list, lst, :last) === Cons(1, Cons(2, Cons(:last, nothing)))
true
```

Notice that `last_impl` dynamically builds the closure `h` that is
passed as the first argument of `fmap`.  Although it is possible to
implement the same lens by directly defining `Setfield.get` and
`Setfield.set`, those two functions would have duplicated code for
recursing into the last item.

Another (marginal?) benefit is that `FLens` can be more efficient when
using `modify`.  This is because `FLens` can do `modify` in one
recursion into the "field" while two recursions are necessary with
`get` and `set`.  It can be relevant especially with complex object
and lens where `get` and `set` used in `modify` cannot be inlined
(e.g., due to type instability).

`FLens` can also be used for imposing some constraints in the fields.
However, it may be better to use [`constraining`](@ref) for this
purpose.

```jldoctest
julia> using Setfield

julia> using Kaleido: FLens, fmap

julia> fstsnd = FLens((f, obj) -> fmap(
           x -> (x, x, obj[3:end]...),
           begin
               @assert obj[1] == obj[2]
               f(obj[1])
           end,
       ));

julia> get((1, 1, 2), fstsnd)
1

julia> set((1, 1, 2), fstsnd, 100)
(100, 100, 2)
```

# Side notes

`FLens` mimics the formalism used in
[the lens in Haskell](http://hackage.haskell.org/package/lens).
For an introduction to lens, the talk
[Lenses: compositional data access and manipulation](https://skillsmatter.com/skillscasts/4251-lenses-compositional-data-access-and-manipulation)
by Simon Peyton Jones is highly recommended.  In this talk, a
simplified form of lens uses in Haskell is explained in details:

```haskell
type Lens' s a = forall f. Functor f
                        => (a -> f a) -> s -> f s
```

Informally, this type synonym maps to the signature of `FLens`:

```julia
FLens(((::A -> ::F{A}), ::S) -> ::F{S} where F <: Functor) :: Lens
```
"""
struct FLens{T} <: Lens
    f::T
end

struct FConst{T}  # constant functor
    value::T
end

struct FIdentity{T}  # identity functor
    value::T
end

# fmap(f, ::F{A}) :: F{B} where {F <: Functor}
fmap(f, x::FConst) = x
fmap(f, x::FIdentity) = FIdentity(f(x.value))
frun(x) = x.value

Setfield.get(obj, lens::FLens) = frun(lens.f(FConst, obj))
Setfield.set(obj, lens::FLens, val) = frun(lens.f(_ -> FIdentity(val), obj))
Setfield.modify(f, obj, lens::FLens) = frun(lens.f(FIdentity ∘ f, obj))

# NOTE: Do NOT confuse the fake "type parameter" `A` of `F{A}` with
# the actual type parameter `T` of `FConst{T}`.  The types `F{A}` and
# `F{B}` do not actually exist in Julian type system.  (In case of
# `FIdentity`, the fake "type parameters" `A` and `B` actually match
# with the real type parameter `T` of `FIdentity` by accident.)
# Informally, those fake "type parameters" can be explicitly written
# as
#
# fmap(f::(::A -> ::B), x::FConst{T}{A}) = x ::FConst{T}{B}
# fmap(f::(::A -> ::B), x::FIdentity{A}) = FIdentity{B}(f(x.value))
#
# i.e., `F = FConst{T}` while `F = FIdentity`.

curry(f) = x -> y -> f(x, y)
uncurry(f) = (x, y) -> f(x)(y)

fcompose(a::FLens, b::FLens) = FLens(uncurry(curry(a.f) ∘ curry(b.f)))

#=
function fcompose(a::FLens, b::FLens)
    fa(f) = obj -> a.f(f, obj)
    fb(f) = obj -> b.f(f, obj)
    fc = fa ∘ fb
    FLens((f, obj) -> fc(f)(obj))
end

fcompose(a::FLens, b::FLens) = FLens((f, obj) -> a.f(obj -> b.f(f, obj), obj))
=#
