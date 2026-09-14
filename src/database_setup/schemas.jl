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

end # module Schemas
