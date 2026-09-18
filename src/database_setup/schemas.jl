module Schemas

using TOML

export my_data_types, RAW_TOML

schemas_path = joinpath(@__DIR__, "..", "..", "config", "schemas.toml")
const SCHEMAS_TOML = Dict(table => content["columns"] for (table, content) in TOML.parsefile(schemas_path))

"""
    parse_type_string(type_str::String)
"""
function parse_type_string(type_str::String)::Type
    try
        return Core.eval(@__MODULE__, Meta.parse(type_str))
    catch e
        error("Failed to parse type '$type_str' defined in TOML. Error: $e")
    end
end


"""
    my_data_types(table::String)
"""
function my_data_types(table::String)::Vector{Pair{Symbol, Type}}
    return map(SCHEMAS_TOML[table]) do col
        Symbol(col["name"]) => parse_type_string(col["type"])
    end
end

end # module Schemas
