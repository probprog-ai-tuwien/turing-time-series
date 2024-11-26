import CSV
import DataFrames
import Dates


data = CSV.read("air-passenger-all-2003-2023.csv", DataFrames.DataFrame)
data = data[data[!,:Month] .!= "TOTAL",:]
DataFrames.transform!(data, :DOMESTIC =>  DataFrames.ByRow(str -> parse(Int, replace(str, ',' => ""))) => :DOMESTIC)
DataFrames.transform!(data, :INTERNATIONAL => DataFrames.ByRow(str -> parse(Int, replace(str, ',' => ""))) => :INTERNATIONAL)
DataFrames.transform!(data, :TOTAL => DataFrames.ByRow(str -> parse(Int, replace(str, ',' => ""))) => :TOTAL)
DataFrames.transform!(data, :Month => DataFrames.ByRow(str -> parse(Int, replace(str, ',' => ""))) => :Month)
data[!,"Total"] = data[!,"TOTAL"] / 10^7
data[!,"Date"] = data[!,"Year"] .+ (data[!,"Month"] .- 1)./ 12
data[!,"ds"] = [Dates.Date(Dates.Month(m), Dates.Year(y)) for (m,y) in DataFrames.eachrow(data[!,["Month","Year"]])]


air_passengers_2013_2023 = data[data[!,:Year] .<= 2023,:]
air_passengers_2013_2018 = data[data[!,:Year] .<= 2018,:]

nothing