export ## Types
       CompositeQSystem,
       Control,
       Dissipation,
       Field,
       IndexSet,
       Interaction,
       ParametricInteraction,
       QSystem,
       ## Methods
       hamiltonian,
       dim,
       label,
       lowering,
       number,
       raising,
       strength,
       X,Y

abstract type QSystem end

label(q::QSystem) = q.label
dim(q::QSystem) = q.dim
raising(q::QSystem) = diagm(-1 => sqrt.(1:(dim(q)-1)))
lowering(q::QSystem) = diagm(1 => sqrt.(1:(dim(q)-1)))
number(q::QSystem) = raising(q) * lowering(q)
X(q::QSystem) = raising(q) + lowering(q)
Y(q::QSystem) = 1im*(raising(q) - lowering(q))
hamiltonian(q::QSystem, t) = hamiltonian(q)

abstract type Control end
label(c::Control) = c.label

abstract type Interaction end
strength(i::Interaction) = i.strength
hamiltonian(i::Interaction, t) = hamiltonian(i)

abstract type ParametricInteraction <: Interaction end

abstract type Dissipation end

const IndexSet = Vector{Int}
const ExpansionIndices = Tuple{Vector{IndexSet},Vector{IndexSet},Vector{IndexSet}}

# [todo] - Should COmpositeQSystem <: QSystem ?
mutable struct CompositeQSystem
    # [feature] - Use something like OrderedDict for component enumeration
    subSystems::Vector{QSystem}
    interactions::Vector{Interaction}
    parametericInteractions::Vector{ParametricInteraction}
    subSystemExpansions::Vector{ExpansionIndices}
    interactionExpansions::Vector{ExpansionIndices}
    dissipatorExpansions::Vector{ExpansionIndices}
    dissipators::Vector{Dissipation}
end
