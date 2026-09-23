module QueryingSQLite

import hello_data_in_julia.DatabaseSetup.MySQLite as dbs
import hello_data_in_julia.DatabaseSetup.Schemas as sch


function main(table::String, query_file::String)
    file = joinpath(@__DIR__, "..", "oltp", query_file)
    dbs.get_conn("hello_data", "ro") do conn
        if isfile(file) && table in dbs.my_tables(conn)
            query = replace(read(file, String), "{table}" => table)
            dbs.print_sqlite(conn, query)
        else
            throw(ArgumentError("File $file not found or table $table does not exist"))
        end
    end
end

end # module QueryingSQLite


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS[1], ARGS[2])
end
