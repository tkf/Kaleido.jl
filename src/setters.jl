abstract type Setter <: Lens end

Setfield.get(::Any, setter::Setter) = error("Setters do not support `get`.")

struct NullSetter <: Setter end
Setfield.set(obj, ::NullSetter, ::Any) = obj

"""
    nullsetter :: Setter

A setter that does nothing; i.e., `set(x, nullsetter, y) === x` for any
`x` and `y`.

# Examples
```jldoctest
julia> using Setfield, Kaleido

julia> set(1, nullsetter, 2)
1
```
"""
const nullsetter = NullSetter()

"""
    ToField(f) :: Setter

Apply `f` when setting.  Use `x -> get(x, f)` if `f` is a `Lens`.

# Examples
```jldoctest
julia> using Setfield, Kaleido

julia> setter = (@lens _.x) ∘ ToField(@lens _.a);

julia> set((x = 1, y = 2), setter, (a = 10, b = 20))
(x = 10, y = 2)
```
"""
struct ToField{F} <: Setter
    f::F
end

_eval(f, x) = f(x)
_eval(f::Lens, x) = get(x, f)

Setfield.set(::Any, setter::ToField, x) = _eval(setter.f, x)
