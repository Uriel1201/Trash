using CSV
import hello_data_in_julia.DatabaseSetup.MySQLite as dbs
import hello_data_in_julia.DatabaseSetup.Schemas as sch


function csv_to_sqlite(table::String, csv_file::String)
    csv_path = joinpath(@__DIR__, "..", "data", "csv", csv_file)
    if isfile(csv_path)
        schema = sch.my_data_types(table)
        data = CSV.Rows(
            csv_path;
            header = map(first, schema),
            types = map(last, schema),
            skipto = 2,
        )
        dbs.get_conn("hello_data", "rw") do conn
            dbs.ingest_csv(conn, table, data)
            println("***csv file $csv_path ingested***")
        end
    else
        throw(ArgumentError("File $csv_path not found in directory"))
    end
end # csv_to_sqlite


if Base.@isdefined(PROGRAM_FILE) && abspath(PROGRAM_FILE) == abspath(@__FILE__)
    csv_to_sqlite(ARGS[1], ARGS[2])
end


