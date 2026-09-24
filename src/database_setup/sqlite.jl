module MySQLite

using SQLite, Arrow, DBInterface, Tables, DataFrames, CSV
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
end # get_conn


"""
    create_arrow(conn::SQLite.DB, table::String) -> Nothing 
"""
function create_arrow(conn::SQLite.DB, table::String)::Nothing
    arrow_path = joinpath(@__DIR__, "..", "..", "data", "arrow", "$table.arrow")
    query_file = joinpath(@__DIR__, "..", "..", "oltp", "table.sql")
    sql = replace(read(query_file, String), "{table}" => table)
    if table in my_tables(conn)
        result = DBInterface.execute(conn, sql)
        open(Arrow.Writer, arrow_path) do writer
            for batch in Iterators.partition(result, 10000)
                Arrow.write(writer, batch)
            end
        end
    else
        throw(ErrorException("Table $table not found in $conn"))
    end
    nothing
end # create_arrow


"""
    ingest_csv(conn::SQLite.DB, table::String, data::CSV.Rows) -> Nothing 
"""
function create_arrow(conn::SQLite.DB, table::String)::Nothing
    arrow_path = joinpath(@__DIR__, "data", "arrow", "$table.arrow")
    query_file = joinpath(@__DIR__, "oltp", "table.sql")
    sql = replace(read(query_file, String), "{table}" => table)
    if table in dbs.my_tables(conn)
        result = DBInterface.execute(conn, sql)
        values = NamedTuple[]
        open(Arrow.Writer, arrow_path) do writer
            for row in result
                push!(values, NamedTuple(row))
                if length(values) == 10000
                    Arrow.write(writer, values)
                    values = NamedTuple[]
                end
            end
            if !isempty(values)
                Arrow.write(writer, values)
            end
        end
    else
        throw(ErrorException("Table $table not found in $conn"))
    end
    nothing
end # create_arrow


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


"""
    insert_query(table::String) -> String
"""
function insert_query(table::String, col_names::Vector{Symbol})::String
    num_columns = length(col_names)
    columns = join(col_names, ", ")
    values = join(fill("?", num_columns), ", ")
    return "INSERT INTO $table ($columns) VALUES ($values)"
end # insert_query

end # module MySQLite
