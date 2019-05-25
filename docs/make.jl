using Documenter, Kaleido

makedocs(;
    modules=[Kaleido],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/tkf/Kaleido.jl/blob/{commit}{path}#L{line}",
    sitename="Kaleido.jl",
    authors="Takafumi Arakaki <aka.tkf@gmail.com>",
    assets=String[],
)

deploydocs(;
    repo="github.com/tkf/Kaleido.jl",
)
