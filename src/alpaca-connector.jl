module alpaca_connector

using HTTP
using JSON
using DataFrames
using Dates

export get_historical_data

"""
    get_historical_data(api_key, api_secret, ticker, timeframe, start_time, limit)

Retrieve historical stock data from Alpaca Market Data V2 API.

# Arguments
- `api_key::String`: Alpaca API key
- `api_secret::String`: Alpaca API secret
- `ticker::String`: Stock ticker symbol (e.g., "AAPL")
- `timeframe::String`: Candle timeframe (e.g., "1Day", "1Hour", "1Min")
- `start_time::String`: Start time in ISO 8601 format (e.g., "2023-01-01T00:00:00Z")
- `limit::Int`: Maximum number of candles to retrieve

# Returns
- `DataFrame`: DataFrame containing historical data ordered from oldest to newest

# Examples
```julia
get_historical_data("your_api_key", "your_api_secret", "AAPL", "1Day", "2023-01-01T00:00:00Z", 100)
```
"""
function get_historical_data(api_key::String, api_secret::String, ticker::String, 
                             timeframe::String, start_time::String, limit::Int)
    
    # Alpaca Market Data V2 API endpoint
    base_url = "https://data.alpaca.markets/v2"
    endpoint = "/stocks/$(ticker)/bars"
    
    # Query parameters
    params = Dict(
        "timeframe" => timeframe,
        "start" => start_time,
        "limit" => string(limit)
    )
    
    # Build URL with query parameters
    query_string = "?" * join(["$(k)=$(v)" for (k, v) in params], "&")
    url = base_url * endpoint * query_string
    
    # Set up headers with authentication
    headers = Dict(
        "APCA-API-KEY-ID" => api_key,
        "APCA-API-SECRET-KEY" => api_secret
    )
    
    try
        # Make the HTTP GET request
        response = HTTP.get(url, headers)
        
        # Check if request was successful
        if response.status != 200
            error("API request failed with status: ", response.status, " - ", String(response.body))
        end
        
        # Parse JSON response
        data = JSON.parse(String(response.body))
        
        # Check if we got bars data
        if !haskey(data, "bars") || isempty(data["bars"])
            return DataFrame()
        end
        
        # Extract bars data
        bars = data["bars"]
        
        # Convert to DataFrame
        df = DataFrame(
            timestamp = [DateTime(bar["t"]) for bar in bars],
            open = [bar["o"] for bar in bars],
            high = [bar["h"] for bar in bars],
            low = [bar["l"] for bar in bars],
            close = [bar["c"] for bar in bars],
            volume = [bar["v"] for bar in bars]
        )
        
        # Sort by timestamp (oldest to newest)
        sort!(df, :timestamp)
        
        return df
        
    catch e
        error("Error fetching historical data: ", e)
    end
end

end # module