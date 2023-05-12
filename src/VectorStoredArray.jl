module VectorStoredArray
export StoredStructure,StoredNode,Storage,ImutableStorage, StoredValue,applytomatrix,SetStorage,SetI,printS
abstract type StoredStructure end
abstract type StoredNode <: StoredStructure end

using FloatingNumberType

mutable struct Storage<: StoredStructure
    tree::StoredStructure
    values::Array{SimType}
    i::Int64
    j::Int64
    Single::Bool
    function Storage()
        x=new()
        x.tree=x
        x.values=Array{FloatType}(undef, 0)
        x.i=1
        x.j=1
        x.Single=true
        return x
    end
end



function SetStorage(S::Storage,z)
    S.Single=false
    S.values=z
end

function SetI(S::Storage,i::Int64)
    S.i=i
end

function SetI(S::Storage,i::Int64,j::Int64)
    S.i=i
    S.j=j
end

struct ImutableStorage{T} <: StoredStructure
    tree::T
    values::Array{FloatType}
end

function ImutableStorage(S::Storage)
    values=S.values
    tree=SwapPointer(S.tree,S)
    return ImutableStorage(tree,values)
end

function SwapPointer(tree::T,S::Storage) where {T<:StoredNode} 
    FieldsInStruct=fieldnames(T)
    s=tuple()
    for n in FieldsInStruct
        f=getfield(tree,n)
        if f isa StoredValue
            out=StoredValue(S,f.index)
        else
        out=SwapPointer(f,S)    
        end
        s=(s...,out)
    end
    return T(s...)
end

function Base.setproperty!(x::Storage,y::Symbol,z::StoredNode)
    setfield!(x,y,z)
    #setfield!(x,:values,view(x.values,1:length(x.values)))
end

struct StoredValue
    store::Storage
    index::UnitRange{Int64}
end


function (::Type{T})(s::Storage,x...) where {T<:StoredNode}  
    t=AssignVariable(s,x)
    T(t...)
end

function TurnToArray(x::Number)
return [x]
end

function TurnToArray(x::AbstractArray)
    return x
end

function Base.getproperty(x::StoredNode,y::Symbol)
    p=getfield(x,y)
    if (p isa StoredValue)
        if ndims(p.store.values)==3
        if p.store.Single
        p=p.store.values[p.index,p.store.i,p.store.j]
        else
        p=p.store.values[p.index,:,:]    
        end
        else
            if p.store.Single
                p=p.store.values[p.index,p.store.i]
                else
                p=p.store.values[p.index,:]    
                end
        end
    end
    return p
end

function printS(x::StoredNode,S::String)
    for nm in fieldnames(typeof(x))
        p=getfield(x,nm)
        printS(p,S*"."*string(nm))
    end
end

function printS(p::StoredValue,S::String)
    if ndims(p.store.values)==3
        if p.store.Single
        p=p.store.values[p.index,p.store.i,p.store.j]
        else
        p=p.store.values[p.index,:,:]    
        end
    else
            if p.store.Single
                p=p.store.values[p.index,p.store.i]
                else
                p=p.store.values[p.index,:]    
                end
    end
    
    println(S)
    println(p)
end

function printS(x::Storage,S::String)
    printS(x.tree,S*".")
end


function applytomatrix(x::SubArray,m::Array{FloatType})
    i=only(x.indices)

    ms=m[i,:]
    return ms
end

function Base.setproperty!(x::StoredNode,y::Symbol,z)
    p=getfield(x,y)
    if (p isa StoredValue)
        if ndims(p.store.values)==3
        p.store.values[p.index,p.store.i,p.store.j]=TurnToArray(z)
        else
            p.store.values[p.index,p.store.i]=TurnToArray(z)  
        end
    else
        p=setfield!(x,y,z)
    end
end

function AssignVariable(s,p)
    t=tuple()
    for iterator in p
        if (iterator isa StoredNode)
        x=iterator
        else
        el=length(s.values)
        nl=length(iterator)   
        x=TurnToArray(iterator)
        s.values=[s.values;x]
        x=StoredValue(s,el+1:el+nl)
        end
        t=tuple(t...,x)
    end
    return t
end

# Write your package code here.

end
