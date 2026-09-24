import hello_data_in_julia.DatabaseSetup.MySQLite as dbs

function extract_sqlite(table::String)
    dbs.get_conn("hello_data", "ro") do conn
        dbs.create_arrow(conn, table)
    end
end # extract_table


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    extract_sqlite(ARGS[1])
end
