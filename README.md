# RedAmber

Simple dataframe library for Ruby (experimental)

- Powered by [Red Arrow](https://github.com/apache/arrow/tree/master/ruby/red-arrow)
- [Rover-df](https://github.com/ankane/rover) like simple API

## Requirements

```ruby
gem 'red-arrow',   '~> 7.0.0'
gem 'red-parquet', '~> 7.0.0' # if you use IO from/to parquet
gem 'rover-df',    '~> 0.3.0' # if you use IO from/to Rover::DataFrame
```

## Installation

Add this line to your Gemfile:

```ruby
gem 'red_amber'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install red_amber

## `RedAmber::DataFrame`

### Constructors and saving

- [x] `new` from a columnar Hash
  - `RedAmber::DataFrame.new(x: [1, 2, 3])`

- [x] `new` from a schema (by Hash) and rows (by Array)
  - `RedAmber::DataFrame.new({:x=>:uint8}, [[1], [2], [3]])`

- [x] `new` from an Arrow::Table
  - `RedAmber::DataFrame.new(Arrow::Table.new(x: [1, 2, 3]))`

- [x] `new` from a Rover::DataFrame
  - `RedAmber::DataFrame.new(Rover::DataFrame.new(x: [1, 2, 3]))`

- [ ] `load` (class method)

     - [x] from a [`.arrow`, `.arrows`, `.csv`, `.csv.gz`, `.tsv`] file
       - `RedAmber::DataFrame.load("test/entity/with_header.csv")`

     - [x] from a string buffer

     - [x] from a URI
       - `RedAmber::DataFrame.load(URI("https://github.com/heronshoes/red_amber/blob/master/test/entity/with_header.csv"))`

     - [ ] from a parquet file

- [ ] `save` (instance method)

     - [x] to a [`.arrow`, `.arrows`, `.csv`, `.csv.gz`, `.tsv`] file

     - [x] to a string buffer

     - [x] to a URI

     - [ ] to a parquet file

### Properties

- [x] `table`

  Reader of Arrow::Table object inside.

- [x] `n_rows`, `nrow`, `size`, `length`
  
  Returns num of rows (data size).
 
- [x] `n_columns`, `ncol`, `width`
  
  Returns num of columns (num of vectors).
 
- [x] `shape`
 
  Returns shape in an Array[n_rows, n_cols].
 
- [x] `column_names`, `keys`
  
  Returns num of column names by an Array.

- [x] `types(class_name: false)`
  
  Returns types of columns by an Array.
  If `class_name: true` returns an Array of `Arrow::DataType`.

- [x] `vectors`

  Returns an Array of Vectors.

- [x] `to_h`

  Returns column-oriented data in a Hash.

- [x] `to_a`, `raw_records`

  Returns an array of row-oriented data without header. If you need a column-oriented full array, use `.to_h.to_a`

- [x] `schema`

  Returns column name and data type in a Hash.

- [x] `==`
 
- [x] `empty?`

### Output

- [x] `to_s`

- [ ] summary, describe

- [x] `to_rover`

  Returns a `Rover::DataFrame`.

- [x] `inspect(tally_level: 5, max_element: 5)`

  Shows some information about self.

  - tally_level: max level to use tally mode
  - max_element: max num of element to show values in each row

### Selecting

- [x] Selecting columns by `[]`

  `[key]`, `[keys]`, `[keys[index]]`

- [x] Selecting rows by `[]`

  `[index]`, `[range]`, `[array]`

- [x] Selecting rows from top or bottom

  `head(n=5)`, `tail(n=5)`, `first(n=1)`, `last(n=1)`

- [ ] slice

### Updating

- [ ] Add a new column

- [ ] Update a single element

- [ ] Update multiple elements

- [ ] Update all elements

- [ ] Update elements matching a condition

- [ ] Clamp

- [ ] Delete columns

- [ ] Rename a column

- [ ] Sort rows

- [ ] Clear data

### Treat na data

- [ ] Drop na (NaN, nil)

- [ ] Replace na with value

- [ ] Interpolate na with convolution array

### Combining DataFrames

- [ ] Add rows

- [ ] Add columns

- [ ] Inner join

- [ ] Left join

### Encoding

- [ ] One-hot encoding

### Iteration (not impremented)

### Filtering (not impremented)


## `RedAmber::Vector`
### Constructor

- [x] Create from columns in a DataFrame

- [x] new from an Array

### Properties

- [x] `to_s`

- [x] `values`, `to_a`, `entries`

- [x] `size`, `length`, `n_rows`, `nrow`

- [x] `type`

- [ ] `each`

- [ ] `chunked?`

- [ ] `n_chunks`

- [ ] `each_chunk`

- [x] `tally`

- [ ] `n_nulls`

### Functions
#### Unary aggregations: vector.func => Scalar

| Method                          |Boolean           |Numeric           |String            |Remarks|
| ------------------------------- | ---------------- | ---------------- | ---------------- | ----- |
|:ballot_box_with_check:`all`     |:heavy_check_mark:|                  |                  |       |
|:ballot_box_with_check:`any`     |:heavy_check_mark:|                  |                  |       |
|:ballot_box_with_check:`approximate_median`|        |:heavy_check_mark:|                  |       |
|:ballot_box_with_check:`count`   |:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|       |
|:ballot_box_with_check:`count_distinct`|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:| |
|:ballot_box_with_check:`count_uniq`    |:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|an alias of `count_distinct`|
|:white_large_square:   `index`   |                  |                  |                  |       |
|:ballot_box_with_check:`max`     |:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|       |
|:ballot_box_with_check:`mean`    |:heavy_check_mark:|:heavy_check_mark:|                  |       |
|:ballot_box_with_check:`min`     |:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|       |
|:white_large_square:   `min_max` |                  |                  |                  |       |
|:white_large_square:   `mode`    |                  |                  |                  |       |
|:ballot_box_with_check:`product` |:heavy_check_mark:|:heavy_check_mark:|                  |       |
|:white_large_square:   `quantile`|                  |                  |                  |       |
|:ballot_box_with_check:`stddev`  |                  |:heavy_check_mark:|                  |       |
|:ballot_box_with_check:`sum`     |:heavy_check_mark:|:heavy_check_mark:|                  |       |
|:white_large_square:   `tdigest` |                  |                  |                  |       |
|:ballot_box_with_check:`variance`|                  |:heavy_check_mark:|                  |       |

#### Unary element-wise: vector.func => Vector

| Method                          |Boolean           |Numeric           |String            |Remarks|
| ------------------------------- | ---------------- | ---------------- | ---------------- | ----- |
|:ballot_box_with_check:`-@`      |                  |:heavy_check_mark:|                  |as `-vector` |
|:ballot_box_with_check:`negate`  |                  |:heavy_check_mark:|                  |        |
|:ballot_box_with_check:`abs`     |                  |:heavy_check_mark:|                  |        |
|:white_large_square:   `acos`    |                  |:white_large_square:|                |        |
|:white_large_square:   `asin`    |                  |:white_large_square:|                |        |
|:ballot_box_with_check:`atan`    |                  |:heavy_check_mark:|                  |        |
|:ballot_box_with_check:`ceil`    |                  |:heavy_check_mark:|                  |        |
|:ballot_box_with_check:`cos`     |                  |:heavy_check_mark:|                  |        |
|:ballot_box_with_check:`floor`   |                  |:heavy_check_mark:|                  |        |
|:white_large_square:   `ln`      |                  |:white_large_square:|                |        |
|:white_large_square:   `log10`   |                  |:white_large_square:|                |        |
|:white_large_square:   `log1p`   |                  |:white_large_square:|                |        |
|:white_large_square:   `log2`    |                  |:white_large_square:|                |        |
|:ballot_box_with_check:`sign`    |                  |:heavy_check_mark:|                  |        |
|:ballot_box_with_check:`sin`     |                  |:heavy_check_mark:|                  |        |
|:ballot_box_with_check:`tan`     |                  |:heavy_check_mark:|                  |        |

#####
- [ ] bit_wise_not, invert, round, round_to_multiple, trunc

#### Binary
- [ ] +, - , *, /, %, **
- [ ] ==, !=, >, >=, <, <=, eq, ne, gt, ge, lt, le

#### Functions
- [ ] sort, sort_index
- [ ] min, max, minmax, mean, stddev, var, median, quantile
- [ ] argmin, argmax

### Updating (not impremented)


## Development

```
git clone https://github.com/heronshoes/red_amber.git
cd red_amber
bundle install
bundle exec rake test
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
