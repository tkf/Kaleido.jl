"""
    getting(f) :: Lens

Apply a callable `f` (typically a type constructor) before getting the
value; i.e.,

```
get(obj, lens ∘ getting(f)) == f(get(obj, lens))
```

This is useful for, e.g., getting a tuple as a `StaticVector` and
converting it back to a tuple when setting.

Note that `getting` requires some properties for `f` and the values
stored in the "field."  See the details below.

# Examples
```jldoctest
julia> using Kaleido, Setfield, StaticArrays

julia> obj = (x = ((0, 1, 2), "A"), y = "B");

julia> lens = (@lens _.x[1]) ∘ getting(SVector);

julia> get(obj, lens) === SVector(obj.x[1])
true

julia> set(obj, lens, SVector(3, 4, 5))
(x = ((3, 4, 5), "A"), y = "B")
```

```jldoctest
julia> using Kaleido, Setfield, StaticArrays

julia> obj = (x = ((a = 0, b = 1, c = 2), "A"), y = "B");

julia> lens = (@lens _.x[1]) ∘ getting(Base.splat(SVector));

julia> get(obj, lens) === SVector(obj.x[1]...)
true

julia> set(obj, lens, SVector(3, 4, 5))
(x = ((a = 3, b = 4, c = 5), "A"), y = "B")
```

# Details

The lens created by `getting(f)` relies on that:

* The output value `y = f(x)` can be converted back to the original
  value `x` by `C(y)` where `C` is a constructor of `x`; i.e., for any
  `x` that could be retrieved from the object through this lens,

  ```
  C(f(x)) == x
  ```

* The conversion in the reverse direction also holds; i.e., for any
  `y` that could be stored into the object through this lens,

  ```
  f(C(y)) == y
  ```

The constructor `C` can be controlled by defining
`Setfield.constructor_of` for custom types of `x`.
"""
getting(f) = ConverterLens(prefer_singleton_callable(f))

struct ConverterLens{T} <: Lens
    f::T
end

Setfield.get(obj, lens::ConverterLens) = lens.f(obj)
Setfield.set(obj, ::ConverterLens, value) = _constructor_of(typeof(obj))(value)
