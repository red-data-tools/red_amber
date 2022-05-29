##  - Unreleased

- Feedback something to Red Arrow

- `DataFrame`
  - Introduce `group_by`
  - Introduce `summarize`
  - Introduce `summary` or ``describe`
  - Improve dataframe obs. manipuration methods to accept float as a index (#10)
  - More performant

- `Vector`
  - Support more functions

- Document
  - YARD support

## [0.1.4] - 2022-05-29 (experimental)

- Bug fixes
  - Fix missing support for scalar argument (#1)
  - Fix type name of boolean in DF#types to be same as Vector#type (#6, #7)
  - Fix zero picking to return empty DataFrame (#8)
  - Fix code at both args and a block given (#8)

- New features and improvements
  - `DataFrame`
    - Refine module name `Displayable`
    - Rename nrow/ncol methods to `size`/`n_keys` to align with TDR concept (#4)
      - Remain `n_row`/`n_col` for compatibility
    - Rename `ls` method to `tdr` (#4)
      - Add limit option to `tdr`
      - Shorten option name (#11)
    - Introduce `pick` method to create sub DataFrame (#8)
      - Add boolean support (#8)
      - Refactor `pick` (#9)
    - Introduce `drop` method to create sub DataFrame (#8)
      - Add boolean support (#8)
      - Refactor `drop` (#9)
    - Add boolean array support for `[]` (#9)
    - Add `indexes`/`indices` to use with selecting observations (#9)
    - Introduce `slice` method to create sub DataFrame (#8)
      - Refactor `slice` (#9)
    - Introduce `remove` method to create sub DataFrame (#9)
    - Introduce `rename` method to create sub DataFrame (#14)
    - Introduce `assign` method to create sub DataFrame (#14)
    - Improve to call block by instance_eval (#13)

  - `Vector`
    - Refine `find(function)`
    - Add `min_max` method (#2)
    - Add `std`/`sd` method (ddof=0 version: `stddev`) (#2)
    - Add `var` method (ddof=0 version: `variance`) (#2)
    - Add `VectorFunctions.arrow_doc(func_name)` (temporally)

  - Documentation
    - Show code in README
    - Change row/column names for **TDR** concept (#4)
    - Add documents about **TDR** concept (#4)
    - Add example about TDR (#4)
    - Separate README to create DataFrame and Vector documents (#12)
    - Add DataFrame model concept image to README (#12)
  
  - GitHub site
    - Switched to use merge on GitHub (not to push merged master) (#1)
    - Create lifetime issue #3 to show the goal of this project (#3)

## [0.1.3] - 2022-05-15 (experimental)

- Bug fixes
  - Fix boolean functions in `Vector` to align with Ruby's behavior
    - `&` == `and_kleene`
    - `|` == `or_kleene`
  - Quote strings of data-preview in `DataFrame#inspect`
  - Quote empty and blank keys in `DataFrame#inspect`
  - Respond to error for a wrong key in `DataFrame#[]`

- New features and improvements
  - `DataFrame`
    - Display nil elements in `inspect`
    - Show NaN and nil counts in `inspect`
    - Refactor `inspect`
    - Add method `key` and `key_index`
    - Add how to load/save Parquet to README

  - `Vector`
    - Add categorization functions
      
      This is an important step to support `slice` method and NA treatment features.
      -  `is_finite`
      -  `is_inf`
      -  `is_na` (RedAmber original)
      -  `is_nan`
      -  `is_nil`, `is_null`
      -  `is_valid`
    - Show in a reduced representation for long array in `inspect`
    - Support options in aggregatiton functions
    - Return values in non-arrow object for scalar aggregation functions

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
