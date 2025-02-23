const iterator_warning = """Inconsistent behavior relative to documentation.

This iterator mistakenly returns the transpose of the result implied by the documentation.
As a result, a warning is issued every time this function is called.  Rather than actually
*fixing* this bug in this minor/patch version — which would be a breaking change — this is a
final release in this major version of the package to notify users of this function that
there is a problem.  The next major version of the package will likely change the actual
behavior to the one implied by the documentation.  To quiet these warnings, you can
temporarily pass the keyword argument `warn=false`, though this will probably be removed in
the next major version.  Alternatively, use something like

    import Logging: with_logger, NullLogger
    Dit = with_logger(NullLogger()) do D_iterator(...) end
"""


"""
    D_iterator(D, ℓₘₐₓ, [ℓₘᵢₙ])

Construct an Iterator that returns sub-matrices of `D`, each of which consists of elements
``(ℓ,-ℓ,-ℓ)`` through ``(ℓ,ℓ,ℓ)``, for ``ℓ`` from `ℓₘᵢₙ` through `ℓₘₐₓ`.  By default, `ℓₘᵢₙ`
is 0.

!!! danger "Inconsistent behavior"
    This iterator mistakenly returns the transpose of the result implied by this
    documentation.  As a result, a warning is issued every time this function is called.
    Rather than actually *fixing* this bug in this minor/patch version — which would be a
    breaking change — this is a final release in this major version of the package to notify
    users of this function (and `d_iterator`) that there is a problem.  The next major
    version of the package will likely change the actual behavior to the one implied by this
    docstring.  To quiet these warnings, you can temporarily pass the keyword argument
    `warn=false`, though this will probably be removed in the next major version.
    Alternatively, use `Dit = with_logger(NullLogger()) do D_iterator(...) end` to catch any
    warnings.

Note that the returned objects are *views* into the original `D` data — meaning that you may
alter their values.

Because the result is a matrix restricted to a particular ``ℓ`` value, you can index the
``(ℓ, m′, m)`` element as `[ℓ+m′+1, ℓ+m+1]`.  For example, you might use this as something
like

    for (ℓ, Dˡ) in zip(ℓₘᵢₙ:ℓₘₐₓ, D_iterator(D, ℓₘₐₓ))
        for m′ in -ℓ:ℓ
            for m in -ℓ:ℓ
                Dˡ[ℓ+m′+1, ℓ+m+1]  # ... do something with Dˡ
            end
        end
    end

Also note that no bounds checking is done, either at instantiation time or during iteration.
You are responsible for ensuring that the size of `D` and the values of `ℓₘₐₓ` and `ℓₘᵢₙ`
make sense.

"""
struct D_iterator{VT<:Vector}
    D::VT
    ℓₘₐₓ::Int
    ℓₘᵢₙ::Int
    function D_iterator{VT}(D, ℓₘₐₓ, ℓₘᵢₙ=0; warn=true) where VT
        #@assert ℓₘₐₓ ≥ ℓₘᵢₙ ≥ 0
        if warn
            @warn iterator_warning
        end
        new{VT}(D, ℓₘₐₓ, ℓₘᵢₙ)
    end
end
D_iterator(D::VT, ℓₘₐₓ, ℓₘᵢₙ=0; warn=true) where VT = D_iterator{VT}(D, ℓₘₐₓ, ℓₘᵢₙ; warn)
const Diterator = D_iterator

function Base.iterate(
    Di::D_iterator{VT},
    state=(Di.ℓₘᵢₙ,WignerDsize(Di.ℓₘᵢₙ-1)+1)
) where VT
    if state[1] > Di.ℓₘₐₓ
        nothing
    else
        ℓ = state[1]
        i1 = state[2]
        i2 = i1 + (2ℓ+1)^2 - 1
        Dˡ = reshape(@view(Di.D[i1:i2]), 2ℓ+1, 2ℓ+1)
        (Dˡ, (ℓ+1, i2+1))
    end
end
Base.IteratorSize(::Type{<:D_iterator}) = Base.HasShape{1}()
Base.IteratorEltype(::Type{<:D_iterator}) = Base.HasEltype()
Base.eltype(::Type{D_iterator{VT}}) where VT = Base.ReshapedArray{eltype(VT), 2, SubArray{eltype(VT), 1, VT, Tuple{UnitRange{Int64}}, true}, Tuple{}}
Base.length(Di::D_iterator) = Di.ℓₘₐₓ - Di.ℓₘᵢₙ + 1
Base.size(Di::D_iterator) = (length(Di),)
Base.size(Di::D_iterator, dim) = dim > 1 ? 1 : length(Di)


