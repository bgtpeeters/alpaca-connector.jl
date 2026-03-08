# AlpacaConnector.jl

[![CI](https://github.com/bgtpeeters/AlpacaConnector.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/bgtpeeters/AlpacaConnector.jl/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A Julia wrapper around the Alpaca Market Data V2 API and Alpaca Trading API.

## Features

- Retrieve historical stock data
- Returns data as Julia DataFrames with type-stable `Float64` columns
- Timezone-aware timestamps using `ZonedDateTime`
- Built-in corporate action adjustments (splits/dividends)
- Easy to use interface

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/bgtpeeters/AlpacaConnector.jl")
```

## Usage

```julia
using AlpacaConnector

# Get historical data for AAPL
api_key = "your_api_key"
api_secret = "your_api_secret"
data = get_historical_data(api_key, api_secret, "AAPL", "1Day", "2023-01-01T00:00:00Z", 100)

# Get split-adjusted data
data_adjusted = get_historical_data(api_key, api_secret, "AAPL", "1Day", "2023-01-01T00:00:00Z", 100, adjustment="split")

# Display the data
println(data)
```

## API Reference

### `get_historical_data`

```julia
get_historical_data(api_key, api_secret, ticker, timeframe, start_time, limit, adjustment="raw")
```

**Arguments:**
- `api_key::String`: Your Alpaca API key
- `api_secret::String`: Your Alpaca API secret
- `ticker::String`: Stock ticker symbol (e.g., "AAPL")
- `timeframe::String`: Candle timeframe (e.g., "1Day", "1Hour", "1Min")
- `start_time::String`: Start time in ISO 8601 format
- `limit::Int`: Maximum number of candles to retrieve
- `adjustment::String`: Adjustment type for corporate actions (default: "raw")
  - "raw": No adjustment (raw prices)
  - "split": Adjust for stock splits only
  - "dividend": Adjust for dividends only
  - "all": Adjust for both splits and dividends

**Returns:**
- `DataFrame`: Historical data ordered from oldest to newest
  - `timestamp`: `ZonedDateTime` with UTC timezone
  - `open`, `high`, `low`, `close`: `Float64` prices
  - `volume`: `Float64` trading volume

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