module Schemas
using Tables


const TABLE_01 = Tables.Schema(
    (:user_id, :action, :action_date),
    (Int64, Union{String,Missing}, Union{String,Missing}),
)
const TABLE_02 = Tables.Schema(
    (:sender, :receiver, :amount, :transaction_date),
    (:Int64, Union{Int64, Missing}, Union{Float64, Missing}, Union{String, Missing}),
)
const TABLE_03 = Tables.Schema(
    (:date, :item),
    (String, Union{String, Missing}),
)
const TABLE_04 = Tables.Schema(
    (:id, :action, :action_date),
    (Int64, Union{String, Missing}, Union{String, Missing}),
)
const TABLE_05 = Tables.Schema(
    (:user_id, :product_id, :transaction_date),
    (Int64, Union{Int64, Missing}, Union{String, Missing}),
)


const SCHEMAS = Dict(
    "users_01" => TABLE_01,
    "transactions_02" => TABLE_02,
    "items_03" => TABLE_03,
    "users_04" => TABLE_04,
    "users_05" => TABLE_05,
)


function csv_types(nombre_tabla::String)
    schema = SCHEMAS[nombre_tabla]
    return Dict(zip(schema.names, schema.types))
end

end # module Schemas
