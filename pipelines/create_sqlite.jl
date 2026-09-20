using Tables, SQLite
using hello_data_in_julia
import hello_data_in_julia.DatabaseSetup.Schemas as sch
import hello_data_in_julia.DatabaseSetup.MySQLite as dbs


const TABLE_LIST = dbs.get_conn("hello_data", "ro") do conn
    dbs.my_tables(conn)
end

function main(table::String)
    println("Available Tables:")
    for table in TABLE_LIST
        println("  * $table")
    end

    schema = sch.my_data_types(table)
    columns = map(first, schema)
    d_types = map(last, schema)
    if !(table in TABLE_LIST)
        dbs.get_conn("hello_data", "rw") do conn
            SQLite.createtable!(conn, table, Tables.Schema(columns, d_types), temp = false)
            @info "$table created"
            dbs.print_sqlite(conn, "PRAGMA table_info($table)")
        end
    else
        @info "$table already exists"
        dbs.get_conn("hello_data", "ro") do conn
            dbs.print_sqlite(conn, "PRAGMA table_info($table)")
        end
    end
end


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS[1])
end
