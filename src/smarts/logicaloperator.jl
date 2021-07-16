#
# This file is a part of MolecularGraph.jl
# Licensed under the MIT License http://opensource.org/licenses/MIT
#


"""
    lglowand!(state::SmartsParserState) -> Union{Pair,Nothing}

LogicalLowAnd <- Or (';' Or)*

The argument `func` is a parser function which has a parser state as an argument,
process tokens found in the given text, and returns nothing if no valid tokens were found.
"""
function lglowand!(state::SmartsParserState, func)
    fmls = []
    fml = lgor!(state, func)
    fml === nothing && return
    while fml !== nothing
        push!(fmls, fml)
        if read(state) == ';'
            forward!(state)
            fml = lgor!(state, func)
        else
            break
        end
    end
    @assert !isempty(fmls) "(lglowand!) invalid AND(;) operation"
    if length(fmls) == 1
        return fmls[1]
    else
        return :and => Tuple(fmls)
    end
end


"""
    lgor!(state::SmartsParserState) -> Union{Pair,Nothing}

Or <- And (',' And)*

The argument `func` is a parser function which has a parser state as an argument,
process tokens found in the given text, and returns nothing if no valid tokens were found.
"""
function lgor!(state::SmartsParserState, func)
    fmls = []
    fml = lghighand!(state, func)
    fml === nothing && return
    while fml !== nothing
        push!(fmls, fml)
        if read(state) == ','
            forward!(state)
            fml = lghighand!(state, func)
        else
            break
        end
    end
    @assert !isempty(fmls) "(lgor!) invalid OR(,) operation"
    if length(fmls) == 1
        return fmls[1]
    else
        return :or => Tuple(fmls)
    end
end


"""
    lghighand!(state::SmartsParserState) -> Union{Pair,Nothing}

And <- Not ('&'? Not)*

The argument `func` is a parser function which has a parser state as an argument,
process tokens found in the given text, and returns nothing if no valid tokens were found.
"""
function lghighand!(state::SmartsParserState, func)
    fmls = []
    fml = lgnot!(state, func)
    fml === nothing && return
    while fml !== nothing
        if fml != (:skip => true)  # valid token but no meaning (ex. wildcard atom *)
            push!(fmls, fml)
        end
        if read(state) == '&'
            forward!(state)
        end
        fml = lgnot!(state, func)
    end
    @assert !isempty(fmls) "(lghighand!) invalid AND(&) operation"
    if length(fmls) == 1
        return fmls[1]
    else
        return :and => Tuple(fmls)
    end
end


"""
    lgnot!(state::SmartsParserState) -> Union{Pair,Nothing}

Not <- '!'? Element

The argument `func` is a parser function which has a parser state as an argument,
process tokens found in the given text, and returns nothing if no valid tokens were found.
"""
function lgnot!(state::SmartsParserState, func)
    if read(state) == '!'
        forward!(state)
        fml = func(state)
        @assert fml !== nothing "(lgnot!) invalid NOT(!) operation"
        return :not => fml
    end
    return func(state)  # can be Nothing if the parser get stop token
end
