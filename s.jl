"""
    ingest_csv(stmt::SQLite.Stmt, data::CSV.Rows) -> Nothing
"""
function ingest_csv(stmt::SQLite.Stmt, data::CSV.Rows)::Nothing
    try
        for batch in Iterators.partition(data, 2000)
            column_table = columntable(batch)
            DBInterface.executemany(stmt, column_table)
        end
    catch e
        @error "unable to execute ingestion"
        rethrow(e)
    end
    nothing
end #ingest_cav

end #module SQLiteDBS
