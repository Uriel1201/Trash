module CreateSQLite

using Tables, SQLite
import hello_data_in_julia.DatabaseSetup.Schemas as sch
import hello_data_in_julia.DatabaseSetup.MySQLite as dbs


function main(table::String)
    dbs.get_conn("hello_data", "rw") do conn
        TABLE_LIST = dbs.my_tables(conn)
        println("Available Tables:")
        for t in TABLE_LIST
            println("  * $t")
        end
        if !(table in TABLE_LIST)
            schema = sch.my_data_types(table)
            columns = map(first, schema)
            d_types = map(last, schema)
    
            SQLite.createtable!(conn, table, Tables.Schema(columns, d_types), temp = false)
            @info "$table created"
            dbs.print_sqlite(conn, "PRAGMA table_info($table)")
        
        else
            @info "$table already exists"
            dbs.print_sqlite(conn, "PRAGMA table_info($table)")
        end
    end
end

end #module CreateSQLite


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS[1])
end
