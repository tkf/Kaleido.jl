"""
    KaleidoLens <: Lens

Internal abstract type for Kaleido.jl.
"""
abstract type KaleidoLens <: Lens end

_getfields(obj) = map(n -> getfield(obj, n), fieldnames(typeof(obj))) :: Tuple

function print_apply(io, f, args)
    if !get(io, :limit, false)
        # Don't show full name in REPL etc.:
        print(io, join(fullname(parentmodule(f)), '.'), '.')
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