"""
    d_iterator(d, ℓₘₐₓ, [ℓₘᵢₙ])

Construct an Iterator that returns sub-matrices of `d`, each of which consists of elements
``(ℓ,-ℓ,-ℓ)`` through ``(ℓ,ℓ,ℓ)``, for ``ℓ`` from `ℓₘᵢₙ` through `ℓₘₐₓ`.  By default, `ℓₘᵢₙ`
is 0.

!!! danger "Inconsistent behavior"
    This iterator mistakenly returns the transpose of the result implied by this
    documentation.  As a result, a warning is issued every time this function is called.
    Rather than actually *fixing* this bug in this minor/patch version — which would be a
    breaking change — this is a final release in this major version of the package to notify
    users of this function (and `D_iterator`) that there is a problem.  The next major
    version of the package will likely change the actual behavior to the one implied by this
    docstring.  To quiet these warnings, you can temporarily pass the keyword argument
    `warn=false`, though this will probably be removed in the next major version.
    Alternatively, use `Dit = with_logger(NullLogger()) do D_iterator(...) end` to catch any
    warnings.

Note that the returned objects are *views* into the original `d` data — meaning that you may
alter their values.

Because the result is a matrix restricted to a particular ``ℓ`` value, you can index the
``(ℓ, m′, m)`` element as `[ℓ+m′+1, ℓ+m+1]`.  For example, you might use this as something
like

    for (ℓ, dˡ) in zip(ℓₘᵢₙ:ℓₘₐₓ, d_iterator(d, ℓₘₐₓ))
        for m′ in -ℓ:ℓ
            for m in -ℓ:ℓ
                dˡ[ℓ+m′+1, ℓ+m+1]  # ... do something with dˡ
            end
        end
    end

Also note that no bounds checking is done, either at instantiation time or during iteration.
You are responsible for ensuring that the size of `d` and the values of `ℓₘₐₓ` and `ℓₘᵢₙ`
make sense.

"""
struct d_iterator{VT<:Vector}
    d::VT
    ℓₘₐₓ::Int
    ℓₘᵢₙ::Int
    function d_iterator{VT}(d, ℓₘₐₓ, ℓₘᵢₙ=0; warn=true) where VT
        #@assert ℓₘₐₓ ≥ ℓₘᵢₙ ≥ 0
        if warn
            @warn iterator_warning
        end
        new{VT}(d, ℓₘₐₓ, ℓₘᵢₙ)
    end
end
d_iterator(d::VT, ℓₘₐₓ, ℓₘᵢₙ=0; warn=true) where VT = d_iterator{VT}(d, ℓₘₐₓ, ℓₘᵢₙ; warn)
const diterator = d_iterator

function Base.iterate(
    di::d_iterator{VT},
    state=(di.ℓₘᵢₙ,WignerDsize(di.ℓₘᵢₙ-1)+1)
) where VT
    if state[1] > di.ℓₘₐₓ
        nothing
    else
        ℓ = state[1]
        i1 = state[2]
        i2 = i1 + (2ℓ+1)^2 - 1
        dˡ = reshape(@view(di.d[i1:i2]), 2ℓ+1, 2ℓ+1)
        (dˡ, (ℓ+1, i2+1))
    end
end
Base.IteratorSize(::Type{<:d_iterator}) = Base.HasShape{1}()
Base.IteratorEltype(::Type{<:d_iterator}) = Base.HasEltype()
Base.eltype(::Type{d_iterator{VT}}) where VT = Base.ReshapedArray{eltype(VT), 2, SubArray{eltype(VT), 1, VT, Tuple{UnitRange{Int64}}, true}, Tuple{}}
Base.length(di::d_iterator) = di.ℓₘₐₓ - di.ℓₘᵢₙ + 1
Base.size(di::d_iterator) = (length(di),)
Base.size(di::d_iterator, dim) = dim > 1 ? 1 : length(di)


