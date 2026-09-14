module MySQLite

using SQLite, Arrow, DBInterface, Tables, DataFrames
using ..Schemas


"""
    get_conn(f::Function, db_path::String = ":memory:", mode::String = "rw")
"""
function get_conn(f::Function, db_path::String = ":memory:", mode::String = "rw")
    if db_path == ":memory:"
        uri = "file::memory:?cache=shared"
        db = SQLite.DB()
    else
        path = joinpath("data", "$db_path.sqlite")
        uri = ispath(path) ? "file:$path?mode=$mode" : "file:$path"
        db = SQLite.DB(uri)
    end
    @info "URI: $uri connected"
    try
        return f(db)
    finally
        SQLite.close(db)
    end
end #get_conn


"""
    sqlite_to_arrow(conn::SQLite.DB, query::String, output_file::String)
"""
function sqlite_to_arrow(conn::SQLite.DB, query::String, output_file::String)::Nothing

    file_path = joinpath("data/arrow", "$output_file.arrow")

    result = DBInterface.execute(conn, query)

    open(Arrow.Writer, file_path) do writer

        batch = NamedTuple[]

        for row in result
            push!(batch, NamedTuple(row))

            if length(batch) == 10000
                table = Tables.columntable(batch)
                Arrow.write(writer, table)

                batch = NamedTuple[]
            end
        end

        if !isempty(batch)
            table = Tables.columntable(batch)
            Arrow.write(writer, table)
        end
    end

    nothing
end #sqlite_to_arrow


"""
    sqlite_sample(conn::SQLite.DB, query::String) -> DataFrame
"""
function sqlite_sample(conn::SQLite.DB, query::String)::DataFrame
    result = DBInterface.execute(conn, query)
    batch = NamedTuple[]
    for row in Iterators.take(result, 100)
        push!(batch, NamedTuple(row))
    end
    return DataFrame(batch)
end # sqlite_sample


"""
    print_sqlite(conn::SQLite.DB, query::String) -> Nothing 
"""
function print_sqlite(conn::SQLite.DB, query::String)::Nothing
    show(sqlite_sample(conn, query))
    nothing
end # print_sqlite


"""
    my_tables(conn::SQLite.DB) -> Vector{String}
"""
function my_tables(conn::SQLite.DB)::Vector{String}
    list_tables = collect(SQLite.tables(conn))
    return [t.name for t in list_tables]
end # my_tables

end # module MySQLite


"""
"""
function insert_query(table::String)::String
    schema = Schemas.SCHEMAS[table]
    num_columns = length(schema.names)

    columns = "(" * join([String(v) for v in schema.names], ", ") * ")"
    values = " VALUES (" * join(["?" for _ in schema.names], ", ") * ")"
    return "INSERT INTO " * "$table " * columns * values
end

end # module MySQLite
