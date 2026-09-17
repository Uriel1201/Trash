using Test
using DBInterface, SQLite, Arrow, Tables, DataFrames, CSV
using hello_data_in_julia
import hello_data_in_julia.DatabaseSetup.Schemas as sch
import hello_data_in_julia.DatabaseSetup.MySQLite as dbs

sql = "SELECT * FROM family"
schema = sch.my_data_types("family")
#=
data = CSV.Rows(IOBuffer("alias,animal,cumpleaños 
Margarita,dog,11-Jan-2018
Uriel,human,12-Dic-1993
Angel,human,06-Jan-2007"); header=1, types=[Int32,String,String], skipto=2)
end # testset=#

@testset "loading TOML schemas" begin
    @test haskey(sch.SCHEMAS, "family")
    @test schema isa Dict{Symbol, Type}
    @test issetequal(keys(schema), [:name, :genre, :birthday])
    @test_throws ErrorException("'perro_del_mal' isn't registered in the current TOML.") sch.my_data_types("perro_del_mal")
end


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
        DBInterface.execute(conn, "CREATE TABLE family (name TEXT, genre TEXT, birthday TEXT)")
        DBInterface.execute(conn, "INSERT INTO family VALUES ('Margarita', 'dog', '11-Jan-2018'), ('Uriel', 'human', '01-Dic-93'), ('Angel', 'human', '06-06-2007')")

        dbs.sqlite_to_arrow(conn, sql, "test_output")

        @test isfile("data/arrow/test_output.arrow")

        tbl = Arrow.Table("data/arrow/test_output.arrow")
        @test length(tbl.name) == 3
        @test collect(tbl.name) == ["Margarita", "Uriel", "Angel"]
        @test collect(tbl.genre) == ["dog", "human", "human"]
    end

    rm("data/arrow/test_output.arrow"; force=true)
end # testset


@testset "reading a sample query as DataFrame" begin
    dbs.get_conn() do conn
        DBInterface.execute(conn, "CREATE TABLE t (id INTEGER, name TEXT)")
        DBInterface.execute(conn, "INSERT INTO t VALUES (1,'a'), (2,'b'), (3,'c'), (4,'d'), (5,'e')")
        my_tables = dbs.my_tables(conn)
        @test "t" in my_tables

        df = dbs.sqlite_sample(conn, "SELECT * FROM t")
        @test df isa DataFrame
        @test nrow(df) == 5
        @test names(df) == ["id", "name"]
        @test df.name == ["a", "b", "c", "d", "e"]
    end
end # testset


@testset "loading a csv file to SQLite" begin
    dbs.get_conn() do conn
        columns = Tuple(keys(schema))
        vals = Tuple(values(schema))
        SQLite.createtable!(conn, "family", Tables.Schema(columns, vals), temp = false)
        @test ("family" in dbs.my_tables(conn))
        @test dbs.insert_query("family") == "INSERT INTO family (name, genre, birthday) VALUES (?, ?, ?)"
        #dbs.csv_to_sqlite(conn, "family", schema, data)
        #df = dbs.sqlite_sample(conn, "SELECT * FROM family")
        #@test df.name == ["Margarita", "Michi", "Pantaleon"]
    end
end # testset =#
