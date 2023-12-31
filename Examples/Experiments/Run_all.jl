using LinearAlgebra,ForwardDiff, Revise, Plots, InvertedIndices, LaTeXStrings, BenchmarkTools, JLD2, Random
include("../../src/LSMOD.jl")
using .LSMOD

"""
    We reproduce Figure 1 in [cite paper]
    Settings:
        - t=2.3 second, 200 timesteps Δt = 10⁻³ and 10⁻⁵
        - At Δt = 10⁻³ we use M=20, m=10
        - At Δt = 10⁻⁵ we use M=35, m=20
        - For each timestep we supply a reference method using the 
          previous step as initial guess for GMRES
        - Other settings:
            - GMRES without restarting
            - Tolerance: ||Ax - b||₂/||b||₂ ≤ 10⁻⁷
            - Incomplete LU preconditioner with no fill in
            - Fourth order discretisation scheme in time
"""

Random.seed!(parse(Int64,ARGS[2]))

const N=1000
if ARGS[1]=="10e_3"
  const M=35
  const m=20
  const Nys_k = 14
  const Nys_p = 6
  Δt = 1e-3
elseif ARGS[1]=="10e_5"
  Δt = 1e-5
  const M=20
  const m=10
  const Nys_k = 7
  const Nys_p = 3
end
t₀=0.1
projection_error = false
filename = pwd() * "/Examples/Data/"*ARGS[1]*"/final_"*ARGS[2]*"_3.jld2"

prob = LSMOD.Example1.make_prob(100)
LSMOD.solve(t₀, Δt , M+10, deepcopy(prob));
sol_base,_,_ = LSMOD.solve(t₀, Δt , N, deepcopy(prob));

RandNYS = LSMOD.Nystrom(prob.internal^2,M,Nys_k,Nys_p);
LSMOD.solve(t₀, Δt , M+10, deepcopy(prob), deepcopy(RandNYS); projection_error=projection_error);
sol_RNYS = LSMOD.solve(t₀, Δt , N, deepcopy(prob), RandNYS; projection_error=projection_error);

pod = LSMOD.POD(prob.internal^2,M,m);
LSMOD.solve(t₀, Δt , M+10, deepcopy(prob), deepcopy(pod); projection_error=projection_error);
sol_POD = LSMOD.solve(t₀, Δt , N, deepcopy(prob), pod; projection_error=projection_error);

RQR=LSMOD.RandomizedQR(prob.internal^2,M,m);
LSMOD.solve(t₀, Δt , M+10, deepcopy(prob), deepcopy(RQR); projection_error=projection_error);
sol_Rand = LSMOD.solve(t₀, Δt , N, deepcopy(prob), RQR; projection_error=projection_error);

RSVD=LSMOD.RandomizedSVD(prob.internal^2,M,m);
LSMOD.solve(t₀, Δt, M+10, deepcopy(prob), deepcopy(RSVD); projection_error=projection_error);
sol_RandSVD = LSMOD.solve(t₀, Δt, N, deepcopy(prob), RSVD; projection_error=projection_error);

save(filename, 
    Dict("base" => sol_base,
         "Nystrom" => sol_RNYS,
         "POD" => sol_POD,
         "RandQR" => sol_Rand,
         "RandSVD" => sol_RandSVD,
         "m" => m,
         "M" => M,
         "dt" => Δt,
         "t0" => t₀,
         "N" => N,
         )
    )

