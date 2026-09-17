using Tables, SQLite
import hello_data_in_julia.DatabaseSetup.Schemas as sch
import hello_data_in_julia.DatabaseSetup.MySQLite as dbs


const TABLE_LIST = dbs.get_conn("hello_data", "ro") do conn
    dbs.my_tables(conn)
end


function users_01(conn::SQLite.DB)::Nothing
    table = "users_01"
    if !(table in dbs.my_tables(conn))
        SQLite.createtable!(conn, table, sch.SCHEMAS[table], temp = false)
        @info $table created:$schema.names, $schema.types
    else
        @info "$table already exists"
    end
    nothing
end


function main()
    dbs.get_conn("hello_data", "rw") do conn
        println("uri: $conn connected")
        users_01(conn)
    end
end


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main()
end
