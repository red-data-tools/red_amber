## [0.1.3] - Unreleased

- `DataFrame`
  - Introduce updating capabilities
  - Introduce NA support
  - Add slice method
- `Vector`
  - Add NaN support for functions
  - More functions

## [0.1.2] - 2022-05-08 (experimental)

- Bug fixes:
  - `DataFrame`
    - Fix bug in `#[]` with end-less Range
- New features and improvements
  - Add support for Arrow 8.0.0
  - `DataFrame`
    - `types` and `data_types`
    - Range is usable to specify columns in `#[]`
  - `Vector`
    - `type` and `data_type`

## [0.1.1] - 2022-05-06 (experimental)

- Release on rubygems.org
- Introduce class `DataFrame`
  -  New from Hash, schema/rows, `Arrow::Table`, `Rover::DataFrame`
  -  Load from file, string, URI
  -  Save to file, string, URI
  -  Methods for basic properties
  -  Rich inspect method
  -  Basic selecting by `#[]`
- Introduce class `Vector`
  -  New from a column in a `DataFlame`
  -  New from `Arrow::Array`, `Arrow::ChunkedArray`, `Array`
  -  Methods for basic properties
  -  Function support
     -  Unary aggregations
     -  Unary element-wises
     -  Binary element-wises
     -  Some operators defined

## [0.1.0] - 2022-04-15 (unreleased)

- Initial version