"""
    sYlm_iterator(Y, ℓₘₐₓ, [ℓₘᵢₙ, [iₘᵢₙ]])

Construct an Iterator that returns sub-vectors of `Y`, each of which consists
of elements ``(ℓ,-ℓ)`` through ``(ℓ,ℓ)``, for ``ℓ`` from `ℓₘᵢₙ` through `ℓₘₐₓ`.

Note that the returned objects are *views* into the original `Y` data — meaning
that you may alter their values.

Because the result is a vector restricted to a particular ``ℓ`` value, you can
index the ``(ℓ, m)`` element as `[ℓ+m+1]`.  For example, you might
use this as something like

    for (ℓ, Yˡ) in zip(ℓₘᵢₙ:ℓₘₐₓ, sYlm_iterator(Y, ℓₘₐₓ))
        for m in -ℓ:ℓ
            Yˡ[ℓ+m+1]  # ... do something with Yˡ
        end
    end

By default, `Y` is assumed to contain all possible values, beginning with
`(0,0)`.  However, if `ℓₘᵢₙ` is not 0, this can be ambiguous: do we mean that
`Y` really starts with the `(0,0)` element and we are just asking to begin the
iteration higher?  Or do we mean that `Y` doesn't even contain data for lower
`ℓ` values?  We can resolve this using `iₘᵢₙ`, which gives the index of `ℓₘᵢₙ`
in `Y`.  By default, we assume the first case, and set `iₘᵢₙ=Ysize(ℓₘᵢₙ-1)+1`.
However, if `Y` doesn't contain data below `ℓₘᵢₙ`, we could use `iₘᵢₙ=1` to
indicate the index in `Y` at which to find ``(ℓₘᵢₙ,-ℓₘᵢₙ)``.

Also note that no bounds checking is done, either at instantiation time or
during iteration.  You are responsible for ensuring that the size of `Y` and
the values of `ℓₘₐₓ`, `ℓₘᵢₙ`, and `iₘᵢₙ` make sense.

"""
struct sYlm_iterator{VT<:Vector}
    Y::VT
    ℓₘₐₓ::Int
    ℓₘᵢₙ::Int
    iₘᵢₙ::Int
    function sYlm_iterator{VT}(Y, ℓₘₐₓ, ℓₘᵢₙ=0, iₘᵢₙ=Ysize(ℓₘᵢₙ-1)+1) where VT
        #@assert ℓₘₐₓ ≥ ℓₘᵢₙ ≥ 0
        new{VT}(Y, ℓₘₐₓ, ℓₘᵢₙ, iₘᵢₙ)
    end
end
sYlm_iterator(Y::VT, ℓₘₐₓ, ℓₘᵢₙ=0) where VT = sYlm_iterator{VT}(Y, ℓₘₐₓ, ℓₘᵢₙ)
sYlm_iterator(Y::VT, ℓₘₐₓ, ℓₘᵢₙ, iₘᵢₙ) where VT = sYlm_iterator{VT}(Y, ℓₘₐₓ, ℓₘᵢₙ, iₘᵢₙ)
const Yiterator = sYlm_iterator

function Base.iterate(
    Yi::sYlm_iterator{VT},
    state=(Yi.ℓₘᵢₙ,Yi.iₘᵢₙ)
) where VT
    if state[1] > Yi.ℓₘₐₓ
        nothing
    else
        ℓ = state[1]
        i1 = state[2]
        i2 = i1 + (2ℓ+1) - 1
        Yˡ = @view(Yi.Y[i1:i2])
        (Yˡ, (ℓ+1, i2+1))
    end
end
Base.IteratorSize(::Type{<:sYlm_iterator}) = Base.HasShape{1}()
Base.IteratorEltype(::Type{<:sYlm_iterator}) = Base.HasEltype()
Base.eltype(::Type{sYlm_iterator{VT}}) where VT = SubArray{eltype(VT), 1, VT, Tuple{UnitRange{Int64}}, true}
Base.length(Yi::sYlm_iterator) = Yi.ℓₘₐₓ - Yi.ℓₘᵢₙ + 1
Base.size(Yi::sYlm_iterator) = (length(Yi),)
Base.size(Yi::sYlm_iterator, dim) = dim > 1 ? 1 : length(Yi)



