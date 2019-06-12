"""
    batch(lens₁, lens₂, ..., lensₙ) :: Lens

From ``n`` lenses, create a single lens that gets/sets ``n``-tuple in
such a way that the number of call to the constructor is minimized.
This is done by calling [`IndexBatchLens`](@ref) whenever possible.

# Examples
```jldoctest
julia> using Kaleido, Setfield

julia> lens = @batchlens begin
           _.a.b.c
           _.a.b.d
           _.a.e
       end;

julia> @assert lens ==
           IndexBatchLens(:a) ∘ MultiLens((
               (@lens _[1]) ∘ IndexBatchLens(:b, :e) ∘ MultiLens((
                   (@lens _[1]) ∘ IndexBatchLens(:c, :d),
                   (@lens _[2]) ∘ Kaleido.SingletonLens(),
               )) ∘ FlatLens(2, 1),
           )) ∘ FlatLens(3)

julia> obj = (a=(b=(c=1, d=2), e=3),);

julia> get(obj, lens)
(1, 2, 3)

julia> set(obj, lens, (10, 20, 30))
(a = (b = (c = 10, d = 20), e = 30),)
```
"""
batch

leftmost(l::Lens) = l
leftmost(l::ComposedLens) = leftmost(l.outer)
rightlens(::Lens) = IdentityLens()
rightlens(l::ComposedLens) = rightlens(l.outer) ∘ l.inner

startswithproperty(::T) where {T <: Lens} = startswithproperty(T)
startswithproperty(::Type{<:Lens}) = false
startswithproperty(::Type{<:PropertyLens}) = true
startswithproperty(::Type{<:ComposedLens{LO}}) where {LO} = startswithproperty(LO)

allstartswithproperty(::T) where {T} = allstartswithproperty(T)
allstartswithproperty(::Type{Tuple{}}) = true
allstartswithproperty(::Type{T}) where {N, T <: NTuple{N, Lens}} =
    startswithproperty(Base.tuple_type_head(T)) &&
    allstartswithproperty(Base.tuple_type_tail(T))

propname(::PropertyLens{name}) where name = name

batch(::IdentityLens) = SingletonLens()

batch(lenses::PropertyLens...) = IndexBatchLens(propname.(lenses)...)

function batch(lenses::Lens...)
    allstartswithproperty(lenses) || return MultiLens(lenses)
    partitions = partitionby(lenses, leftmost)
    propnames = _map(x -> propname(x.key), partitions)
    sublenses = _map(x -> rightlens.(x.values), partitions)
    indexlenses = ntuple(i -> (@lens _[i]), length(partitions))
    return IndexBatchLens(propnames...) ∘
        MultiLens(_compose.(indexlenses, _batch.(sublenses))) ∘
        FlatLens(_map(x -> length(x.values), partitions)...)
end
# TODO: Sort the lenses first and compute the permutation to recover
# the original order.

_batch(lenses::Tuple{Vararg{Lens}}) = batch(lenses...)


"""
    @batchlens begin
        lens_expression_1
        lens_expression_2
        ...
        lens_expression_n
    end

From ``n`` "lens expression", create a lens that gets/sets ``n``-tuple.
Each "lens expression" is an expression that is supported by
`Setfield.@lens` or such expression post-composed with other lenses
using `∘`.

See also [`batch`](@ref) which does all the heavy lifting of the
transformation of the lenses.

# Examples
```jldoctest
julia> using Kaleido, Setfield

julia> lens = @batchlens begin
           _.a.b.c
           _.a.b.d ∘ converting(fromfield = x -> parse(Int, x), tofield = string)
           _.a.e
       end;

julia> obj = (a = (b = (c = 1, d = "2"), e = 3),);

julia> get(obj, lens)
(1, 2, 3)

julia> set(obj, lens, (10, 20, 30))
(a = (b = (c = 10, d = "20"), e = 30),)
```
"""
macro batchlens(lenses_expression)
    if !(lenses_expression isa Expr && lenses_expression.head == :block)
        error("""
        Macro @batchlens needs a block of lens expressions.  Got:
        $lenses_expression
        """)
    end
    lnns = lenses_expression.args[1:2:end]
    exprs = lenses_expression.args[2:2:end]
    if all(isa.(lnns, LineNumberNode)) &&
            all(isa.(exprs, Expr)) &&
            length(lnns) == length(exprs)
        lens_exprs = make_lens_expr.(exprs, lnns)
    else
        lens_exprs = [
            make_lens_expr(x, __source__) for x in lenses_expression.args
            if x isa Expr
        ]
    end
    return esc(Expr(:call, batch, lens_exprs...))
end

islensexpr(ex::Symbol) = ex == :_
islensexpr(ex::Expr) = ex.head in (:., :ref) && islensexpr(ex.args[1])

function make_lens_expr(ex::Expr, lnn::LineNumberNode)
    if !(islensexpr(ex) || (ex.head == :call && ex.args[1] == :∘))
        error("Not a lens expression: $ex")
    end
    return _make_lens_expr(ex, lnn)
end

_make_lens_expr(ex::Symbol, lnn::LineNumberNode) = ex
function _make_lens_expr(ex::Expr, lnn::LineNumberNode)
    if islensexpr(ex)
        # Make `:(Setfield.@lens $ex)` with a proper `LineNumberNode`:
        atlens = Expr(:., Setfield, QuoteNode(Symbol("@lens")))
        return Expr(:macrocall, atlens, lnn, ex)
    elseif ex.head == :call && ex.args[1] == :∘
        return Expr(:call, :∘, _make_lens_expr.(ex.args[2:end], Ref(lnn))...)
    else
        return ex
    end
end
