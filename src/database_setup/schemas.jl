module Schemas

using TOML, OrderedCollections

export SCHEMAS, my_data_types, load_schemas!

const SCHEMAS = Dict{String, OrderedDict{Symbol, Type}}()


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

#=
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
        table_dict = OrderedDict{Symbol, Type}()
        for (col_name, type_str) in columns
            table_dict[Symbol(col_name)] = parse_type_string(type_str)
        end
        SCHEMAS[table] = table_dict
    end

    return SCHEMAS
end


"""
    my_data_types(table::String)
"""
function my_data_types(table::String)::Dict{Symbol, Type}
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
end =#

end # module Schemas 
