normalize(l::Lens) = l
normalize(l::ComposedLens) = _compose(l.outer, l.inner)

"""
    _compose(lens1, lens2)

Like `∘` but fixes the associativity to match with the default one in
Setfield.
"""
_compose(l1::Lens, l2::Lens) = l1 ∘ l2
_compose(l1::Lens, l2::ComposedLens) =
    _compose(_compose(normalize(l1), l2.outer), l2.inner)