# # Eq. (10) of [Reinecke & Seljebotn](@cite Reinecke_2013)
# ₛλₗₘ(ϑ) = (-1)ᵐ √((2ℓ+1)/(4π)) dˡ₋ₘₛ(ϑ)
#
# # Eq. (4.11) of [Kostelec & Rockmore](@cite Kostelec_2008)
# # Note that terms with out-of-range indices should be treated as 0.
# ₛλₗ₊₁ₘ = √((2ℓ+3)/(2ℓ+1)) (ℓ+1) (2ℓ+1) / √(((ℓ+1)²-m²) ((ℓ+1)²-s²)) (cosϑ + ms/(ℓ(ℓ+1))) ₛλₗₘ
#          -  √((2ℓ+3)/(2ℓ-1)) (ℓ+1) (2ℓ+1) √((ℓ-m²) (ℓ-s²)) / √(((ℓ+1)²-m²) ((ℓ+1)²-s²)) ((ℓ+1)/ℓ) ₛλₗ₋₁ₘ
#
# # Eqs. (4.7) and (4.6) of [Kostelec & Rockmore](@cite Kostelec_2008)
# for 0 ≤ s ≤ ℓ
# ₛλₗₗ(ϑ) = (-1)ᵐ √((2ℓ+1)/(4π)) √(((2ℓ)!)/((ℓ+s)!(ℓ-s)!)) cosˡ⁻ˢ ϑ/2 sinˡ⁺ˢ ϑ/2
# ₛλₗ₋ₗ(ϑ) = (-1)ᵐ⁺ˡ⁺ˢ √((2ℓ+1)/(4π)) √(((2ℓ)!)/((ℓ+s)!(ℓ-s)!)) cosˡ⁺ˢ ϑ/2 sinˡ⁻ˢ ϑ/2
#
# # https://en.wikipedia.org/wiki/Wigner_D-matrix#Symmetries_and_special_cases
# dˡ₋ₘₛ(ϑ) = (-1)ˡ⁺ᵐ dˡ₋ₘ₋ₛ(π-ϑ)
#  ₛλₗₘ(ϑ) = (-1)ˡ⁺ᵐ  ₋ₛλₗₘ(π-ϑ)
#
# for -ℓ ≤ s ≤ 0
# ₛλₗₗ(ϑ) = (-1)ˡ √((2ℓ+1)/(4π)) √(((2ℓ)!)/((ℓ+s)!(ℓ-s)!)) cosˡ⁺ˢ (π-ϑ)/2 sinˡ⁻ˢ (π-ϑ)/2
# ₛλₗ₋ₗ(ϑ) = (-1)ˢ √((2ℓ+1)/(4π)) √(((2ℓ)!)/((ℓ+s)!(ℓ-s)!)) cosˡ⁻ˢ (π-ϑ)/2 sinˡ⁺ˢ (π-ϑ)/2

@doc raw"""
    λ_recursion_initialize(cosθ, sin½θ, cos½θ, s, ℓ, m)

This provides initial values for the recursion to find
``{}_{s}\lambda_{\ell,m}`` along indices of increasing ``\ell``, due to
[Kostelec & Rockmore](@cite Kostelec_2008) Specifically, this function computes
values with ``\ell=m``.

```math
{}_{s}\lambda_{\ell,m}(\theta)
    := {}_{s}Y_{\ell,m}(\theta, 0)
    = (-1)^m\, \sqrt{\frac{2\ell+1}{4\pi}} d^\ell_{-m,s}(\theta)
```
"""
function λ_recursion_initialize(sin½θ::T, cos½θ::T, s, ℓ, m) where T
    if abs(s) > abs(m)
        λ_recursion_initialize(-sin½θ, cos½θ, m, ℓ, s)
    else
        let π = T(π)
            c = √((2ℓ+1) / (4π)) * sqrtbinomial(2ℓ, ℓ-abs(s), T)
            if s < 0
                if m == ℓ
                    (-1)^ℓ * c * sin½θ^(ℓ+s) * cos½θ^(ℓ-s)
                else # m == -ℓ
                    (-1)^s * c * sin½θ^(ℓ-s) * cos½θ^(ℓ+s)
                end
            else
                if m == ℓ
                    (-1)^m * c * sin½θ^(ℓ+s) * cos½θ^(ℓ-s)
                else # m == -ℓ
                    (-1)^(ℓ+s+m) * c * sin½θ^(ℓ-s) * cos½θ^(ℓ+s)
                end
            end
        end
    end
end

function λ_recursion_coefficients(cosθ::T, s, ℓ, m) where T
    cₗ₊₁ = √(((ℓ+1)^2-m^2) * ((ℓ+1)^2-s^2) / T(2ℓ+3)) / T((ℓ+1)*(2ℓ+1))
    cₗ = (cosθ + m*s/T(ℓ*(ℓ+1))) / √T(2ℓ+1)
    cₗ₊₁, cₗ
end

