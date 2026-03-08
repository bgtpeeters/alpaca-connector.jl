# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `adjustment` parameter for corporate action adjustments (splits/dividends)
- Timezone-aware timestamps using `ZonedDateTime`

### Changed
- DataFrame numeric columns from `Real` to `Float64` for better type stability and performance
- Enhanced rate limiting with adaptive delays for safe large requests

## [0.1.0] - 2023-01-01

### Added
- First public release
- Core package structure
- Documentation and examples