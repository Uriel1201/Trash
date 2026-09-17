module Schemas

using TOML
using Dates

export SCHEMAS, csv_types, load_schemas!

const SCHEMAS = Dict{String, Dict{Symbol, Type}}()


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
    load_schemas!(toml_path::String)
"""
function load_schemas!(toml_path::String)
    if !isfile(toml_path)
        error("$toml_path: does not exist")
    end

    raw_data = TOML.parsefile(toml_path)
    empty!(SCHEMAS)

    for (table, columns) in raw_data
        table_dict = Dict{Symbol, Type}()
        for (col_name, type_str) in columns
            table_dict[Symbol(col_name)] = parse_type_string(type_str)
        end
        SCHEMAS[table] = table_dict
    end

    return SCHEMAS
end


"""
    csv_types(table::String)
"""
function csv_types(table::String)::Dict{Symbol, Type}
    if isempty(SCHEMAS)
        error("SCHEMAS dont loaded. Call 'Schemas.load_schemas!(path)' first.")
    end

    return get(SCHEMAS, table) do
        error("'$table' isn't registered in the current TOML.")
    end
end


function __init__()
    default_path = joinpath(@__DIR__, "..", "..", "config", "schemas.toml")
    if isfile(default_path)
        load_schemas!(default_path)
    end
end

end # module Schemas
