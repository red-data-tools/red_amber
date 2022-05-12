# RedAmber

A simple dataframe library for Ruby (experimental)

- Powered by [Red Arrow](https://github.com/apache/arrow/tree/master/ruby/red-arrow)
- Simple API similar to [Rover-df](https://github.com/ankane/rover)

## Requirements

```ruby
gem 'red-arrow',   '>= 7.0.0'
gem 'red-parquet', '>= 7.0.0' # if you use IO from/to parquet
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

- [x] `types`
  
  Returns types of columns by an Array of Symbols.

- [x] `data_types`

  Returns types of columns by an Array of `Arrow::DataType`.

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

  Shows some information about self in a transposed style.

```ruby
hash = {a: [1, 2, 3], b: %w[A B C], c: [1.0, 2, 3]}
RedAmber::DataFrame.new(hash)
# =>
RedAmber::DataFrame : 3 observations(rows) of 3 variables(columns)
Variables : 2 numeric, 1 string
# key type   level data_preview
1 :a  uint8      3 [1, 2, 3]
2 :b  string     3 [A, B, C]
3 :c  double     3 [1.0, 2.0, 3.0]
```

  - tally_level: max level to use tally mode
  - max_element: max num of element to show values in each row

### Selecting

- [x] Select columns by `[]` as `[key]`, `[keys]`, `[keys[index]]`
  - Key in a Symbol: `df[:symbol]`
  - Key in a String: `df["string"]`
  - Keys in an Array: `df[:symbol1`, `"string"`, `:symbol2`
  - Keys in indeces: `df[df.keys[0]`, `df[df.keys[1,2]]`, `df[df.keys[1..]]`
  - Keys in a Range:
    A end-less Range can be used to represent keys.
```ruby
hash = {a: [1, 2, 3], b: %w[A B C], c: [1.0, 2, 3]}
df = RedAmber::DataFrame.new(hash)
df[:b..:c, "a"]
# =>
RedAmber::DataFrame : 3 observations(rows) of 3 variables(columns)
Variables : 2 numeric, 1 string
# key type   level data_preview
1 :b  string     3 [A, B, C]
2 :c  double     3 [1.0, 2.0, 3.0]
3 :a  uint8      3 [1, 2, 3]
```

- [x] Select rows by `[]` as `[index]`, `[range]`, `[array]`
  - Select a row by index: `df[0]`
  - Select rows by indeces in a Range: `df[1..2]`
  - Select rows by indeces in an Array: `df[1, 2]`
  - Mixed case: `df[2, 0..]`

- [x] Select rows from top or bottom

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

- [x] Create from a column in a DataFrame

- [x] New from an Array

### Properties

- [x] `to_s`

- [x] `values`, `to_a`, `entries`

- [x] `size`, `length`, `n_rows`, `nrow`

- [x] `type`

- [x] `data_type`

- [ ] `each`

- [ ] `chunked?`

- [ ] `n_chunks`

- [ ] `each_chunk`

- [x] `tally`

- [ ] `n_nulls`

### Functions
#### Unary aggregations: vector.func => Scalar

| Method    |Boolean|Numeric|String|Remarks|
| ------------ | --- | --- | --- | ----- |
| ✓ `all`     |  ✓  |     |     |       |
| ✓ `any`     |  ✓  |     |     |       |
| ✓ `approximate_median`| |  ✓  |     |     |
| ✓ `count`         |  ✓  |  ✓  |  ✓  |     |
| ✓ `count_distinct`|  ✓  |  ✓  |  ✓  |     |
| ✓ `count_uniq`    |  ✓  |  ✓  |  ✓  |an alias of `count_distinct`|
|[ ] `index`   |     |     |     |       |
| ✓ `max`     |  ✓  |  ✓  |  ✓  |       |
| ✓ `mean`    |  ✓  |  ✓  |     |       |
| ✓ `min`     |  ✓  |  ✓  |  ✓  |       |
|[ ] `min_max` |     |     |     |       |
|[ ] `mode`    |     |     |     |       |
| ✓ `product` |  ✓  |  ✓  |     |       |
|[ ] `quantile`|     |     |     |       |
| ✓ `stddev`  |     |  ✓  |     |       |
| ✓ `sum`     |  ✓  |  ✓  |     |       |
|[ ] `tdigest` |     |     |     |       |
| ✓ `variance`|     |  ✓  |     |       |

#### Unary element-wise: vector.func => Vector

| Method    |Boolean|Numeric|String|Remarks|
| ------------ | --- | --- | --- | ----- |
| ✓ `-@`      |     |  ✓  |     |as `-vector`|
| ✓ `negate`  |     |  ✓  |     |`-@`   |
| ✓ `abs`     |     |  ✓  |     |       |
|[ ] `acos`    |     | [ ] |     |       |
|[ ] `asin`    |     | [ ] |     |       |
| ✓ `atan`    |     |  ✓  |     |       |
| ✓ `bit_wise_not`  |     | (✓) |     |integer only|
|[ ] `ceil`    |     |  ✓  |     |       |
| ✓ `cos`     |     |  ✓  |     |       |
|[ ] `floor`   |     |  ✓  |     |       |
| ✓ `invert`  |  ✓  |     |     |`!`, alias `not`|
|[ ] `ln`      |     | [ ] |     |       |
|[ ] `log10`   |     | [ ] |     |       |
|[ ] `log1p`   |     | [ ] |     |       |
|[ ] `log2`    |     | [ ] |     |       |
| ✓ `sign`    |     |  ✓  |     |       |
| ✓ `sin`     |     |  ✓  |     |       |
| ✓ `tan`     |     |  ✓  |     |       |
|[ ] `trunc`   |     |  ✓  |     |       |

#### Binary element-wise: vector.func(vector) => Vector

| Method          |Boolean|Numeric|String|Remarks|
| ------------------ | --- | --- | --- | ----- |
| ✓ `add`           |     |  ✓  |     | `+`   |
| ✓ `atan2`         |     |  ✓  |     |       |
| ✓ `and_kleene`    |  ✓  |     |     | `&`   |
| ✓ `and_org   `    |  ✓  |     |     |`and` in Red Arrow|
| ✓ `and_not`       |  ✓  |     |     |       |
| ✓ `and_not_kleene`|  ✓  |     |     |       |
|[ ] `bit_wise_and`  |     | (✓) |     |integer only|
|[ ] `bit_wise_or`   |     | (✓) |     |integer only|
|[ ] `bit_wise_xor`  |     | (✓) |     |integer only|
| ✓ `divide`        |     |  ✓  |     | `/`   |
| ✓ `equal`         |  ✓  |  ✓  |  ✓  |`==`, alias `eq`|
| ✓ `greater`       |  ✓  |  ✓  |  ✓  |`>`, alias `gt`|
| ✓ `greater_equal` |  ✓  |  ✓  |  ✓  |`>=`, alias `ge`|
| ✓ `less`          |  ✓  |  ✓  |  ✓  |`<`, alias `lt`|
| ✓ `less_equal`    |  ✓  |  ✓  |  ✓  |`<=`, alias `le`|
|[ ] `logb`          |     | [ ] |     |       |
|[ ] `mod`           |     | [ ] |     | `%`   |
| ✓ `multiply`      |     |  ✓  |     | `*`   |
| ✓ `not_equal`     |  ✓  |  ✓  |  ✓  |`!=`, alias `ne`|
| ✓ `or_kleene`     |  ✓  |     |     | `\|`   |
| ✓ `or_org`        |  ✓  |     |     |`or` in Red Arrow|
| ✓ `power`         |     |  ✓  |     | `**`  |
| ✓ `subtract`      |     |  ✓  |     | `-`   |
| ✓ `shift_left`    |     | (✓) |     |`<<`, integer only|
| ✓ `shift_right`   |     | (✓) |     |`>>`, integer only|
| ✓ `xor`           |  ✓  |     |     | `^`   |

##### (Not impremented)
- [ ] round, round_to_multiple
- [ ] sort, sort_index
- [ ] minmax, var, median, quantile
- [ ] argmin, argmax
- [ ] (array functions)
- [ ] (strings functions)
- [ ] (temporal functions)
- [ ] (conditional functions)
- [ ] (index functions)
- [ ] (other functions)

### Coerce (not impremented)

### Updating (not impremented)

### DSL in a block for faster calculation ?


## Development

```shell
git clone https://github.com/heronshoes/red_amber.git
cd red_amber
bundle install
bundle exec rake test
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
