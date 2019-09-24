module TestPrettyLens

include("preamble.jl")

@testset "prettylens(::Lens)" begin
    @test prettylens((@lens _.a[:b].c)) == "◻.a[:b].c"
    @test prettylens((@lens _.a) ∘ settingasℝ₊) == "◻.a ∘ (←exp|log→)"
    @test prettylens((@lens _.a) ∘ settingasℝ₊; context=:compact=>true) ==
        "◻.a∘(←exp|log→)"
    @test prettylens(
        (@lens _.a) ∘ MultiLens((
            (@lens last(_)),
            (@lens _[:c].d) ∘ settingasℝ₊,
        ));
         context = :compact => true,
    ) == "◻.a∘〈last(◻),◻[:c].d∘(←exp|log→)〉"
end

end  # module
