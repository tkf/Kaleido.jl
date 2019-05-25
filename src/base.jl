"""
    KaleidoLens <: Lens

Internal abstract type for Kaleido.jl.
"""
abstract type KaleidoLens <: Lens end

function Base.show(io::IO, lens::KaleidoLens)
    T = typeof(lens)
    if !get(io, :limit, false)
        # Don't show full name in REPL etc.:
        print(io, join(fullname(parentmodule(T)), '.'), '.')
    end
    print(io, nameof(T))
    args = map(n -> getfield(lens, n), fieldnames(T)) :: Tuple
    if length(args) == 1
        print(io, '(')
        show(io, args[1])
        print(io, ')')
    else
        show(io, args)
    end
    return
end
