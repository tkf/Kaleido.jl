"""
    prettylens(lens::Lens; sprint_kwargs...) :: String
    prettylens(io::IO, lens::Lens)

Print or return more compact and easier-to-read string representation of
`lens` than `show`.

# Examples
```jldoctest
julia> using Setfield, Kaleido

julia> prettylens(
           (@lens _.a) ∘ MultiLens((
               (@lens last(_)),
               (@lens _[:c].d) ∘ settingasℝ₊,
           ));
           context = :compact => true,
       )
"◻.a∘〈last(◻),◻[:c].d∘(←exp|log→)〉"
```
"""
prettylens

# Importing internals (let's try not break precompilation)
isdefined(Setfield, :has_atlens_support) && using Setfield: has_atlens_support
isdefined(Setfield, :print_in_atlens) && using Setfield: print_in_atlens

printhole(io) = printstyled(io, "◻", color=:light_black)

prettylens(lens::Lens; kwargs...) = sprint(prettylens, lens; kwargs...)

function prettylens(io::IO, lens::ComposedLens)
    prettylens_via_atlens(io,  lens) && return

    prettylens(io, lens.outer)
    printstyled(io, (:compact => true) in io ? "∘" : " ∘ "; color=:light_black)
    prettylens(io, lens.inner)
end

prettylens(io::IO, lens::Lens) =
    prettylens_via_atlens(io, lens) || show(io, lens)

function prettylens_via_atlens(io, lens)
    if has_atlens_support(lens)
        name = sprint(print_in_atlens, lens, context=io)
        if startswith(name, "(@lens ") && endswith(name, ")")
            if startswith(name, "(@lens _")
                printhole(io)
                print(io, name[length("(@lens _")+1:end-length(")")])
            else
                parts = split(name[length("(@lens ")+1:end-length(")")], "(_)")
                print(io, parts[1])
                for s in parts[2:end]
                    print(io, '(')
                    printhole(io)
                    print(io, ')')
                    print(io, s)
                end
            end
            return true
        end
    end
    return false
end

function prettylens(io::IO, lens::MultiLens)
    print(io, '〈')
    for (i, l) in enumerate(lens.lenses)
        if i != 1
            print(io, ',')
            (:compact => true) in io || print(io, ' ')
        end
        prettylens(io, l)
    end
    print(io, '〉')
end

function prettylens(io::IO, lens::BijectionLens{<:FunctionPair})
    bi = lens.bijection
    print(io, "(←", bi.tofield, "|", bi.fromfield, "→)")
end

function prettylens(io::IO, lens::BijectionLens)
    print(io, "(←", lens.bijection, "→)")
end

function prettylens(io::IO, lens::BijectionLens{<:XFBijection{INV}}) where INV
    if (@isdefined TransformVariables)
        io = IOContext(io, :module => TransformVariables)
    end
    print(io, "(←")
    INV || print(io, '|')
    print(io, lens.bijection.xf)
    INV && print(io, '|')
    print(io, "→)")
end

function prettylens(io::IO, lens::ConverterLens)
    print(io, "(")
    print(io, lens.f)
    print(io, "→)")
end

function prettylens(io::IO, setter::ToField)
    print(io, "(←")
    print(io, setter.f)
    print(io, "|❌→)")
end