"""
    λ_iterator(θ, s, m)

Construct an object to iterate over ₛλₗₘ values.

The ``ₛλₗₘ(θ)`` function is defined as the spin-weighted spherical harmonic evaluated at
spherical coordinates ``(θ, ϕ)``, with ``ϕ=0``.  In particular, note that it is real-valued.
The return type is determined by the type of `θ` (or more precisely, cos½θ).

This algorithm by [Kostelec & Rockmore](@cite Kostelec_2008) allows
us to iterate over increasing ``ℓ`` values, for given fixed ``s`` and ``m`` values.

Note that this iteration has no inherent bound, so if you try to iterate over all values,
you will end up in an infinite loop.  Instead, you can `zip` this iterator with another:
```julia
θ = 0.1
s = -2
m = 1
λ = λ_iterator(θ, s, m)
Δ = max(abs(s), abs(m))
for (ℓ, ₛλₗₘ) ∈ zip(Δ:Δ+5, λ)
    @show (ℓ, ₛλₗₘ)
end
```
Alternatively, you could use `Iterates.take(λ, 6)`, for example.

Note that the iteration always begins with `ℓ = Δ = max(abs(s), abs(m))`.
"""
struct λ_iterator{T}
    cosθ::T
    sin½θ::T
    cos½θ::T
    s::Integer
    m::Integer
end
function λ_iterator(θ, s, m)
    cosθ = cos(θ)
    sin½θ, cos½θ = sincos(θ/2)
    λ_iterator{typeof(cos½θ)}(cosθ, sin½θ, cos½θ, s, m)
end
const λiterator = λ_iterator

function Base.iterate(λ::λ_iterator{T}) where {T}
    Δ = max(abs(λ.s), abs(λ.m))
    ₛλₗₘ = λ_recursion_initialize(λ.sin½θ, λ.cos½θ, λ.s, Δ, λ.m)
    state = (zero(λ.cos½θ), ₛλₗₘ, zero(λ.cos½θ), Δ)
    (ₛλₗₘ, state)
end
function Base.iterate(λ::λ_iterator{T}, state) where {T}
    (ₛλₗ₋₁ₘ, ₛλₗₘ, cₗ₋₁, ℓ) = state
    cₗ₊₁, cₗ = λ_recursion_coefficients(λ.cosθ, λ.s, ℓ, λ.m)
    ₛλₗ₊₁ₘ = if ℓ == 0
        # The only case in which this will ever be used is when
        # s == m == ℓ == 0.  So we want ₀Y₁₀, which is known:
        √(3/4T(π)) * λ.cosθ
    else
        (cₗ * ₛλₗₘ + cₗ₋₁ * ₛλₗ₋₁ₘ) / cₗ₊₁
    end
    ₛλₗ₋₁ₘ = ₛλₗₘ
    ₛλₗₘ = ₛλₗ₊₁ₘ
    cₗ₋₁ = -cₗ₊₁ * √((2ℓ+1)/T(2ℓ+3))
    ℓ += 1
    (ₛλₗₘ, (ₛλₗ₋₁ₘ, ₛλₗₘ, cₗ₋₁, ℓ))
end
Base.IteratorSize(::Type{<:λ_iterator}) = Base.IsInfinite()
Base.IteratorEltype(::Type{<:λ_iterator}) = Base.HasEltype()
Base.eltype(λ::λ_iterator{T}) where {T} = T



"""Simple iterator to count down to 0, with alternating signs

```julia
julia> collect(AlternatingCountdown(5))
11-element Vector{Int64}:
  5
 -5
  4
 -4
  3
 -3
  2
 -2
  1
 -1
  0
```
"""
struct AlternatingCountdown
    start::Int
end
function Base.iterate(c::AlternatingCountdown, state=c.start)
    if state == typemax(Int)
        return nothing
    end
    n = if state == 0
        typemax(Int)
    elseif state > 0
        -state
    else
        -state - 1
    end
    (state, n)
end
Base.eltype(::Type{AlternatingCountdown}) = Int
Base.length(c::AlternatingCountdown) = 2c.start+1

struct AlternatingCountup
    stop::Int
end
function Base.iterate(c::AlternatingCountup, state=0)
    if state > c.stop
        return nothing
    end
    n = if state > 0
        -state
    else
        -state + 1
    end
    (state, n)
end
Base.eltype(::Type{AlternatingCountup}) = Int
Base.length(c::AlternatingCountup) = 2c.stop+1
