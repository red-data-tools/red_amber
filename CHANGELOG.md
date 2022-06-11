## [0.2.0] - unreleased

- Document
  - YARD support

- DataFrame#join features

## [0.1.6] - Unreleased

- Feedback something to Red Data Tools

- `DataFrame`
  - Introduce `summary` or ``describe`
  - Add `Quantile` by own code?
  - Improve dataframe obs. manipuration methods to accept float as a index (#10)
  - Improve as more performant by benchmark check.

- `Vector`
  - Support more functions
  - Support coerece

- More examples of frequently needed tasks

## [0.1.5] - 2022-06-12 (experimental)

- Bug fixes
  - Fix DF#tdr to display timestamp type (#19)
  - Add TZ setting in CI test to pass temporal tests (#19)
  - Fix example in document of #load(csv_from_URI) (#23)

- New features and improvements
  - Improve usability of DataFrame manipulating block (#19)
    - Add `DataFrame#v` to select a Vector
    - Add `DataFrame#variables` method
    - Add `DataFrame#to_arrow`
    - Add instance variables in DataFrame with lazy initialization
    - Add `Vector#key` to get key name
    - Add `Vector#temporal?` to check if temporal type
    - Refine around DataFrame#variables
    - Refine init of instance variables
    - Refine DataFrame#type_classes, V#ectortype_class
    - Refine DataFrame#tdr to shorten temporal data

  - Add supports to make up for missing values (#20)
    - Add VectorArgumentError
    - Add `Vector#replace_with`
    - Add helper function to assert with NaN
      - To assert NaN == NaN
    - Add `Vector#fill_nil_backward`, `Vector#forward`
    - Add `DataFrame#remove_nil` method
    - Change to accept nil as replacement in Vector#replace_with

  - Introduce index related methods (#22)
    - Add `Vector#sort_indexes` method
    - Add `Vector#uniq` method
    - Add `Vector#tally` and `Vectorvalue_counts` methods
    - Add `DataFrame#sort` method
    - Add `DataFrame#group` method
    - Change to use DataFrame#map_indices in #[]

  - Add rounding functions with opts (#21)
    -  With options :mode and :n_digits 
    -  :n_digits also can be specified with :multiple option in `Vector#round_to_multiple`
    - `Vector#round`
    - `Vector#ceil`
    - `Vector#floor`
    - `Vector#trunc`

  - Documentation
    - Update TDR, TDR_ja documents to latest (#18)
    - Refinement and small fix in DataFrame.md (#18)
    - Update README to use more effective example (#18)
    - Delete expired TDR_operations.pdf (#23)
    - Update README and dataframe_model image (#23)
    - Update description about rover-df in README (#23)
    - Add installation of Arrow in README (#23)

  - Others
    - Tried but cannot use bundler cache in ci test (#17)
    - Bump up requirements to Arrow 8.0.0 (#25)
      - Arrow 7.0.0 with Ubuntu 21.04 causes an fatal error in replace_with_mask function.
    - Update the description of gem (#23)
    - Add benchmark tests (#26)

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
