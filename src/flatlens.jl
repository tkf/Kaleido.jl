"""
    FlatLens(N₁, N₂, ..., Nₙ)

# Examples
```jldoctest
julia> using Setfield, Kaleido

julia> l = MultiLens((
           (@lens _.x) ∘ IndexBatchLens(:a, :b, :c),
           (@lens _.y) ∘ IndexBatchLens(:d, :e),
       )) ∘ FlatLens(3, 2);

julia> get((x=(a=1, b=2, c=3), y=(d=4, e=5)), l)
(1, 2, 3, 4, 5)

julia> set((x=(a=1, b=2, c=3), y=(d=4, e=5)), l, (10, 20, 30, 40, 50))
(x = (a = 10, b = 20, c = 30), y = (d = 40, e = 50))
```
"""
FlatLens

struct FlatLens{lengths} <: Lens end

Setfield.get(obj, ::FlatLens) = _cat(obj...)

Setfield.set(::Any, ::FlatLens{lengths}, val) where lengths =
    let val = Tuple(val)
        _foldl(lengths, ((), 1)) do (ys, start), n
            (ys..., val[start:start + n - 1]), start + n
        end[1]
    end

FlatLens(lengths::Vararg{Integer}) = FlatLens{UInt.(lengths)}()

Base.show(io::IO, ::FlatLens{lengths}) where lengths =
    print_apply(io, FlatLens, Int.(lengths))


"""
    SingletonLens()

Inverse of `FlatLens(1)`.
"""
struct SingletonLens <: Lens end

Setfield.get(obj, ::SingletonLens) = (obj,)
Setfield.set(::Any, ::SingletonLens, obj) = obj[1]
