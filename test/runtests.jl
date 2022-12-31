using VectorStoredArray
using Test

struct MarketDynamics
    NF::Int64
    Initialrate::Float32
    k1::Float32
    theta::Float32
    s1::Float32
    s0::Float32
    b0::Float32
    thetaQ::Float32
    b::Float32
    se2::Float32
end

struct OneCurrency <: StoredNode
    X0::StoredValue
    X::StoredValue
end

struct MarketState <: StoredNode
    USD::OneCurrency
end

function MarketState(t::Float32,S::Storage,Dynamics::MarketDynamics)
    X=Dynamics.Initialrate*ones(Dynamics.NF-1)
    X0=Dynamics.Initialrate
    OCM=OneCurrency(S,X0,X)
    return MarketState(S,OCM)
end

struct Matrices{N}
    State::Array{Float32,N}
end

struct DataPointers
    State::Storage
end

function Matrices(M::Matrices,D::Array{Float32})
    NS,NA=size(M.State)
return Matrices(D[1:NS,:])
end

@testset "VectorStoredArray.jl" begin
    # Write your tests here.
    MD=MarketDynamics(11,0.03,0.0388,0.0222,0.016,0.01,2.0,0.01381,1.869,0.0001)
    State0=Storage()
    State0.tree=MarketState(Float32(0.0),State0,MD)
    data=Matrices(repeat(State0.values,1,8))
    d0=Float32.(randn(11,8))
    data=Matrices(data,d0)
    ptrs= DataPointers(State0) 
    ptrs0=deepcopy(ptrs) 
    SetStorage(ptrs0.State,data.State)
    ptrs0.State.Single=true
    SetI(ptrs0.State,1)
    println(ptrs0.State.tree.USD.X0)
    SetI(ptrs0.State,2)
    printS(ptrs0.State,"Test")
    ptrs0.State.Single=false
    SetI(ptrs0.State,2)
    printS(ptrs0.State,"Test")

end
