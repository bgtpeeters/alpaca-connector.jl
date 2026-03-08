module AlpacaConnector

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
- `limit::Int`: Maximum number of candles to retrieve (automatically handles pagination)

# Returns
- `DataFrame`: DataFrame containing historical data ordered from oldest to newest

# Examples
```julia
# Get 100 daily candles (automatically handles pagination if needed)
get_historical_data("your_api_key", "your_api_secret", "AAPL", "1Day", "2023-01-01T00:00:00Z", 100)

# Get 1000 hourly candles (will make multiple API calls if needed)
get_historical_data("your_api_key", "your_api_secret", "AAPL", "1Hour", "2023-01-01T00:00:00Z", 1000)
```

# Notes
- The function automatically handles pagination using `page_token` when the requested limit exceeds what the API returns in a single call
- Maximum limit per API request is 1000 candles
- For large datasets, multiple API requests will be made transparently

# Rate Limit Considerations
- Alpaca API has a rate limit of 200 requests per minute per API key
- This function includes automatic rate limiting with 300ms delays between requests
- For very large datasets (>20,000 candles), consider:
  - Using larger timeframes (e.g., "1Day" instead of "1Hour")
  - Breaking requests into smaller time ranges
  - Using Alpaca's unlimited market data plan if available
  - Implementing caching to avoid repeated requests for the same data

# Safety Limits
- Maximum of 100 API requests per function call to prevent excessive usage
- Warnings are issued when approaching rate limit thresholds
"""
function get_historical_data(api_key::String, api_secret::String, ticker::String, 
                             timeframe::String, start_time::String, limit::Int)
    
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
    
    # Warn about large requests that might hit rate limits
    if limit > 5000
        @warn "Requesting ", limit, " candles may require many API calls. Consider using a larger timeframe or breaking into smaller requests."
    end
    
    try
        while length(all_bars) < limit
            request_count += 1
            
            # Rate limiting: Alpaca API has 200 requests per minute limit
            # Add small delay between requests to avoid hitting rate limits
            if request_count > 1
                sleep(0.3)  # 300ms delay between requests (allows ~200 requests/minute)
            end
            
            # Safety check: Don't make too many requests
            if request_count > 100
                @warn "Made 100 API requests and still haven't reached the limit. Stopping to avoid rate limiting."
                break
            end
            
            # Additional warning when approaching rate limits
            if request_count % 50 == 0
                @warn "Made ", request_count, " API requests so far. Consider optimizing your request."
            end
            # Query parameters
            params = Dict(
                "timeframe" => timeframe,
                "start" => start_time,
                "limit" => string(current_limit)
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
            timestamp = [DateTime(bar["t"], dateformat"yyyy-mm-dd\THH:MM:SS\Z") for bar in all_bars],
            open = [bar["o"] for bar in all_bars],
            high = [bar["h"] for bar in all_bars],
            low = [bar["l"] for bar in all_bars],
            close = [bar["c"] for bar in all_bars],
            volume = [bar["v"] for bar in all_bars]
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