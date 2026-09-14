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


function csv_path(csv::String)::Union{Vector{String}, String}
    dir = joinpath(@__DIR__, "data", "csv", csv)
    if isdir(dir)
        return joinpath.(dir, filter(f -> endswith(f, ".csv"), readdir(dir)))
    elseif isfile(dir)
        return dir
    else
        throw(ArgumentError("$csv is invalid"))
    end
end

end # module Schemas
