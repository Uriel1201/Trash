
module Schemas
using Tables


const USERS_01 = Tables.Schema(
    (:user_id, :action, :action_date),
    (Int64, Union{String,Missing}, Union{String,Missing}),
)


const SCHEMAS = Dict("users_01" => USERS_01)


function csv_types(nombre_tabla::String)
    schema = SCHEMAS[nombre_tabla]
    return Dict(zip(schema.names, schema.types))
end


function insert_query(table::String)::String
    schema = Schemas.SCHEMAS[table]
    num_columns = length(schema.names)

    columns = "(" * join([String(v) for v in schema.names], ", ") * ")"
    values = " VALUES (" * join(["?" for _ in schema.names], ", ") * ")"
    return "INSERT INTO " * "$table " * columns * values
end
end # module Schemas
