module VectorStoredArray
export StoredStructure,StoredNode,Storage,ImutableStorage, StoredValue,applytomatrix

abstract type StoredStructure end
abstract type StoredNode <: StoredStructure end

mutable struct Storage<: StoredStructure
    tree::StoredStructure
    values::Array{Float32,1}
    pointer::SubArray{Float32}
    function Storage()
        x=new()
        x.tree=x
        x.values=Array{Float32}(undef, 0)
        x.pointer=view(x.values,:)
        return x
    end
end


struct ImutableStorage{T} <: StoredStructure
    tree::T
    pointer::Array{Float32}
end

function ImutableStorage(S::Storage)
    pointer=S.values
    tree=SwapPointer(S.tree,pointer)
    return ImutableStorage(tree,pointer)
end

function SwapPointer(tree::T,pointer::Array{Float32}) where {T<:StoredNode} 
    FieldsInStruct=fieldnames(T)
    s=tuple()
    for n in FieldsInStruct
        f=getfield(tree,n)
        if f isa StoredValue
            out=StoredValue(view(pointer,f.index),f.index)
        else
        out=SwapPointer(f,pointer)    
        end
        s=(s...,out)
    end
    return T(s...)
end

function Base.setproperty!(x::Storage,y::Symbol,z::StoredNode)
    setfield!(x,y,z)
    setfield!(x,:pointer,view(x.values,1:length(x.values)))
end

struct StoredValue
    store::SubArray{Float32}
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
        p=p.store
    end
    return p
end

function applytomatrix(x::SubArray,m::Array{Float32})
    i=only(x.indices)

    ms=m[i,:]
    return ms
end

function Base.setproperty!(x::StoredNode,y::Symbol,z)
    p=getfield(x,y)
    if (p isa StoredValue)
        p.store[:]=TurnToArray(z)
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
        x=StoredValue(view(s.values,el+1:el+nl),el+1:el+nl)
        end
        t=tuple(t...,x)
    end
    return t
end

# Write your package code here.

end
