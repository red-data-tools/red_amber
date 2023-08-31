## [0.5.2] - 2023-09-01

Support Apache Arrow 13.0.0 .
This version is compatible with Arrow 12.0.0 .

- Breaking change

- Bug fixes
  - Fix bundle install issue by install libyaml-devel (#280)
  - Fix ownership in devcontainer ci (#280)

- New features and improvements
  - Support Arrow 13.0.0 (#280)

- Documentation and Example
  - Add dataframe_comparison_ja (#281)

## [0.5.1] - 2023-08-18

Docker environment is replaced by Dev Container,
and Jupyter Notebooks will be created from qmd files.

- Breaking change

- Bug fixes
  - Fix timestamp test to set TZ locally (#249)
  - Fix regexp for beginning of String (#251)
  - Fix loading bin/Gemfile locally in bin/jupyter script (#261)

- New features and improvements
  - Support sort and null_placement options in Vector#rank (#265)
  - Add Vector#find_substring method (#270)
  - Add Group#one method (#274)
  - Add Group#all and #any method (#274)
  - Add Group#median method (#274)
  - Add Group#count_uniq method (#274)
  - Introduce Dev Container environment
    - Introduce Devcontainer environment (#253)
    - Change lifecycle script from postCreate to onCreate (#253)
    - Move example to bin (#253)
    - Fix Python and Ruby versions in Dev Container (#254)
    - Add locale and timezone settings (#256)
    - Add quarto from devcontainer feature (#259)
    - Install HaranoAjiFonts as default Tex font (#259)

- Refactoring
  - Rename boolean methods in VectorStringFunction (#263)
  - Refine Vector#inspect to show wheather chunked or not (#267)
  - Add an alias Group#count_all for #group_count (#274)

- Improve in tests/CI
  - Create rake commands for Notebook convert/test (#269)
  - Fix rubocop warning of forwarding arguments in assign_update (#269)
  - Use rake to start example script (#269)
  - Add test in Vector#rank to cover illegal rank option error (#271)
  - Add bundle install to Rakefile (#276)
  - Use Dockerfile to create dev container (#276)
  - Save image to ghcr in ci (#276)

- Documentation and Example
  - YARD
    - Update Docker Environment (#245)
    - Refine jupyter notebook environment (#253)
    - Refine yard in Group aggregations (#274)
    - Fix yard of Vector#rank (#269)
    - Fix yard of Group (#269)
  - Notebook
    - Start source management for jupyter notebook by qmd (#259)
    - Don't create ipynb if it exists (#261)
    - Add Group methods (125 in total) (#269)
    - Add ArrowFunction (126 in total) (#269)
    - Add DataFrame#auto_cast (127 in total) (#269)
    - Update required version in examples notebook (#269)
    - Update examples_of_red_amber (#269)
    - Update red-amber.qmd (#269)

- GitHub site
  - Fix broken link in README/README.ja by Viktorius Suwandi (#262)
  - Change description in gemspec (#254)
  - Add documents for Dev Container (#254)

- Thanks
  - Viktorius Suwandi

## [0.5.0] - 2023-05-24

- Breaking change
  - Use non keyword argument in #sub_by_value (#219)
  - Upgrade dependency to Arrow 12.0.0 (#238)
    - right_join will output columns as same order as Red Arrow.
    - DataFrame#join will not force ordering of original column by default
    - Join with type, such as full_join, sort after join by default

- Bug fixes
  - Use truncate in Vector#sample(float) (#229)
  - Support options in DataFrame#tdra (#231)
  - Fix printing table with non-ascii strings (#233)
  - Fix join for Arrow 12.0.0

- New features and improvements
  - Add a singleton method Vector.[] (#218)
  - Add an alias #sub_group (#219)
  - Accept Group#summarize{Hash} to rename aggregated columns (#219)
  - Add Group#group_frame (#219)
  - Add Vector#cast (#224)
  - Add Vector#fill_nil(value) (#226)
  - Add Vector#one (#227)
  - Add Vector#mode (#228)
  - Add DataFrame#propagate (#235)
  - Add DataFrame#sample (#237)
  - Add DataFrame#shuffle (#237)
  - Support RankOptions in Vector#rank (#239)
  - Introduce MatchSubstringOptions family in Vector (#241)
    - Introduce Vector#match_substring?
    - Add Vector#end_with?, #start_with? method
    - Add Vector#match_like?
    - Add Vector#count_substring method

- Refactoring
  - Refine Group and SubFrames function (#219)
    - Refine Group#group_count
    - Use Acero in Group#filters
    - Refine Group#filters, not using Acero
    - Refine Group#summarize(array)
  - Use Acero for renaming columns in join (#238)
  - Use index kernel with IndexOptions introduced in 12.0.0 (#240)

- Improve in tests/CI
  - Use Fedra 39 Rawhide in CI (#238)

- Documentation and Example
  - Add missing yard documents for SubFrames::Selectors (#219)
  - Update docker/example (#219)
  - Update Gemfile in docker (#219)
  - Add README.ja.md (#242)

- GitHub site
  - Update link of Red Data Tools Chat to matrix (#242)

- Thanks

## [0.4.2] - 2023-04-02

- Breaking change

- Bug fixes
 - Fix Vector#modulo, #fdiv, #remainder (#203)

- New features and improvements
  - Update SubFrames#take to return SubFrames (#212)

- Refactoring
  - Refine SubFrames to support partial retrieval (#207)
  - Upgrade SubFrames#frames  and promote to public (#207)
  - Use faster count in Group#inspect (#207)

- Improve in tests/CI

- Documentation and Example
  - Introduce minimum docker environment (#205)
  - Move example REPL to docker (#205)
  - Add readme.md in docker (#205)
  - Add example_of_red_amber.ipynb (#205)
  - Use smaller dataset in irb example
  - Fix docker/example
  - Updated link to red-data-tools (#213)
    - Thanks to Soumya Kushwaha

- GitHub site
  - Migrated to [Red Data Tools](https://github.com/red-data-tools)
    - Thanks to Sutou Kouhei

- Thanks
  - Sutou Kouhei
  - Soumya Kushwaha

## [0.4.1] - 2023-03-11

- Breaking change
  - Remove Vector.aggregate? method (#200)

- Bug fixes
  - Return self in DataFrame#drop when dropper is empty (reverts 746ac263) (#193)
  - Return self in DataFrame#rename when renaming to same name (#193)
  - Return self in DataFrame#pick when pick itself (#199)
  - Fix column width for non-ascii elemnts in DataFrame#to_s (#193)
    - This change uses String#width.
  - Fix DataFrame#to_iruby when data is date32 type (#193)
  - Fix DataFrame#shorthand to show temporal type data simply (#193)
  - Fix Vector#rank when data is ChunkedArray (#198)
  - Fix Vector element-wise functions with nil as scalar (#198)
  - Support :force_order for all methods of join family (#199)
    - Supports :force_order option to force sorting after join for all #join familiy.
    - This will valuable in some cases such as large dataframes.
  - Ensure baseframe's schema for SubFrames (#200)

- New features and improvements
  - Add Vector#first, #last method (#198)
    - This method will be used in SubFrames feature.
  - Add Vector#modulo method (#198)
    - The divmod function in Arrow C++ is still in draft state.
      This method was created by combining existing functions
  - Add Vector#quotient method (#198)
  - Add aliases #div, #mod, #mul, #pow, #quo and #sub for Vector (#198)
  - Add Vector#*_checked functions (#198)
    - This functions will check numeric range overflow.
  - Add 'tdra' and 'plain' in display mode (#193)
    - The plain mode and default inspect will show up to 128 rows and 128 columns.
  - Add String#width method in refinements (#193)
    - This will be used to update DataFrame#to_s.
  - Introduce pre-loaded REPL environment (#199)
    - This commit will add bin/example and it will start irb environment
      with enabled commonly used datasets such as penguins, diamonds, etc.
  - Upgrade SubFrames#aggregate to accept block (#200)

- Refactoring
  - Use symbolized keys in refinements of Table#keys, #key? (#193)
    - This can be treat Tables and DataFrames as same manner.
  - Use key_name.succ in suffix of DataFrame#join (#193)
    - This will make simple to get name candidate.
  - Use ||= to memorize instance variables (#193)
  - Refine vector projection to use #variables (#193)
    - #variables is fastest when picking Vectors.
  - Refine Vector#is_in to avoid #pack (#198)
  - Refine Vector#index (#198)

- Improve in tests/CI
  - Tests
    - Update benchmarks to test from older version (#193)
    - Refine test of Vector function with scalar (#198)
    - Refine test subframes and test_vector_selectable (#200)

  - Cops
  - CI

- Documentation
  - Update documents(small fix) (#201)

- GitHub site

- Thanks

## [0.4.0] - 2023-02-25

- Breaking change
  - Upgrade dependency to Arrow 11.0.0 (#188)

- Bug fixes
  - Add :force_order option for DataFrame#join (#174)
  - Return error for empty DataFrame in DataFrame#filter (#172)
  - Accept ChunkedArray in DataFrame#filter (#172)
  - Fix Vector#replace to accept Arrow::Array as a replacer (#179)
  - Fix Vector#round_to_multiple to accept Float or Integer (#180)
  - Change Vector atan2 to a class method (#180)
  - Fix Vector#shift when boolean Vector (#184)
  - Fix processing empty SubFrames (#183)
  - Do not check object id in DataFrame#rename, #drop for self (#188)

- New features and improvements
  - Accept a block in DataFrame#filter (#172)
  - Add Vector.aggregate? method (#175)
  - Introduce Vector#propagate method (#175)
  - Add Vector#rank methods (#176)
  - Add Vector#sample method (#176)
  - Add Vector#sort method (#176)
  - Promote DataFrame#shape_str to public (#184)
  - Introduce Vector#concatenate (#184)
  - Add #numeric? in refinements of Array (#184)
  - Add Vector#cumulative_sum_checked and #cumsum (#184)
  - Add Vector#resolve method (#184)
  - Add DataFrame#tdra method (#184)
  - Add #expand as an alias for Vector#propagate (#184)
  - Add #glimpse as an alias for DataFrame#tdr (#184)
  - New class SubFrames (#183)
    - Introduce class SubFrames
    - Memorize dataframes in SubFrames
    - Add @frames to memorize sub DataFrames
    - Accept filters in SubFrames.new
    - Accept block in SubFrames.new
    - Add SubFrames.by_filter
    - Introduce methods creating SubFrames from DataFrame
    - Introduce SubFrames#each method
    - Add SubFrames#to_s method
    - Add SubFrames#concatenate method
    - Add SubFrames#offset_indices method
    - SubFrames#aggregate method
    - Redefine SubFrames#map to return SubFrames
    - Define SubFrame#map dynamically
    - Add SubFrames#assign method
    - Redefine SubFrames#select to return SubFrames
    - Add SubFrames#reject method
    - Add SubFrames#filter_map method
    - Refine DataFrame#indices memorizing @indices
    - Rename SubFrames#universal_frame as #baseframe
    - Set Group iteration feature to @api private

- Refactoring
  - Generate Vector functions in class method (#177)
  - Set Constant visibility to private (#179)
  - Separate test_vector_function (#179)
  - Relocate methods in DataFrameIndexable (#179)
  - Rename Array refinements to the same name as Vector (#184)

- Improve in tests/CI
  - Tests
    - Update benchmarks to set 0.3.0 as a reference (#167)
    - Move test of Vector#logb to proper location (#180)

  - Cops
    - Update .rubocop.yml to align with latest cops (#174)
    - Unify style of MethodCallIndentation as relative to reciever (#184)

  - CI
    - Fix setting up Arrow by homebrew in CI (#167)
    - Fix CI error on homebrew deleting python link (#167)
    - Set cache-version to get new C extensions in CI (#173)
      - Thanks to @kou for suggestion.

- Documentation
  - Update DataFrame.md about loading csv without headers (#165)
    - Thanks to kojix2
  - Update YARD in DataFrame combinable (#168)
  - Update comment for Ruby 2.7 support in README.md
  - Update license year
  - Update README (#172)
  - Update Vector.md and yardoc in #propagate (#175)
  - Use customized style sheet for YARD (#179)
  - Add examples for the doc of #pick and #drop (#179)
  - Add examples to YARD in DataFrame reshaping methods (#179)
  - Update documents in DataFrameDisplayable (#179)
  - Update documents in DataFrameVariableOperation (#179)
  - Update document for dynamically generated methods (#179)
  - Unify style in document (#179)
  - Update documents in DataFrameSelectable (#179)
  - Update documents of basic Vector methods (#179)
  - Update document in VectorUpdatable (#179)
  - Update document of Group (#179)
  - Update document of DataFrameLoadSave (#180)
  - Add examples for document of ArrowFunction (#180)
  - Update document of Vector_unary_aggregation (#180)
  - Update document of Vector_unary_element_wise (#180)
  - Update document of Vector_biary_element_wise (#180)
  - Add documentation to give comparison of dataframes(#169)
    - Thanks to Benson Muite
  - Update documents for consistency of method indentation (#189)
  - Update CHANGELOG (#189)
  - Update README for 0.4.0 (#189)

- GitHub site

- Thanks
  - kojix2
  - Benson Muite

## [0.3.0] - 2022-12-18

- Breaking change
  - Supported Ruby version has changed from 2.7 to 3.0
    - Upgrade minimum supported/required version of Ruby from 2.7 to 3.0 (#159, #160)

- Bug fixes
  - Add check with #key? in DataFrame#method_missing (#140)
  - Delete unnecessary backslash to supress warning in unary functions (#140)
  - Fix syntax in code_climate.yml (144)
  - Temporary disable simplecov test report (#149)
  - Change Vector#[] to return Array or scalar (#148)
  - Add missing simplecov HTML formatter (#148)
  - Change return value of DataFrame#save to self (#160)
    - Originally reported by kojix2.

- New features and improvements
  - Update Vector#take to accept block (#148)
  - Add properties of list Vectors (#148)
  - Add Vector#split, #split_to_column, #split_to_row (#148)
  - Add Vector#merge (#148)

- Refactoring
  - Refactor code (#140)
    - Add DataFrame.create as a faster constructor
    - Refactor DataFrame.new using refinements and duck typing
    - Refactor Vector.new using refinements and duck typing
    - Add Vector.create as a faster constructor
    - Refactor Group
    - Refactor DataFrame#pick/#drop by refininig Array
    - Refactor DataFrame#pick/#drop
    - Refactor nil treatment in pick/drop
    - Refactor DataFrame#pick/#drop using new parser
    - Refactor DataFrame#[]
    - Refactor Vector#[], #take, #filter by updating parser
    - Add for_keys option to parse_args
    - Refactor Vector properties by refinements for Arrow::Array
    - Refactor DataFrame selectable using Arrow::Array refinements instead of Vector methods
    - Refactor DataFrame#assign
  - Refine error message in DataFrame#to_long/to_wide #143)
  - Refactor Vector#take/filter returns arrow array (#148)
  - Change LineLength in cop from 120 to 90 (#152)
  - Refine DataFrame combinable (join) operations (#159)
    - Refine DataFrame#join effectively using outputs options
    - Simplify DataFrame set operations

- Improve in tests/CI
  - Tests
    - Update benchmark using 0.2.3 (#138)
    - Update benchmark basic#02/pick by [] (#140)
    - Update benchmark contexts and loop_count (#140)
    - Add benchmark for vector (#140)
    - Add tests for refinements (#140)
    - Add benchmark for the series of DataFrame operations (#140)
    - Add missing test for tdr and dictionary (#140)
    - Add missing test for group#method with foreign key (#152)
    - Add missing test for set operations and natural join (#152)
    - Add missing test for DataFrame#[] with selecting by Array of illegal type' (#152)
    - Add missing test for DataFrame#assign when assigner size is mismatch (#152)
    - Accept Hash as join keys in DataFrame join methods (#159)

  - Cops
    - Refactor/clean rubocop.yml (#138)

  - CI
    - Support Ruby 3.2 in CI test (#141)
    - Send test coverage report to Code Climate (#144)
    - Add test on Fedora (#151)
      - Thanks to Benson Muite.

    - Add workflow to generate document (#153)
      - Thanks to kojix2.

    - Support Code Climate test coverage report in CI (#155)

- Documentation
  - Add YARD in data_frame.rb (#140)
  - Fix YARD document in the code (#140)
  - Add Code Climate badges of maintainability and coverage (#144)
  - Add installation for Fedora in README (#147)
    - Thanks to Benson Muite.

  - Add Vector#split/merge in Vector.md (#148)
  - Fix codeclimate badges in README (#155)
  - Update YARD in DataFrame join methods (#159)
  - Update jupyter notebook '89 examples of Redamber' (#160)

- Thanks
  - Benson Muite
  - kojix2

## [0.2.3] - 2022-11-16

- Bug fixes

  - Fix DataFrame#to_s when DataFrame.size == 0 (#125)
  - Remove unused lines in funcs (#128)
  - Remove unused methods in helper (#128)
  - Add test for invalid arg in DataFrame.new (#128)
  - Add test for Vector#shift(0) (#128)
  - Fix bugs for DataFrame#[], #pick and #drop with Range of Symbols and Symbol (#135)

- New features and improvements

  - Upgrade dependency to Arrow 10.0.0 (#132)

    It is possible to initialize by the objects responsible to `to_arrow` since 0.2.3 .
    Arrays in Numo::NArray is responsible to `to_arrow` with Red Arrow Numo::NArray 0.0.6 .
    This feature is proposed by the Red Data Tools member @kojix2 and implemented by @kou.
    I made also Vector to be responsible to `to_arrow` and `to_arrow_array`.
    It becomes a member of ducks ('quack quack'). Thanks!

    - Change dev dependency to red-dataset-arrow (#117)
    - Add dev dependency for red-arrow-numo-narray (#132)
    - Support Numo::NArray in Vector.new (#132)
    - Support Vector#to_arrow_array (#132)

  - Update group (#118)
    - Introduce new DataFrame group support (experimental)

      This additional API will treat a grouped DataFrame as a list of DataFrames.
      I think this API has pros such as:
      - API is easy to understand and flexible.
      - It has good compatibility with Ruby's primitive Enumerables.
      - We can only use non hash-ed aggregation functions.
      - Do not need grouped DataFrame state, nor `#ungroup` method.
      - May be useful for concurrent operations.

      This feature is implemented by Ruby, so it is pretty slow and experimental.
      Use original Group API for practical purpose.

    - `include Enumerable` to Group  (experimental)
    - Add Group#each, #inspect
    - Refactor Group to align with Arrow

  - Introduce DataFrame combining methods (#125)
    - Introduce DataFrame#concatenate method
    - Add DataFrame#merge method
    - Add DataFrame#inner_join method
    - Add DataFrame#full_join method
    - Add DataFrame#left_join method
    - Add DataFrame#right_join method
    - Add DataFrame#semi_join method
    - Add DataFrame#anti_join method
    - Add DataFrame#intersect method
    - Add DataFrame#union method
    - Add DataFrame#setdiff method
      - Rename #setdiff to #difference
    - Support natural join in DataFrame#join
    - Support partial join_key and renaming
    - Fix DataFrame#join to merge key columns
    - Add DataFrame#set_operable? method
    - Add join/set/bind image to DataFrame.md
    - Fix DataFrame#join, #right_semi, #right_anti (#128)

  - Miscellaneous
    - Return Vector in DataFrame#indices (#118)

- Improve tests/ci

  - Improve CI
    - Add CI test on macOS (#133)
    - Enable bundler-cache on macOS (#128)
    - Add install gobject introspection prior to glib in CI (#133)
      This will stabilize CI system installation especially with cache.

    - Rename workflows/test.yml to ci.yml (#133)
      - Fix link in CI badge of README.md (#118)

    - Add github action for coverage (#128)

  - Add benchmark
    - Add benchmarks with Rover (#118)
    - Introduce benchmark suite (#134)
    - Add benchmark for combining operations (#134)

  - Measuring test coverage
    - Add test coverage measurement (#128)

- Refactoring

  - Remove redundant string escape in `test_vector_function` (#132)
  - Refine tests to use `assert_equal_array` (#128)
  - Rewrite Vector#replace (#128)

- Documentation

  - Update README.md for installation (#126)
  - Add clause that keys must be unique in doc. (#126)
  - Rows should be called as 'records' (#126)
  - Update Jupyter Notebook `83 examples of RedAmber` (#135)

- GitHub site

    - Update Jupyter notebooks in Binder
    - Change default branch name from 'master' to 'main' (#127)

- Thanks

  Ruby Association Grant committee
    It is a great honor for selecting RedAmber as a project of Ruby Association Grant 2022.


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
    - Move `DataFrame#slice`, `#remove` to Selectable
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
