function get_trace(res, i)
    m = res[i]
    return m.name_map.parameters, reshape(m.value.data, :)[1:length(m.name_map.parameters)] 
end

function get_map(res)
    return get_trace(res, argmax(vec(res[:lp]))) # discard internal parameters
end

function base_plot(data)
    if data isa Tuple
        x, y = data
    else
        x = data[!,"Date"]
        y = data[!,"Total"]
    end
    year_min = Int(floor(minimum(x)))
    year_max = Int(ceil(maximum(x)))
    p = plot(x, y,
        legend=false, xlabel="year", ylabel="passenger [10^7]", xticks=year_min:year_max, xrotation=45)
    return p
end

nothing