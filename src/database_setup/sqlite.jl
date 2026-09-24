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
    create_arrow(conn::SQLite.DB, query::String, output_name::String) -> Nothing 
"""
function create_arrow(conn::SQLite.DB, query::String, output_name::String)::Nothing
    arrow_path = joinpath(@__DIR__, "..", "..", "data", "arrow", "$output_name.arrow")
    if table in my_tables(conn)
        result = DBInterface.execute(conn, query)
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
    ingest_csv(conn::SQLite.DB, table::String, data::CSV.Rows, columns::Vector{Symbol}) -> Nothing 
"""
function ingest_csv(conn::SQLite.DB, table::String, data::CSV.Rows, columns::Vector{Symbol})::Nothing
    if haskey(Schemas.SCHEMAS_TOML, table)
        insert = insert_query(table, columns)
        stmt = SQLite.Stmt(conn, insert)
        for batch in Iterators.partition(data, 2000)
            column_table = Tables.columntable(batch)
            DBInterface.executemany(stmt, column_table)
        end
    else
        throw(KeyError(table))
    end
    nothing
end # csv_to_sqlite


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
