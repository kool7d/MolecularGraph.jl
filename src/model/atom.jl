#
# This file is a part of MolecularGraph.jl
# Licensed under the MIT License http://opensource.org/licenses/MIT
#

export
    SDFAtom, SMILESAtom,
    setcharge, setstereo, atomnumber, atomsymbol


const ATOMTABLE = let
    weightsfile = joinpath(dirname(@__FILE__), "../../assets/const/atomicweights.yaml")
    include_dependency(weightsfile)
    YAML.load(open(weightsfile))
end

const ATOMSYMBOLMAP = let
    symbolfile = joinpath(dirname(@__FILE__), "../../assets/const/symboltonumber.yaml")
    include_dependency(symbolfile)
    YAML.load(open(symbolfile))
end

const ATOM_COVALENT_RADII = let
    radiifile = joinpath(dirname(@__FILE__), "../../assets/const/covalent_radii.csv")
    include_dependency(radiifile)
    tab, headers = readdlm(radiifile, '\t', String; header=true, comments=true)
    radii = Dict{Int,Union{Float32,Dict{String,Float32}}}()
    for i = 1:size(tab, 1)
        an = parse(Int, tab[i, 1])
        container = if !haskey(radii, an)
            if i < size(tab, 1) && tab[i+1,1] == tab[i,1]  # special handling for elements with multiple options
                radii[an] = Dict{String,Float32}()
            else
                nothing
            end
        else
            radii[an]
        end
        ar = parse(Float32, tab[i, 3])
        if container === nothing
            radii[an] = ar
        else
            container[tab[i, 2]] = ar
        end
    end
    radii
end

const ATOM_VANDERWAALS_RADII = let
    radiifile = joinpath(dirname(@__FILE__), "../../assets/const/vanderWaals_radii.csv")
    include_dependency(radiifile)
    tab, headers = readdlm(radiifile, '\t', String; header=true, comments=true)
    radii = Dict{Int,Float32}()
    for i = 1:size(tab, 1)
        an = parse(Int, tab[i, 1])
        ar = parse(Float32, tab[i, 2])
        radii[an] = ar
    end
    radii
end


struct SDFAtom
    symbol::Symbol
    charge::Int
    multiplicity::Int
    mass::Union{Int, Nothing}
    coords::Union{Vector{Float64}, Nothing}
    stereo::Symbol  # deprecated

    function SDFAtom(sym, chg, mul, ms, coords, stereo)
        haskey(ATOMSYMBOLMAP, string(sym)) || throw(ErrorException("Unsupported atom symbol: $(sym)"))
        new(sym, chg, mul, ms, coords, stereo)
    end
end

SDFAtom(sym, chg, mul, ms, coords) = SDFAtom(sym, chg, mul, ms, coords, :unspecified)
SDFAtom() = SDFAtom(:C, 0, 1, nothing, nothing, :unspecified)
SDFAtom(d::Dict{T,Any}) where T <: Union{AbstractString,Symbol} = SDFAtom(
    Symbol(d[T("symbol")]), d[T("charge")], d[T("multiplicity")],
    d[T("mass")], d[T("coords")], :unspecified)

Base.getindex(a::SDFAtom, prop::Symbol) = getproperty(a, prop)

function to_dict(a::SDFAtom)
    data = Dict{String,Any}()
    for field in fieldnames(SDFAtom)
        data[string(field)] = getfield(a, field)
    end
    return data
end

setcharge(a::SDFAtom, chg
    ) = SDFAtom(a.symbol, chg, a.multiplicity, a.mass, a.coords)  # deprecated

setstereo(a::SDFAtom, direction) = SDFAtom(
    a.symbol, a.charge, a.multiplicity, a.mass, a.coords, direction)  # deprecated


struct SMILESAtom
    symbol::Symbol
    charge::Int
    multiplicity::Int
    mass::Union{Int, Nothing}
    isaromatic::Union{Bool, Nothing}
    stereo::Symbol
end


SMILESAtom() = SMILESAtom(:C, 0, 1, nothing, false, :unspecified)
SMILESAtom(d::Dict{T,U}) where {T<:Union{AbstractString,Symbol},U} = SMILESAtom(
    Symbol(get(d, T("symbol"), :C)),
    get(d, T("charge"), 0),
    get(d, T("multiplicity"), 1),
    get(d, T("mass"), nothing),
    get(d, T("isaromatic"), false),
    Symbol(get(d, T("stereo"), :unspecified))
)

Base.getindex(a::SMILESAtom, prop::Symbol) = getproperty(a, prop)

function todict(a::SMILESAtom)
    data = Dict{String,Any}()
    for field in fieldnames(SMILESAtom)
        data[string(field)] = getfield(a, field)
    end
    return data
end

setcharge(a::SMILESAtom, chg) = SMILESAtom(
    a.symbol, chg, a.multiplicity, a.mass, a.isaromatic, a.stereo)

setstereo(a::SMILESAtom, direction) = SMILESAtom(
    a.symbol, a.charge, a.multiplicity, a.mass, a.isaromatic, direction)


"""
    atomnumber(atomsymbol::Symbol) -> Int
    atomnumber(atom::Atom) -> Int

Return atom number.
"""
atomnumber(atomsymbol::Symbol) = ATOMSYMBOLMAP[string(atomsymbol)]
atomnumber(a::SDFAtom) = atomnumber(a.symbol)
atomnumber(a::SMILESAtom) = atomnumber(a.symbol)



"""
    atomsymbol(n::Int) -> Symbol

Return atom symbol of given atomic number.
"""
atomsymbol(n::Int) = Symbol(ATOMTABLE[n]["Symbol"])
