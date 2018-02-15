# solvers for time evolution of quantum systems

using DifferentialEquations

import QSimulator.add_parametric_hamiltonians!

export unitary_propagator,
       unitary_state

"""
    schrodinger(cqs::CompositeQSystem, ts::Float64; u0::Matrix=Matrix{Complex128}(0,0), t0=0.0)

Compute the unitary propagator evolution of a CompositeQSystem evaluted at ts.
"""
function unitary_propagator(cqs::CompositeQSystem, ts::Vector; u0=Matrix{Complex128}(0,0), t0=0.0)
    # schrodinger differential equation for unitary with in place update
    # dU/dt = -iHU
    function ode(du, u, p, t)
        ham = p[3] # preallocated workspace array
        ham .= p[2] # start from fixed_ham
        add_parametric_hamiltonians!(ham, p[1], t)
        scale!(ham, -1im)
        A_mul_B!(du, ham, u)
    end
    # scale Hamiltonian from Hz to rad.
    fixed_ham = 2pi * hamiltonian(cqs)
    # if initial condition not passed start with identity
    if isempty(u0)
        u0 = eye(Complex128, dim(cqs))
    end
    work_ham = similar(fixed_ham) # scratch space
    prob = ODEProblem(ode, u0, (t0, float(ts[end])), (cqs, fixed_ham, work_ham))
    save_start = ts[1]==t0 ? true : false #save t0 only if asked for
    sol = solve(prob; saveat=ts, save_start=save_start)
    sol.u
end


"""
    unitary_state(cqs::CompositeQSystem, ts::Float64, ψ0::Vector, t0=0.0)

Compute the unitary state evolution of a CompositeQSystem from initial state ψ0 evaluted at ts.
"""
function unitary_state(cqs::CompositeQSystem, ts::Vector, ψ0::Vector; t0=0.0)
    # schrodinger differential equation for state vector with in place update
    # dψ/dt = -iHψ
    function ode(dψ, ψ, p, t)
        ham = copy(p[1])
        add_parametric_hamiltonians!(ham, p[2], t)
        dψ[:] = vec(-1im * ham * ψ)
    end
    # scale Hamiltonian from Hz to rad.
    fixed_ham = 2pi * hamiltonian(cqs)
    prob = ODEProblem(ode, ψ0, (t0, float(ts[end])), (fixed_ham, cqs))
    save_start = ts[1]==t0 ? true : false #save t0 only if asked for
    sol = solve(prob; saveat=ts, save_start=save_start)
    sol.u
end


"""
    unitary_state(cqs::CompositeQSystem, ts::Float64, ρ0::Matrix, t0=0.0)

Compute the unitary state evolution of a CompositeQSystem from initial density matrix ρ0 evaluted at ts.
"""
function unitary_state(cqs::CompositeQSystem, ts::Vector, ρ0::Matrix; t0=0.0)
    # schrodinger differential equation for density matrix with in place update
    # dρ/dt = -i[H, ρ]
    function ode(dρ, ρ, p, t)
        ham = copy(p[1])
        add_parametric_hamiltonians!(ham, p[2], t)
        dρ[:] = vec(-1im * (ham*ρ - ρ*ham))
    end
    # scale Hamiltonian from Hz to rad.
    fixed_ham = 2pi * hamiltonian(cqs)
    prob = ODEProblem(ode, ρ0, (t0, float(ts[end])), (fixed_ham, cqs))
    save_start = ts[1]==t0 ? true : false #save t0 only if asked for
    sol = solve(prob; saveat=ts, save_start=save_start)
    sol.u
end

# add helper functions for saving at a single point
unitary_propagator{T<:Number}(cqs::CompositeQSystem, t::T; u0=Matrix{Complex128}(0,0), t0=0.0) = unitary_propagator{T<:Number}(cqs, [t]; u0=u0, t0=t0)[1]
unitary_state{T<:Number}(cqs::CompositeQSystem, t::T, ψ0::Vector; t0=0.0) = unitary_state(cqs, [t], ψ0=ψ0; t0=t0)[1]
unitary_state{T<:Number}(cqs::CompositeQSystem, t::T, ρ0::Matrix; t0=0.0) = unitary_state(cqs, [t], ρ0=ρ0; t0=t0)[1]
