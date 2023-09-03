@testset verbose=true "Operators" begin

    # These are just simple versions of the operators defined in
    # notes/operators/explicit_definition.jl, for testing purposes.  Note that we explicitly
    # use `cos(θ) + sin(θ)*g` instead of simply `exp(θ*g)`, because the `exp` implementation
    # currently has a special case at zero, which messes with the derivative at that point.
    # But also note that these are incorrect for `g=0` because we oversimplify.
    function L(g::QuatVec{T}, f) where T
        function L_g(Q)
            -im * ForwardDiff.derivative(θ -> f((cos(θ) + sin(θ)*g) * Q), zero(T)) / 2
        end
    end
    function R(g::QuatVec{T}, f) where T
        function R_g(Q)
            -im * ForwardDiff.derivative(θ -> f(Q * (cos(θ) + sin(θ)*g)), zero(T)) / 2
        end
    end

    @testset "Explicit definition $T" for T ∈ [Float32, Float64, Double64, BigFloat]
        # Test the `L` and `R` operators as defined above
        ϵ = 100 * eps(T)
        for Q ∈ randn(Rotor{T}, 10)
            for ℓ ∈ 0:4
                for m ∈ -ℓ:ℓ
                    for m′ ∈ -ℓ:ℓ
                        f(Q) = D_matrices(Q, ℓ)[WignerDindex(ℓ, m, m′)]

                        @test R(imz, f)(Q) ≈ m′ * f(Q) atol=ϵ rtol=ϵ
                        @test L(imz, f)(Q) ≈ m * f(Q) atol=ϵ rtol=ϵ

                        if ℓ ≥ abs(m+1)
                            L₊1 = L(imx, f)(Q) + im * L(imy, f)(Q)
                            L₊2 = √T((ℓ-m)*(ℓ+m+1)) * D_matrices(Q, ℓ)[WignerDindex(ℓ, m+1, m′)]
                            @test L₊1 ≈ L₊2 atol=ϵ rtol=ϵ
                        end

                        if ℓ ≥ abs(m-1)
                            L₋1 = L(imx, f)(Q) - im * L(imy, f)(Q)
                            L₋2 = √T((ℓ+m)*(ℓ-m+1)) * D_matrices(Q, ℓ)[WignerDindex(ℓ, m-1, m′)]
                            @test L₋1 ≈ L₋2 atol=ϵ rtol=ϵ
                        end

                        if ℓ ≥ abs(m′+1)
                            K₊1 = R(imx, f)(Q) - im * R(imy, f)(Q)
                            K₊2 = √T((ℓ-m′)*(ℓ+m′+1)) * D_matrices(Q, ℓ)[WignerDindex(ℓ, m, m′+1)]
                            @test K₊1 ≈ K₊2 atol=ϵ rtol=ϵ
                        end

                        if ℓ ≥ abs(m′-1)
                            K₋1 = R(imx, f)(Q) + im * R(imy, f)(Q)
                            K₋2 = √T((ℓ+m′)*(ℓ-m′+1)) * D_matrices(Q, ℓ)[WignerDindex(ℓ, m, m′-1)]
                            @test K₋1 ≈ K₋2 atol=ϵ rtol=ϵ
                        end
                    end
                end
            end
        end
    end

    @testset "Scalar multiplication $T" for T ∈ [Float32, Float64, Double64]
        # Test L_{sg} = sL_{g} and R_{sg} = sR_{g}
        ϵ = 100 * eps(T)
        Ss = randn(T, 5)
        Gs = randn(QuatVec{T}, 5)
        for Q ∈ randn(Rotor{T}, 5)
            for ℓ ∈ 0:4
                for m ∈ -ℓ:ℓ
                    for m′ ∈ -ℓ:ℓ
                        f(Q) = D_matrices(Q, ℓ)[WignerDindex(ℓ, m, m′)]
                        for s ∈ Ss
                            for g ∈ Gs
                                @test L(s*g, f)(Q) ≈ s*L(g, f)(Q) atol=ϵ rtol=ϵ
                                @test R(s*g, f)(Q) ≈ s*R(g, f)(Q) atol=ϵ rtol=ϵ
                            end
                        end
                    end
                end
            end
        end
    end

    @testset "Additivity $T" for T ∈ [Float32, Float64, Double64]
        # Test L_{a+b} = L_{a}+L_{b} and R_{a+b} = R_{a}+R_{b}
        ϵ = 100 * eps(T)
        Gs = randn(QuatVec{T}, 5)
        for Q ∈ randn(Rotor{T}, 5)
            for ℓ ∈ 0:4
                for m ∈ -ℓ:ℓ
                    for m′ ∈ -ℓ:ℓ
                        f(Q) = D_matrices(Q, ℓ)[WignerDindex(ℓ, m, m′)]
                        for g₁ ∈ Gs
                            for g₂ ∈ Gs
                                @test L(g₁+g₂, f)(Q) ≈ L(g₁, f)(Q) + L(g₂, f)(Q) atol=ϵ rtol=ϵ
                                @test R(g₁+g₂, f)(Q) ≈ R(g₁, f)(Q) + R(g₂, f)(Q) atol=ϵ rtol=ϵ
                            end
                        end
                    end
                end
            end
        end
    end

    @testset "Casimir $T" for T ∈ [Float32, Float64, Double64, BigFloat]
        # Test that L² = (L₊L₋ + L₋L₊ + 2Lz²)/2 = R² = (R₊R₋ + R₋R₊ + 2Rz²)/2
        ϵ = 100 * eps(T)
        for s ∈ -3:3
            for ℓₘₐₓ ∈ 4:7
                for ℓₘᵢₙ ∈ 0:min(abs(s)+1, ℓₘₐₓ)
                    let L²=L²(s, ℓₘᵢₙ, ℓₘₐₓ, T),
                        Lz=Lz(s, ℓₘᵢₙ, ℓₘₐₓ, T),
                        L₊=L₊(s, ℓₘᵢₙ, ℓₘₐₓ, T),
                        L₋=L₋(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                        L1 = L²
                        L2 = (L₊*L₋ .+ L₋*L₊ .+ 2Lz*Lz)/2
                        @test L1 ≈ L2 atol=ϵ rtol=ϵ
                    end
                    let L²=L²(s, ℓₘᵢₙ, ℓₘₐₓ, T),
                        R²=R²(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                        @test L² ≈ R² atol=ϵ rtol=ϵ
                    end
                    let
                        # R² = (2Rz² + R₊R₋ + R₋R₊)/2
                        R1 = R²(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                        R2 = T.(Array(
                            R₊(s+1, ℓₘᵢₙ, ℓₘₐₓ, T) * R₋(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                            .+ R₋(s-1, ℓₘᵢₙ, ℓₘₐₓ, T) * R₊(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                            .+ 2Rz(s, ℓₘᵢₙ, ℓₘₐₓ, T) * Rz(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                        ) / 2)
                        @test R1 ≈ R2 atol=ϵ rtol=ϵ
                    end
                end
            end
        end
    end

    @testset verbose=false "Applied to ₛYₗₘ $T" for T ∈ [Float32, Float64, Double64, BigFloat]
        # Evaluate (on points) ðY = √((ℓ-s)(ℓ+s+1)) Y, and similarly for ð̄Y
        ϵ = 100 * eps(T)
        @testset "$ℓₘₐₓ" for ℓₘₐₓ ∈ 4:7
            for s in -3:3
                let ℓₘᵢₙ = 0
                    𝒯₊ = SSHT(s+1, ℓₘₐₓ; T=T, method="Direct", inplace=false)
                    𝒯₋ = SSHT(s-1, ℓₘₐₓ; T=T, method="Direct", inplace=false)
                    i₊ = Yindex(abs(s+1), -abs(s+1), ℓₘᵢₙ)
                    i₋ = Yindex(abs(s-1), -abs(s-1), ℓₘᵢₙ)
                    Y = zeros(Complex{T}, Ysize(ℓₘᵢₙ, ℓₘₐₓ))
                    for ℓ in abs(s):ℓₘₐₓ
                        for m in -ℓ:ℓ
                            Y[:] .= zero(T)
                            Y[Yindex(ℓ, m, ℓₘᵢₙ)] = one(T)
                            ðY = 𝒯₊ * (ð(s, ℓₘᵢₙ, ℓₘₐₓ, T) * Y)[i₊:end]
                            Y₊ = 𝒯₊ * Y[i₊:end]
                            c₊ = ℓ < abs(s+1) ? zero(T) : √T((ℓ-s)*(ℓ+s+1))
                            @test ðY ≈ c₊ * Y₊ atol=ϵ rtol=ϵ
                            ð̄Y = 𝒯₋ * (ð̄(s, ℓₘᵢₙ, ℓₘₐₓ, T) * Y)[i₋:end]
                            Y₋ = 𝒯₋ * Y[i₋:end]
                            c₋ = ℓ < abs(s-1) ? zero(T) : -√T((ℓ+s)*(ℓ-s+1))
                            @test ð̄Y ≈ c₋ * Y₋ atol=ϵ rtol=ϵ
                        end
                    end
                end
            end
        end
    end

    @testset verbose=false "Commutators $T" for T ∈ [Float32, Float64, Double64, BigFloat]
        # Test the following relations:
        # [L², Lz] = 0     [L², L₊] = 0     [L², L₋] = 0
        # [R², Rz] = 0     [R², R₊] = 0     [R², R₋] = 0
        # [Lz, L₊] = L₊    [Lz, L₋] = -L₋   [L₊, L₋] = 2Lz
        # [Rz, R₊] = R₊    [Rz, R₋] = -R₋   [R₊, R₋] = 2Rz
        # [Rz, ð] = -ð     [Rz, ð̄] = ð̄      [ð, ð̄] = 2Rz
        ϵ = 100 * eps(T)
        @testset "$ℓₘₐₓ" for ℓₘₐₓ ∈ 4:7
            for s in -3:3
                let ℓₘᵢₙ = 0
                    for Oᵢ ∈ [Lz, L₊, L₋, Rz, R₊, R₋]
                        for O² ∈ [L², R²]
                            let O²=O²(s, ℓₘᵢₙ, ℓₘₐₓ, T),
                                Oᵢ=Oᵢ(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                                # [O², Oᵢ] = 0
                                @test O²*Oᵢ-Oᵢ*O² ≈ 0*O² atol=ϵ rtol=ϵ
                            end
                        end
                    end
                    let Lz=Array(Lz(s, ℓₘᵢₙ, ℓₘₐₓ, T)),
                        L₊=Array(L₊(s, ℓₘᵢₙ, ℓₘₐₓ, T)),
                        L₋=Array(L₋(s, ℓₘᵢₙ, ℓₘₐₓ, T))
                        # [Lz, L₊] = L₊
                        @test Lz*L₊ - L₊*Lz ≈ L₊ atol=ϵ rtol=ϵ
                        # [Lz, L₋] = -L₋
                        @test Lz*L₋ - L₋*Lz ≈ -L₋ atol=ϵ rtol=ϵ
                        # [L₊, L₋] = 2Lz
                        @test L₊*L₋ - L₋*L₊ ≈ 2Lz atol=ϵ rtol=ϵ
                    end
                    let
                        # [Rz, R₊] = R₊
                        @test (
                            Rz(s-1, ℓₘᵢₙ, ℓₘₐₓ, T)*R₊(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                            - R₊(s, ℓₘᵢₙ, ℓₘₐₓ, T)*Rz(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                            ≈ R₊(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                        ) atol=ϵ rtol=ϵ
                        # [Rz, R₋] = -R₋
                        @test (
                            Rz(s+1, ℓₘᵢₙ, ℓₘₐₓ, T)*R₋(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                            - R₋(s, ℓₘᵢₙ, ℓₘₐₓ, T)*Rz(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                            ≈ -R₋(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                        ) atol=ϵ rtol=ϵ
                        # [R₊, R₋] = 2Rz
                        @test (
                            R₊(s+1, ℓₘᵢₙ, ℓₘₐₓ, T)*R₋(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                            - R₋(s-1, ℓₘᵢₙ, ℓₘₐₓ, T)*R₊(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                            ≈ 2Rz(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                        ) atol=ϵ rtol=ϵ
                        # [Rz, ð] = -ð
                        @test (
                            Rz(s+1, ℓₘᵢₙ, ℓₘₐₓ, T)*ð(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                            - ð(s, ℓₘᵢₙ, ℓₘₐₓ, T)*Rz(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                            ≈ -ð(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                        ) atol=ϵ rtol=ϵ
                        # [Rz, ð̄] = ð̄
                        @test (
                            Rz(s-1, ℓₘᵢₙ, ℓₘₐₓ, T)*ð̄(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                            - ð̄(s, ℓₘᵢₙ, ℓₘₐₓ, T)*Rz(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                            ≈ ð̄(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                        ) atol=ϵ rtol=ϵ
                        # [ð, ð̄] = 2Rz
                        @test (
                            ð(s-1, ℓₘᵢₙ, ℓₘₐₓ, T)*ð̄(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                            -ð̄(s+1, ℓₘᵢₙ, ℓₘₐₓ, T)*ð(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                            ≈ 2Rz(s, ℓₘᵢₙ, ℓₘₐₓ, T)
                        ) atol=ϵ rtol=ϵ
                    end
                end
            end
        end
    end

    # @testset "General commutators $T" for T ∈ [Float32, Float64, Double64, BigFloat]
    #     # Pretest: Test that [eⱼ, eₖ] = 2∑ₗ ε(j,k,l) eₗ
    #     ε(j,k,l) = ifelse((j,k,l)∈((1,2,3),(2,3,1),(3,1,2)), 1, ifelse((j,k,l)∈((2,1,3),(1,3,2),(3,2,1)), -1, 0))
    #     let e = [imx, imy, imz]
    #         for (j,eⱼ) ∈ enumerate(e)
    #             for (k,eₖ) ∈ enumerate(e)
    #                 @test eⱼ*eₖ - eₖ*eⱼ == 2sum(ε(j,k,l)*e[l] for l ∈ 1:3)
    #             end
    #         end
    #     end
    #     # Therefore, we are about to test the following relations (and then some):
    #     #   [Lⱼ, Lₖ] =  im L_{[eⱼ,eₖ]/2} =  im ∑ₗ ε(j,k,l) Lₗ
    #     #   [Rⱼ, Rₖ] = -im R_{[eⱼ,eₖ]/2} = -im ∑ₗ ε(j,k,l) Rₗ

    #     # Test the following relations:
    #     # [L_a, L_b] = - L_{[a,b]} / 2im
    #     # [R_a, R_b] =   R_{[a,b]} / 2im
    #     ϵ = 100 * eps(T)
    #     vectors = [e; randn(Rotor{T}, 10)]
    #     @testset "$ℓₘₐₓ" for ℓₘₐₓ ∈ 4:7
    #         for s in -3:3
    #             let ℓₘᵢₙ = 0
    #                 Y = zeros(Complex{T}, Ysize(ℓₘᵢₙ, ℓₘₐₓ))
    #                 let Lz=Array(Lz(s, ℓₘᵢₙ, ℓₘₐₓ, T)),
    #                     L₊=Array(L₊(s, ℓₘᵢₙ, ℓₘₐₓ, T)),
    #                     L₋=Array(L₋(s, ℓₘᵢₙ, ℓₘₐₓ, T))
    #                     # [Lz, L₊] = L₊
    #                     @test Lz*L₊ - L₊*Lz ≈ L₊ atol=ϵ rtol=ϵ
    #                     # [Lz, L₋] = -L₋
    #                     @test Lz*L₋ - L₋*Lz ≈ -L₋ atol=ϵ rtol=ϵ
    #                     # [L₊, L₋] = 2Lz
    #                     @test L₊*L₋ - L₋*L₊ ≈ 2Lz atol=ϵ rtol=ϵ
    #                 end

end
