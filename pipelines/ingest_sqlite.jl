using CSV
import hello_data_in_julia.DatabaseSetup.MySQLite as dbs
import hello_data_in_julia.DatabaseSetup.Schemas as sch


function ingest_sqlite(table::String, csv_file::String)
    csv_path = joinpath(@__DIR__, "..", "data", "csv", csv_file)
    if isfile(csv_path)
        schema = sch.my_data_types(table)
        columns = map(first, schema)
        try
            data = CSV.Rows(
                csv_path;
                header = columns,
                types = map(last, schema),
                skipto = 2,
            )
        catch e
            @error "Unable to parse CSV file" csv_path exception=(e, catch_backtrace())
            rethrow()
        end

        dbs.get_conn("hello_data", "rw") do conn
            dbs.ingest_csv(conn, table, data, columns)
            println("***csv file $csv_path ingested***")
        end
    else
        throw(ErrorException("File $csv_path not found in directory"))
    end
end # csv_to_sqlite


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    ingest_sqlite(ARGS[1], ARGS[2])
end
