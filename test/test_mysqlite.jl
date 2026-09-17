using Test
using DBInterface, SQLite, Arrow, Tables, DataFrames, CSV
using hello_data_in_julia
import hello_data_in_julia.DatabaseSetup.MySQLite as dbs

sql = "SELECT * FROM t"
schema = Tables.Schema((:id, :animal, :name), (Int32, String, String))
data = CSV.Rows(IOBuffer("id,animal,name
1,dog,Margarita
2,cat,Michi
3,bird,Pantaleon"); header=1, types=[Int32,String,String])


@testset "MySQLite.get_conn" begin
    dbs.get_conn() do conn
        @test conn isa SQLite.DB
        stmt = SQLite.Stmt(conn, "SELECT 'HELLO, WORLD!' AS greet")
        result = DBInterface.execute(stmt)
        row = first(result)
        @test row.greet == "HELLO, WORLD!"
    end
end # testset


@testset "MySQLite.sqlite_to_arrow" begin
    dbs.get_conn() do conn
        DBInterface.execute(conn, "CREATE TABLE t (id INTEGER, name TEXT)")
        DBInterface.execute(conn, "INSERT INTO t VALUES (1,'a'), (2,'b'), (3,'c'), (4,'d'), (5,'e')")

        dbs.sqlite_to_arrow(conn, sql, "test_output")

        @test isfile("data/arrow/test_output.arrow")

        tbl = Arrow.Table("data/arrow/test_output.arrow")
        @test length(tbl.id) == 5
        @test collect(tbl.id) == [1, 2, 3, 4, 5]
        @test collect(tbl.name) == ["a", "b", "c", "d", "e"]
    end

    rm("data/arrow/test_output.arrow"; force=true)
end # testset


@testset "MySQLite.sqlite_sample" begin
    dbs.get_conn() do conn
        DBInterface.execute(conn, "CREATE TABLE t (id INTEGER, name TEXT)")
        DBInterface.execute(conn, "INSERT INTO t VALUES (1,'a'), (2,'b'), (3,'c'), (4,'d'), (5,'e')")
        my_tables = dbs.my_tables(conn)
        @test "t" in my_tables

        df = dbs.sqlite_sample(conn, sql)
        @test df isa DataFrame
        @test nrow(df) == 5
        @test names(df) == ["id", "name"]
        @test df.name == ["a", "b", "c", "d", "e"]
    end
end # testset


@testset "MySQLite.csv_to_sqlite" begin
    dbs.get_conn() do conn
        SQLite.createtable!(conn, "family", schema, temp = false)
        @test ("family" in dbs.my_tables(conn))
        dbs.csv_to_sqlite(conn, "family", data)
        df = dbs.sqlite_sample(conn, "SELECT * FROM family")
        @test df.name == ["Margarita", "Michi", "Pantaleon"]
    end
end
