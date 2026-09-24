module ExtractSQLite

import hello_data_in_julia.DatabaseSetup.MySQLite as dbs

function main(table::String)
    dbs.get_conn("hello_data", "ro") do conn
        dbs.create_arrow(conn, table)
    end
end


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS[1])
end

end # module ExtractSQLite


