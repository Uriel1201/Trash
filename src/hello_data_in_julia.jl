module hello_data_in_julia
module DatabaseSetup
    include("database_setup/schemas.jl")
    include("database_setup/sqlite.jl")
end # DatabaseSetup
export DatabaseSetup

greet() = print("Hello World!")

end # module hello_data_in_julia


