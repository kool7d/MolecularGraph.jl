#
# This file is a part of MolecularGraph.jl
# Licensed under the MIT License http://opensource.org/licenses/MIT
#

import Graphs:
    AbstractGraph, edgetype, is_directed, nv, vertices, ne, edges,
    has_vertex, has_edge, inneighbors, outneighbors

export
    AbstractMolGraph, OrderedMolGraph, AbstractReaction,
    to_dict, edge_rank, undirectededge


abstract type AbstractMolGraph{T} <: AbstractGraph{T} end
abstract type OrderedMolGraph{T} <: AbstractMolGraph{T} end

abstract type AbstractReaction{T<:AbstractMolGraph} end


Base.copy(g::AbstractMolGraph) = deepcopy(mol)
Base.eltype(g::AbstractMolGraph) = eltype(typeof(g))
edgetype(g::AbstractMolGraph) = edgetype(typeof(g))
is_directed(::Type{<:AbstractMolGraph}) = false

nv(g::AbstractMolGraph) = nv(g.graph)
vertices(g::AbstractMolGraph) = vertices(g.graph)
ne(g::AbstractMolGraph) = ne(g.graph)
edges(g::AbstractMolGraph) = edges(g.graph)

has_vertex(g::AbstractMolGraph, x::Integer) = has_vertex(g.graph, x)
has_edge(g::AbstractMolGraph, s::Integer, d::Integer) = has_edge(g.graph, s, d)

inneighbors(g::AbstractMolGraph, v::Integer) = inneighbors(g.graph, v)
outneighbors(g::AbstractMolGraph, v::Integer) = outneighbors(g.graph, v)

"""
    edge_rank

A workaround for edge indices that are not yet implemented in SimpleGraph
"""
function edge_rank(g::SimpleGraph, u::Integer, v::Integer)
    u, v = u < v ? (u, v) : (v, u)
    i = zero(u)
    cnt = 0
    @inbounds while i < u
        i += one(u)
        for j in g.fadjlist[i]
            if j > i
                cnt += 1
                j == v && break
            end
        end
    end
    return cnt
end

edge_rank(g::SimpleGraph, e::Edge) = edge_rank(g, src(e), dst(e))

"""
    undirectededge

A workaround for UndirectedEdge that are not yet implemented in SimpleGraph
"""
undirectededge(::Type{T}, src, dst) where T <: Edge = src < dst ? T(src, dst) : T(dst, src)
undirectededge(src::Int, dst::Int) = undirectededge(Edge{Int}, src, dst)