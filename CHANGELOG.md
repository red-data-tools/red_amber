## [0.2.2] - 2022-10-04

- Bug fixes

  - Return self when no replacement happen in Vector#replace. (#92)

  - Limit n-digits in to_iruby. (#111)

  - Fix displaying space in to_iruby. (#111)

  - Raise error if key is duplicated. (#113)

  - Fix DataFrame#pick/#drop with endless Range. (#113)

  - Change type from dictionary to string in DataFrame reshaping methods. (#113)

  - Fix arguments parser to accept Enumerator. (#114)

- New features and improvements

  - Support to make a data frame from a to_arrow-responsible object. (#106) [Patch by Kenta Murata]

  - Introduce DataFrame#auto_cast (experimental feature) (#105)

  - Change default name in DataFrame#transpose, #to_long, #to_wide. (#110)

  - Add Vector#dictionary? method. (#113)

  - Add display mode 'Plain' and 'Minimum'. (#113)

  - Refactor code

    - Refine test_vector_selectable. (#92)
    - Refine test_vector_updatable. (#92)
    - Refine Vector.new. (#113)
    - Refine DataFrame#pick, #drop. (#113)

  - Documents

    - Update images. (#90, #105, #113)

    - Update README to use simpler examples. (#112)
      - Update README with a new screenshot example. (#113)

  - GitHub site

    - Update Jupyter notebooks in Binder (#88, #115)
      - Move binder support to heronshoes/docker-stacks repository.
      - Update README notebook on binder.
      - Add examples_of_RedAmber notebook on binder.
    
    - Start to use discussions.

- Thanks
  
  - Kenta Murata

## [0.2.1] - 2022-09-07

- Bug fixes

  - Fix `Vector#each` with block (#66)
    `Vector#each` will return value of each element with block.

  - Fix table format at size == 9 (#67)

  - Fix to support Vector in `DataFrame#assign` (#77)

  - Add `assert_delta` functionality for `assert_with_NaN` (#78)

  - Fix Vector#is_in when self is chunked (#79)

  - Fix Array type error (uint/int) (#79)

- New features and improvements

  - Refine `DataFrame#indices` method (#67)

  - Update DataFrame reshaping methods (#73)

    - Change default option value of DataFrame reshaping

    - Change the order of import_cars example

  - Add `DataFrame#method_missing` to get column vector by method (#75)

    - Add `DataFrame#method_missing` to get column (#75)

  - Accept both args and block in `DataFrame#assign` (#75)

  - Accept indices in `DataFrame#pick` and `DataFrame#drop` (#76)

  - Add `DataFrame#slice_by` method (#77)
  
  - Add new Vector functions (#78)

    - Add inverse trigonometric function for Vector
      - `acos`
      - `asin`

    - Add logarithmic function for Vector
      - `ln`
      - `log10`
      - `log1p`
      - `log2`

    - Add binary function `Vector#logb`

  - Docker image and Jupyter Notebook [Thanks to Kenta Murata]
    - Add link to RubyData in README
    - Add link to interactive README by Binder

  - Update Jupyter Notebook `71 examples of RedAmber`

- Thanks
  
  - Kenta Murata

## [0.2.0] - 2022-08-15

- Bump version up to 0.2.0

- Bug fixes

  - Fix order of multiple group keys (#55)
  
    Only 1 group key comes to left. Other keys remain in right.

  - Remove optional `require` for rover (#55)

    Fix DataFrame.new for argument with Rover::DataFrame.

  - Fix occasional failure in CI (#59)

    Sometimes the CI test fails. I added -dev dependency 
    in Arrow install by apt, not doing in bundler.

  - Fix calling :take in V#[] (#56)

    Fixed to call Arrow function :take instead of :array_take in Vector#take_by_vector. This will prevent the error below
    when called with Arrow::ChunkedArray.

  - Raise error renaming non existing key (#61)

    Add error when specified key is not exist.

  - Fix DataFrame#rename #assign by array (#65)

- New features and improvements

  - Support Arrow 9.0.0
    - Upgrade to Arrow 9.0.0 (#59)
    - Add Vector#quantile method (#59)
      Arrow::QuantileOptions has supported in Arrow GLib 9.0.0 (ARROW-16623, Thanks!)
  
    - Add Vector#quantiles (#62)

    - Add DataFrame#each_row (#56)
      - Returns Enumerator if block is not given.
      - Change DataFrame#each_row to return a Hash {key => row} (#63)

  - Refactor to use pattern match in overloaded parameter parsing (#61)
    - Refine DataFrame.new to use pattern match
    - Use pattern match in DataFrame#assign
    - Use pattern match in DataFrame#rename
  
  - Accept Array for renamer/assigner in #rename/#assign (#61)
    - Accept assigner by Arrays in DataFrame#assign
    - Accept renamer pairs by Arrays in DataFrame#rename
    - Add DataFrame#assign_left method

  - Add summary/describe (#62)
    - Introduce DataFrame#summary(#describe)

  - Introduce reshaping methods for DataFrame (#64)
    - Introduce DataFrame#transpose method
    - Intorduce DataFrame#to_long method
    - Intorduce DataFrame#to_wide method

  - Others
 
    - Add alias sort_index for array_sort_indices (#59)
    - Enable :width option in DataFrame#to_s (#62)
    - Add options to DataFrame#format_table (#62)

  - Update Documents
  
    - Add Yard doc for some methods
  
    - Update Jupyter notebook '61 Examples of Red Amber' (#65)

## [0.1.8] - 2022-08-04 (experimental)

- Bug fixes

  - Fix unnamed column in table formatter (#52)
  - Fix DataFrame#key?, DataFrame#key_index when @keys.nil? (#52)
  - Align order of replacer in Vector#replace (#53, resolved #38)

- New features and improvements

  - Refine DataFrame.new for empty arguments (#50)
    - Delete .rubocop_todo.yml for not to use yoda condition (#50)

  - Refine Group (#52, resolved #28)
    - Refine Group methods creation
    - Make group key at first(left)
    - Show only one group count when same counts
    - Add block acceptability for group
    - Rename empty key to :unnamed in DataFrame.new
    - Rename Group#aggregated_by to #summarize (#54)

  - Add Vector#shift (#51)

  - Vector#[] accepts Range as an argument (#51)

- Update documents

  - Add support for yard (#54)

  - Renew jupyter notebook '53 examples' (#54)

  - Add more examples and images in README (#52)
  - Add document of group manipulations in README (#52)
  - Renew DF#group document in DataFrame.md (#52)

## [0.1.7] - 2022-07-15 (experimental)

- Bug fixes

  - Remove development dependency for red-dataset-arrow (#47)
    - To avoid irregular fails in CI test
    - Add red-datasets to development dependency instead (#49)

  - Supress useless log in tests (#46)
    Suppress log of Webrick and iruby.

- New features and improvements

  - Use Table mode as default preview mode in `inspect`/`to_s` (#40)
    - Show examples in documents in Table
    - Use the word rows/columns
    - Update images of data processing in Table style

  - Introduce a new Table formatter (#47)
    - Migrate from the Arrow's formatter
      - Do not use TAB, format by spaces only.
      - Align column width with head rows and tail rows.
      - Show nils.
      - Show data types.
    - Refine documents to use new formatter output
  
  - Simplify options of Vector functions (#46)
    Vector functions with options use optional argument opt in previous code.

  - Add `#float?`, `#integer?` to Vector (#46)
  - Add `#each` to Vector (#47)

  - Introduce class `Group` (#48)
    - Refine `DataFrame#group` to use class Group
    - Add methods to Group

  - Move parquet and rover to development dependency (#49)
  
  - Refine text in `DataFrame#to_iruby` (#40)

  - Add badges in Github site
    - Gitter badge for Red Data Tools (#42)
    - Gem version and CI status badge (#45)

  - Exchange containers in red-amber.rb and red_amber.rb (#47)
    - Mainly use red_amber by consistency with the folder name

  - Add Jupyter notebook '47 Examples of Red Amber' (#49)

## [0.1.6] - 2022-06-26 (experimental)

- Bug fixes
  - Fix mime-type of empty DataFrame in `#to_iruby` (#31)
  - Fix mime setting in `DataFrame#to_iruby` (#36)
  - Fix unmatched return val in Selectable (#34)
  - Fix to return same error as `#[]` in `DataFrame#slice` (#34)

- New features and improvements
  - Introduce Jupyter support (#29, #30, #31, #32)
    - Add `DataFrame#to_html (changed to use #to_iruby)
    - Add feature to show nil in to_iruby
      - nil is expressed as (nil)
      - empty string('') is ""
      - blank spaces are " "

  - Enable to change DataFrame display mode by ENV (#36)
    - Support ENV['RED_AMBER_OUTPUT_STYLE'] to change display mode in `#inspect` and `#to_iruby`
      - ENV['RED_AMBER_OUTPUT_STYLE'] = 'table' # => Table mode
      - ENV['RED_AMBER_OUTPUT_STYLE'] = nil or other than 'table' # => TDR mode

  - Support `require 'red-amber'`, as well (#34)

  - Refine Vector slicing methods (#31)
    - Introduce `Vector#take` method
    - Introduce `Vector#filter` method
    - Improve `Vector#[]` to overload take and filter
    - Introduce `Vector#drop_nil` method
    - Introduce `Vector#if_else` method
    - Intorduce `Vector#is_in` method
    - Add alias `Vector#all?`, `#any?` methods (#32)
    - Add `Vector#has_nil?` method(#32)
    - Add `Vector#empty?` method
    - Add `Vector#primitive_invert` method
    - Refactor `Vector#take`, `#filter`
    - Move `Vector#if_else` from function to Updatable
    - Move if_else test to updatable
    - Rename updatable in test
    - Remove method `Vector#take_out_element_wise`
    - Rename inner metthod name

  - Refine DataFrame slicing methods (#31)
    - Introduce `DataFrame#take method
      - #take is implemented as vector calculation by #if_else
    - Introduce `DataFrame#fliter method
    - Change `DataFrame#[] to use take and filter
      - Float indices is acceptable (#10)
      - Negative index (like Array) is also acceptable

  - Further refinement in DataFrame slicing methods (#34)
   -  Improve `DataFrame#[]`, `#slice`, `#remove` by a new engine
      -  It parses arguments to Vector internally.
      -  Used Kernel#Array to simplify code (#16) .
    - recycle: Move `DataFrame#slice`, `#remove` to Selectable
    - Refine `DataFrame#take`, `#filter` (undocumented)

  - Introduce coerce in Vector (#35)
    - Introduce `Vector#coerce`
      - Now we can `-1 * Vector.new([1, 2, 3])`
    - Add `Vector#to_ary` method
      - Now we can `[1, 2] + Vector.new([3, 4, 5])`

  - Other new feature or refinements
    - Common
      - Refactor helper as common for DataFrame and Vector (#35)
      - Change name row/col to obs/var (#34)
      - Rename internal function name (#34)
      - Delete unused methods (#34)
    - DataFrame
      - Change to return instance variable in `#to_arrow`, `#keys` and `#key_index` (#34)
      - Change to return an Array in `DataFrame#indices` (#35)
    - Vector
      - Introduce `Vector#replace` method
      - Accept Range and expanded Array in `Vector#new`
      - Add `Vector#indices` method (#35)
      - Add `Vector#index` method (#35)
      - Rename VectorCompensable to *Updatable (#33)

  - Documentation
    - Fix typo in DataFrame.md

  - Github site
    - Add gem and status badges in README. (#42) [Patch by kojix2]

- Thanks
  
  - kojix2

## [0.1.5] - 2022-06-12 (experimental)

- Bug fixes
  - Fix DataFrame#tdr to display timestamp type (#19)
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
    - Refine DataFrame#type_classes, Vector#ectortype_class
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
  - Fix type name of boolean in DataFrame#types to be same as Vector#type (#6, #7)
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
