using Tables, SQLite
import hello_data_in_julia.DatabaseSetup.Schemas as sch
import hello_data_in_julia.DatabaseSetup.MySQLite as dbs


const TABLE_LIST = dbs.get_conn("hello_data", "ro") do conn
    dbs.my_tables(conn)
end


function main(table::String)
    try
        schema = sch.SCHEMAS[table]
        if !(table in TABLE_LIST)
            dbs.get_conn("hello_data", "rw") do conn
                SQLite.createtable!(conn, table, schema, temp = false)
                @info "$table created: $schema"
            end
        else
            @info "$table already exists: $schema"
        end
    catch e
        if e isa KeyError
            println("Error: ", "$table is not a valid table")
        else
            rethrow()
        end
    end
end


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS[1])
end
