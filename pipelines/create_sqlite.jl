using Tables, SQLite
import hello_data_in_julia.DatabaseSetup.Schemas as sch
import hello_data_in_julia.DatabaseSetup.MySQLite as dbs


function create_table(table::String)
    dbs.get_conn("hello_data", "rw") do conn
        TABLE_LIST = dbs.my_tables(conn)
        println("Available Tables:")
        for t in TABLE_LIST
            println("  * $t")
        end
        if haskey(sch.SCHEMAS_TOML, table)
            schema = sch.my_data_types(table)
            columns = map(first, schema)
            d_types = map(last, schema)

            SQLite.createtable!(conn, table, Tables.Schema(columns, d_types), temp = false)
            println("
***$table created***")
            dbs.print_sqlite(conn, "PRAGMA table_info($table)")
        else
            throw(KeyError(table))
        end
    end
end # create_table


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    create_table(ARGS[1])
end
