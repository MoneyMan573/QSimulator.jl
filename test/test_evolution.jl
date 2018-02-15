############################ Ramsey ##########################

# ramsey evolution of a single transmon should produce sinusoidal oscillations at the qubit frequency
qubit_freq = 5.0
q0 = FixedDuffingTransmon("q0", qubit_freq, -0.2, 3)
cqs = CompositeQSystem([q0]);
add_hamiltonian!(cqs, q0)
times = collect(linspace(0,1,201))
ψ_init = (1/sqrt(2)) * Complex128[1; 1; 0]
ψs = unitary_state(cqs, times, ψ_init);
signal = Float64[real(ψ_init'*ψ) for ψ in ψs]
expected = 0.5 + 0.5*cos.(2π*qubit_freq * (linspace(0,1,201)))
@test isapprox(signal, expected; rtol=1e-3, atol=1e-3)

# check that the propagator gives the same result
us = unitary_propagator(cqs, times)
ψs = [u*ψ_init for u = us]
signal = Float64[real(ψ_init'*ψ) for ψ in ψs]
@test isapprox(signal, expected; rtol=1e-4, atol=1e-4)

########################### Rabi ##########################

# rabi flops should produce sinusoidal oscillations between ground and excited state
# TODO remove when added to QSimulator package
function qubit_drive(q::QSystem, drive::Function)
    function add_drive_ham!(ham, idxs, t)
        pulse = 2π * drive(t)
        drive_ham = real(pulse) * X(q) + imag(pulse) * Y(q)
        QSimulator.expand_add!(ham, drive_ham, idxs)
    end
end

qubit_freq = 5.0
nutation_freq = 0.02
q0 = FixedDuffingTransmon("q0", qubit_freq, -0.2, 3)
cqs = CompositeQSystem([q0]);
add_hamiltonian!(cqs, q0)
add_hamiltonian!(cqs, qubit_drive(q0, t -> nutation_freq*cos(2π*qubit_freq * t)), q0);
ψ_init = Complex128[1; 0; 0]
times = collect(linspace(0,100,101))
ψs = unitary_state(cqs, times, ψ_init);

g_sim = [abs2(s[1]) for s in ψs]
e_sim = [abs2(s[2]) for s in ψs]

# we would normally expect a factor of 0.5 from lab -> rotating frame but by defining the qubit
# drive in terms of X rather than 0.5 X undoes that
g_expected = 0.5 + 0.5*cos.(2π*nutation_freq * times)
@test isapprox(g_sim, g_expected; rtol=1e-2, atol=1e-2)
@test isapprox(e_sim, 1-g_expected; rtol=1e-2, atol=1e-2)

# check that the propagator gives the same result
us = unitary_propagator(cqs, times)
ψs = [u*ψ_init for u = us]
g_sim = [abs2(s[1]) for s in ψs]
e_sim = [abs2(s[2]) for s in ψs]
@test isapprox(g_sim, g_expected; rtol=1e-2, atol=1e-2)
@test isapprox(e_sim, 1-g_expected; rtol=1e-2, atol=1e-2)

########################### Parmetric Flux Drive ##########################

# parametric flux drive should produce flops between resonant states
# TODO remove when added to QSimulator package
function flux_drive(tt::QSystem, amp, freq)
    function add_drive_ham!(ham, idxs, t)
        tt_ham = 2π * hamiltonian(tt, amp*sin(2π * freq * t))
        QSimulator.expand_add!(ham, tt_ham, idxs)
    end
end

# parameters from Blue Launch paper
q0 = FixedDuffingTransmon("q0", 3.94015, -0.1807,  3)
q1 = TunableDuffingTransmon("q1",  0.172, 16.4, 0.55, 3)


# should get an iSWAP interaction at 122 MHz
freq = 122.1
times = collect(0.0:5:1000)
cqs = CompositeQSystem([q0, q1])
add_hamiltonian!(cqs, hamiltonian(q0), q0)
add_hamiltonian!(cqs, 0.006*Dipole(q0, q1), [q0,q1])
add_hamiltonian!(cqs, flux_drive(q1, 0.323, freq/1e3), q1)
ψ0 = Complex128[0.0; 1.0; 0.0] ⊗ Complex128[1.0; 0.0; 0.0] # start in the 10 state
ψs = unitary_state(cqs, times, ψ0);
pop_10 = [abs2(ψ[4]) for ψ in ψs]
pop_01 = [abs2(ψ[2]) for ψ in ψs]

# population should oscillate between 01 and 10
# there is additional lab frame jaggedness so relax tolerance
# TODO: calculated analytical expected g
expected_10 = 0.5 +  0.5*cos.(2π*(1/145) * times)
@test isapprox(pop_10, expected_10; rtol=2e-2, atol=2e-2)
@test isapprox(pop_01, 1 .- expected_10; rtol=2e-2, atol=2e-2)
