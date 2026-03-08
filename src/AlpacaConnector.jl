module AlpacaConnector

using HTTP
using JSON
using DataFrames
using Dates
using TimeZones

export get_historical_data

"""
    get_historical_data(api_key, api_secret, ticker, timeframe, start_time, limit, adjustment="raw")

Retrieve historical stock data from Alpaca Market Data V2 API.

# Arguments
- `api_key::String`: Alpaca API key
- `api_secret::String`: Alpaca API secret
- `ticker::String`: Stock ticker symbol (e.g., "AAPL")
- `timeframe::String`: Candle timeframe (e.g., "1Day", "1Hour", "1Min")
- `start_time::String`: Start time in ISO 8601 format (e.g., "2023-01-01T00:00:00Z")
- `limit::Int`: Maximum number of candles to retrieve (automatically handles pagination)
- `adjustment::String`: Adjustment type for corporate actions (default: "raw")
  - "raw": No adjustment (raw prices)
  - "split": Adjust for stock splits only
  - "dividend": Adjust for dividends only
  - "all": Adjust for both splits and dividends

# Returns
- `DataFrame`: DataFrame containing historical data ordered from oldest to newest

# Examples
```julia
# Get 100 daily candles (automatically handles pagination if needed)
get_historical_data("your_api_key", "your_api_secret", "AAPL", "1Day", "2023-01-01T00:00:00Z", 100)

# Get 1000 hourly candles (will make multiple API calls if needed)
get_historical_data("your_api_key", "your_api_secret", "AAPL", "1Hour", "2023-01-01T00:00:00Z", 1000)

# Get split-adjusted daily data
get_historical_data("your_api_key", "your_api_secret", "AAPL", "1Day", "2023-01-01T00:00:00Z", 100, adjustment="split")

# Get fully adjusted data (splits + dividends)
get_historical_data("your_api_key", "your_api_secret", "AAPL", "1Day", "2023-01-01T00:00:00Z", 100, adjustment="all")
```

# Notes
- The function automatically handles pagination using `page_token` when the requested limit exceeds what the API returns in a single call
- Maximum limit per API request is 1000 candles
- For large datasets, multiple API requests will be made transparently

# Rate Limit Considerations
- Alpaca API has a rate limit of 200 requests per minute per API key
- This function includes adaptive rate limiting based on request size:
  - Small requests (<5000 candles): 200ms delays, up to 100 requests
  - Medium requests (5000-10000 candles): 300-500ms delays, up to 200 requests
  - Large requests (10000-20000 candles): 500ms-1s delays, up to 150 requests
  - Very large requests (>20000 candles): 1s+ delays, up to 100 requests

# Safe Usage Guidelines
- **Up to 10,000 candles**: Safe for frequent use with built-in rate limiting
- **10,000-20,000 candles**: Safe with cautious rate limiting (500ms+ delays)
- **20,000+ candles**: Use with caution - consider alternative approaches:
  - Break into multiple function calls with different time ranges
  - Use larger timeframes (e.g., "1Day" instead of "1Hour")
  - Implement caching to store and reuse data
  - Use Alpaca's unlimited market data plan if available

# Safety Limits
- Adaptive maximum requests based on size (100-200 requests per call)
- Progressive delays that increase with more requests
- Automatic warnings for large requests
- Detailed progress reporting for requests over 5000 candles
"""
function get_historical_data(api_key::String, api_secret::String, ticker::String, 
                             timeframe::String, start_time::String, limit::Int, 
                             adjustment::String = "raw")
    
    # Alpaca Market Data V2 API endpoint
    base_url = "https://data.alpaca.markets/v2"
    endpoint = "/stocks/$(ticker)/bars"
    
    # Set up headers with authentication
    headers = Dict(
        "APCA-API-KEY-ID" => api_key,
        "APCA-API-SECRET-KEY" => api_secret
    )
    
    all_bars = []
    current_limit = min(limit, 1000)  # API max per request
    next_page_token = nothing
    request_count = 0
    
    # Determine rate limiting strategy based on request size
    if limit > 20000
        @warn "Requesting ", limit, " candles exceeds recommended safe limit. Using conservative rate limiting."
        max_requests = 100  # Safety limit
        base_delay = 1.0    # 1 second delay for very large requests
    elseif limit > 10000
        @warn "Requesting ", limit, " candles is a large request. Using cautious rate limiting."
        max_requests = 150  # Slightly higher limit for medium-large requests
        base_delay = 0.5    # 500ms delay for large requests
    elseif limit > 5000
        @info "Requesting ", limit, " candles. Using standard rate limiting."
        max_requests = 200  # Standard safety limit
        base_delay = 0.3    # 300ms delay for medium requests
    else
        # No warning for reasonable requests
        max_requests = 100   # Conservative limit for small requests
        base_delay = 0.2    # 200ms delay for small requests
    end
    
    try
        while length(all_bars) < limit
            request_count += 1
            
            # Rate limiting with adaptive delays
            if request_count > 1
                # Progressive delay: starts with base_delay, increases for many requests
                delay = base_delay * (1 + 0.1 * floor((request_count - 1) / 10))
                sleep(delay)
                @debug "API request ", request_count, ": waiting ", round(delay*1000), "ms"
            end
            
            # Safety check: Don't make too many requests
            if request_count > max_requests
                @warn "Made ", max_requests, " API requests and still haven't reached the limit. Stopping to avoid rate limiting."
                break
            end
            
            # Progress reporting for large requests
            if limit > 5000 && request_count % 20 == 0
                @info "Progress: ", request_count, " requests made, ", length(all_bars), "/", limit, " candles retrieved"
            end
            # Query parameters
            params = Dict(
                "timeframe" => timeframe,
                "start" => start_time,
                "limit" => string(current_limit),
                "adjustment" => adjustment
            )
            
            # Add pagination token if available
            if next_page_token !== nothing
                params["page_token"] = next_page_token
            end
            
            # Build URL with query parameters
            query_string = "?" * join(["$(k)=$(v)" for (k, v) in params], "&")
            url = base_url * endpoint * query_string
            
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
                break  # No more data available
            end
            
            # Extract bars data
            bars = data["bars"]
            append!(all_bars, bars)
            
            # Check if we have enough data
            if length(all_bars) >= limit
                all_bars = all_bars[1:limit]  # Trim to requested limit
                break
            end
            
            # Check for pagination token
            if haskey(data, "next_page_token") && data["next_page_token"] !== nothing
                next_page_token = data["next_page_token"]
            else
                break  # No more pages available
            end
            
            # Reduce limit for next request to get remaining data
            current_limit = min(limit - length(all_bars), 1000)
        end
        
        if isempty(all_bars)
            return DataFrame()
        end
        
        # Convert to DataFrame
        df = DataFrame(
            timestamp = ZonedDateTime[ZonedDateTime(DateTime(bar["t"], dateformat"yyyy-mm-dd\THH:MM:SS\Z"), tz"UTC") for bar in all_bars],
            open = Float64[bar["o"] for bar in all_bars],
            high = Float64[bar["h"] for bar in all_bars],
            low = Float64[bar["l"] for bar in all_bars],
            close = Float64[bar["c"] for bar in all_bars],
            volume = Float64[bar["v"] for bar in all_bars]
        )
        
        # Sort by timestamp (oldest to newest)
        sort!(df, :timestamp)
        
        return df
        
    catch e
        if isa(e, ArgumentError) && occursin("DateTime", string(e))
            error("Error parsing timestamp from API response. Expected ISO 8601 format (e.g., '2023-01-01T00:00:00Z'). Received: ", 
                  string(e))
        else
            error("Error fetching historical data: ", e)
        end
    end
end

end # module AlpacaConnector