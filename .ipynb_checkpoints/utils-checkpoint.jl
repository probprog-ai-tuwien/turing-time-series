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


function plot_trend_model_1_map(data, trace)
    slope, intercept, error = trace
    p = base_plot(data)
    t_min = data[!,"Date"][1]
    plot!(p, t -> slope * (t-t_min) + intercept, color="red")
    plot!(p, t -> slope * (t-t_min) + intercept + sqrt(error), color="orange")
    plot!(p, t -> slope * (t-t_min) + intercept - sqrt(error), color="orange")
    p
end

function plot_trend_model_1_posterior(data, res)
    p = base_plot(data)
    t_min = data[!,"Date"][1]
    for i in 1:length(res)
        _, trace = get_trace(res, i)
        slope, intercept, error = trace
        plot!(p, t -> slope * (t-t_min) + intercept, color="black", alpha=0.05)
    end
    p
end


function trend_model_2_f(t::Real, slope::Real, intercept::Real, changepoint::Real, adjustment::Real)
    k = slope
    m = intercept
    # UPGRADE: if the time series exeeds the changepoint, we adjust slope and intercept in a continuous way
    if changepoint ≤ t
        k += adjustment
        m -= changepoint * adjustment
    end
    return k * t + m
end

function plot_trend_model_2(data, trace)
    slope, intercept, error, changepoint, adjustment = trace
    p = base_plot(data)
    t_min = data[!,"Date"][1]
    plot!(p, t -> trend_model_2_f(t - t_min, slope, intercept, changepoint, adjustment), color="red")
    plot!(p, t -> trend_model_2_f(t - t_min, slope, intercept, changepoint, adjustment) + sqrt(error), color="orange")
    plot!(p, t -> trend_model_2_f(t - t_min, slope, intercept, changepoint, adjustment) - sqrt(error), color="orange")
    vline!([changepoint + t_min], linestyle=:dash, color="black")
    p
end

function trend_model_3_1_f(t::Real, slope::Real, intercept::Real, changepoints::Vector{<:Real}, adjustments::Vector{<:Real})
    k = slope
    m = intercept
    for (changepoint, adjustment) in zip(changepoints, adjustments)
        if changepoint ≤ t
            k += adjustment
            m -= changepoint * adjustment
        end
    end
    return k * t + m
end

function plot_trend_model_3_1(data, trace)
    slope = trace[1]
    intercept = trace[2]
    error = trace[3]
    n_changepoints = Int(trace[4])
    changepoints = trace[5:9][1:n_changepoints]
    adjustments = trace[10:14][1:n_changepoints]
    
    p = base_plot(data)
    x = data isa Tuple ? data[1] : data[!,"Date"]
    t_min = x[1]
    plot!(p, t -> trend_model_3_1_f(t - t_min, slope, intercept, changepoints, adjustments), color="red")
    plot!(p, t -> trend_model_3_1_f(t - t_min, slope, intercept, changepoints, adjustments) + sqrt(error), color="orange")
    plot!(p, t -> trend_model_3_1_f(t - t_min, slope, intercept, changepoints, adjustments) - sqrt(error), color="orange")

    vline!(changepoints[abs.(adjustments) .> 0.01] .+ t_min, linestyle=:dash, color="black")
    return p
end


function trend_model_3_f(t, slope, intercept, changepoints, adjustments)
    ix = changepoints .<= t
    return (slope + sum(adjustments[ix])) * t + (intercept - changepoints[ix]'adjustments[ix])
end

function plot_trend_model_3(data, trace)
    slope, intercept, error, adjustments = trace[1], trace[2], trace[3], trace[5:end]
    p = base_plot(data)
    x = data[!,"Date"]
    t_min = x[1]
    changepoints = x[(1:length(x)) .% 12 .== 1] .- x[1]
    plot!(p, t -> trend_model_3_f(t - t_min, slope, intercept, changepoints, adjustments), color="red")
    plot!(p, t -> trend_model_3_f(t - t_min, slope, intercept, changepoints, adjustments) + sqrt(error), color="orange")
    plot!(p, t -> trend_model_3_f(t - t_min, slope, intercept, changepoints, adjustments) - sqrt(error), color="orange")

    vline!(changepoints[abs.(adjustments) .> 0.01] .+ t_min, linestyle=:dash, color="black")
    p
end

function prophet_model_f(t, slope, intercept, changepoints, adjustments, N_frequencies, beta)
    return trend_model_3_f(t, slope, intercept, changepoints, adjustments) + seasonality_component(t, N_frequencies, beta)
end

function plot_prophet_model(data, trace, N_frequencies, n_changepoints)
    slope, intercept, error, tau = trace[1:4]
    adjustments = trace[5:(5+n_changepoints-1)]
    beta = trace[5+n_changepoints : end]

    p = base_plot(data)
    x = data[!,"Date"]
    t_min = x[1]
    changepoints = x[(1:length(x)) .% 12 .== 1] .- x[1]
    plot!(p, t -> prophet_model_f(t - t_min, slope, intercept, changepoints, adjustments, N_frequencies, beta), color="red")
    # plot!(p, t -> prophet_model_f(t - t_min, slope, intercept, changepoints, adjustments, N_frequencies, beta) + sqrt(error), color="orange")
    # plot!(p, t -> prophet_model_f(t - t_min, slope, intercept, changepoints, adjustments, N_frequencies, beta) - sqrt(error), color="orange")

    vline!(changepoints[abs.(adjustments) .> 0.01] .+ t_min, linestyle=:dash, color="black")
    p
end

function plot_forecast(x, y, x_forecast, y_pred)
    forecast = length(x_forecast)
    p = plot(x, y, label="air passenger historic data", xlabel="year", ylabel="passenger [10^7]", legend=:topleft)
    q05 = map(i -> quantile(y_pred[:,i], 0.05), 1:forecast)
    q50 = map(i -> quantile(y_pred[:,i], 0.5), 1:forecast)
    q95 = map(i -> quantile(y_pred[:,i], 0.95), 1:forecast)
    plot!(x_forecast, q50, ribbon=(q50-q05,q95-q50), label="forecast")
    return p
end

nothing