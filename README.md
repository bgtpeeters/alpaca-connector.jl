# Alpaca Connector

[![CI](https://github.com/yourusername/alpaca-connector.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/yourusername/alpaca-connector.jl/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A Julia wrapper around the Alpaca Market Data V2 API and Alpaca Trading API.

## Features

- Retrieve historical stock data
- Returns data as Julia DataFrames
- Easy to use interface

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/yourusername/alpaca-connector.jl")
```

## Usage

```julia
using alpaca_connector

# Get historical data for AAPL
api_key = "your_api_key"
api_secret = "your_api_secret"
data = get_historical_data(api_key, api_secret, "AAPL", "1Day", "2023-01-01T00:00:00Z", 100)

# Display the data
println(data)
```

## API Reference

### `get_historical_data`

```julia
get_historical_data(api_key, api_secret, ticker, timeframe, start_time, limit)
```

**Arguments:**
- `api_key::String`: Your Alpaca API key
- `api_secret::String`: Your Alpaca API secret
- `ticker::String`: Stock ticker symbol (e.g., "AAPL")
- `timeframe::String`: Candle timeframe (e.g., "1Day", "1Hour", "1Min")
- `start_time::String`: Start time in ISO 8601 format
- `limit::Int`: Maximum number of candles to retrieve

**Returns:**
- `DataFrame`: Historical data ordered from oldest to newest

## Contributing

While direct code contributions are not accepted, suggestions for improvements and bug reports are welcome! Please use the GitHub issue tracker to:

- Report bugs
- Suggest features
- Provide feedback

See [CHANGELOG.md](CHANGELOG.md) for a history of changes and [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

## License

MIT — see [LICENSE](LICENSE).

## Contact

For questions or support, please open an issue on GitHub.