
function base_plot(data)
    p = plot(data[!,"Date"], data[!,"Total"],
        legend=false, xlabel="year", ylabel="passenger [10^7]", xticks=2003:2018, xrotation=45)
    return p
end