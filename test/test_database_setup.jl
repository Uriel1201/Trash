using Test
using DBInterface, SQLite, Arrow, Tables, DataFrames, CSV
using hello_data_in_julia
import hello_data_in_julia.DatabaseSetup.Schemas as sch
import hello_data_in_julia.DatabaseSetup.MySQLite as dbs


schema = sch.my_data_types("family")


@testset "loading TOML schemas" begin
    @test haskey(sch.SCHEMAS_TOML, "family")
    @test schema isa Vector{Pair{Symbol,Type}}
    @test map(first, schema) == [:name, :gender, :birthday]
    @test map(last, schema) == [String, String, String]
    @test_throws ErrorException("Table 'perro_del_mal' not found in schemas.toml") sch.my_data_types(
        "perro_del_mal",
    )
end # test_set


@testset "getting a connection to SQLite" begin
    dbs.get_conn() do conn
        @test conn isa SQLite.DB
        stmt = SQLite.Stmt(conn, "SELECT 'HELLO, WORLD!' AS greet")
        result = DBInterface.execute(stmt)
        row = first(result)
        @test row.greet == "HELLO, WORLD!"
    end
end # testset


@testset "converting SQLite query to IPC file" begin
    dbs.get_conn() do conn
        DBInterface.execute(
            conn,
            "CREATE TABLE family (name TEXT, genre TEXT, birthday TEXT)",
        )
        DBInterface.execute(
            conn,
            "INSERT INTO family VALUES ('Margarita', 'dog', '11-Jan-2018'), ('Uriel', 'human', '01-Dic-93'), ('Angel', 'human', '06-06-2007')",
        )
        @test_throws SQLiteException dbs.create_arrow(
            conn,
            "SELECT * FROM perro_del_mal",
            "perro_del_mal"
        )
        dbs.create_arrow(conn, "SELECT * FROM family WHERE name = 'Margarita'", "family")
        arrow_file = joinpath(@__DIR__, "..", "data", "arrow/family.arrow")
        @test isfile(arrow_file)

        tbl = Arrow.Table(arrow_file)
        @test length(tbl.name) == 1
        @test collect(tbl.name) == ["Margarita"]
        @test collect(tbl.genre) == ["dog"]
    end

    rm("data/arrow/family.arrow"; force = true)
end # testset


@testset "reading query results into a DataFrame" begin
    dbs.get_conn() do conn
        DBInterface.execute(conn, "CREATE TABLE t (id INTEGER, name TEXT)")
        DBInterface.execute(
            conn,
            "INSERT INTO t VALUES (1,'a'), (2,'b'), (3,'c'), (4,'d'), (5,'e')",
        )
        my_tables = dbs.my_tables(conn)
        @test "t" in my_tables

        df = dbs.sqlite_sample(conn, "SELECT * FROM t")
        @test df isa DataFrame
        @test nrow(df) == 5
        @test names(df) == ["id", "name"]
        @test df.name == ["a", "b", "c", "d", "e"]
    end
end # testset


columns = map(first, schema)
data_types = map(last, schema)
data = CSV.Rows(
    IOBuffer("alias,animal,cumpleaños
Margarita,dog,11-Jan-2018
Uriel,human,12-Dic-1993
Angel,human,06-Jan-2007");
    header = columns,
    types = data_types,
    skipto = 2,
)
@testset "loading a csv file to SQLite" begin
    dbs.get_conn() do conn
        SQLite.createtable!(
            conn,
            "family",
            Tables.Schema(columns, data_types),
            temp = false,
        )
        @test "family" in dbs.my_tables(conn)
        @test dbs.insert_query("family", columns) ==
              "INSERT INTO family (name, gender, birthday) VALUES (?, ?, ?)"

        @test_throws KeyError dbs.ingest_csv(conn, "perro_del_mal", data)
        @test_throws SQLiteException dbs.ingest_csv(conn, "transactions_02", data)
        dbs.ingest_csv(conn, "family", data)
        df = dbs.sqlite_sample(conn, "SELECT * FROM family")
        @test df.name == ["Margarita", "Uriel", "Angel"]
    end
end # testset


