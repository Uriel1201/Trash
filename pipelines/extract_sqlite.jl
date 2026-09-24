import hello_data_in_julia.DatabaseSetup.MySQLite as dbs

function extract_sqlite(table::String)
    query_file = joinpath(@__DIR__, "..", "oltp", "table.sql")
    query = replace(read(query_file, String), "{table}" => table)
    dbs.get_conn("hello_data", "ro") do conn
        dbs.create_arrow(conn, query, table)
    end
end # extract_table


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    extract_sqlite(ARGS[1])
end
