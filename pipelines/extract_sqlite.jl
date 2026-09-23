module ExtractSQLite

import hello_data_in_julia.DatabaseSetup.MySQLite as dbs

function main(table::String, query_file::String)
    file = joinpath(@__DIR__, "..", "oltp", query_file)
    dbs.get_conn("hello_data", "ro") do conn
        if isfile(file) && table in dbs.my_tables(conn)
            query = replace(read(file, String), "{table}" => table)
            dbs.sqlite_to_arrow(conn, query, table)
        else
            throw(ArgumentError("File $file or table $table not found"))
        end
    end
end


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS[1], ARGS[2])
end

end # module ExtractSQLite
