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

- [x] `load` (class method)

     - [x] from a [`.arrow`, `.arrows`, `.csv`, `.csv.gz`, `.tsv`] file
       - `RedAmber::DataFrame.load("test/entity/with_header.csv")`

     - [x] from a string buffer

     - [x] from a URI
       - `RedAmber::DataFrame.load(URI("https://github.com/heronshoes/red_amber/blob/master/test/entity/with_header.csv"))`

     - [x] from a Parquet file

       `red-parquet` gem is required.

  ```ruby
    require 'parquet'
    dataframe = RedAmber::DataFrame.load("file.parquet")
  ```

- [x] `save` (instance method)

     - [x] to a [`.arrow`, `.arrows`, `.csv`, `.csv.gz`, `.tsv`] file

     - [x] to a string buffer

     - [x] to a URI

     - [x] to a Parquet file

       `red-parquet` gem is required.

  ```ruby
    require 'parquet'
    dataframe.save("file.parquet")
  ```

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
require 'red_amber'
require 'datasets-arrow'

penguins = Datasets::Penguins.new.to_arrow
RedAmber::DataFrame.new(penguins)
# =>
RedAmber::DataFrame : 344 x 8 Vectors
Vectors : 5 numeric, 3 strings
# key                type   level data_preview
1 :species           string     3 {"Adelie"=>152, "Chinstrap"=>68, "Gentoo"=>124}
2 :island            string     3 {"Torgersen"=>52, "Biscoe"=>168, "Dream"=>124}
3 :bill_length_mm    double   165 [39.1, 39.5, 40.3, nil, 36.7, ... ], 2 nils
4 :bill_depth_mm     double    81 [18.7, 17.4, 18.0, nil, 19.3, ... ], 2 nils
5 :flipper_length_mm uint8     56 [181, 186, 195, nil, 193, ... ], 2 nils
6 :body_mass_g       uint16    95 [3750, 3800, 3250, nil, 3450, ... ], 2 nils
7 :sex               string     3 {"male"=>168, "female"=>165, nil=>11}
8 :year              uint16     3 {2007=>110, 2008=>114, 2009=>120}
```

  - tally_level: max level to use tally mode
  - max_element: max num of element to show values in each row

### Selecting

- [x] Select columns by `[]` as `[key]`, `[keys]`, `[keys[index]]`
  - Key in a Symbol: `df[:symbol]`
  - Key in a String: `df["string"]`
  - Keys in an Array: `df[:symbol1, "string", :symbol2]`
  - Keys in indeces: `df[df.keys[0]`, `df[df.keys[1,2]]`, `df[df.keys[1..]]`
  - Keys in a Range:
    A end-less Range can be used to represent keys.

```ruby
hash = {a: [1, 2, 3], b: %w[A B C], c: [1.0, 2, 3]}
df = RedAmber::DataFrame.new(hash)
df[:b..:c, "a"]
# =>
RedAmber::DataFrame : 3 x 3 Vectors
Vectors : 2 numeric, 1 string
# key type   level data_preview
1 :b  string     3 ["A", "B", "C"]
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

- [x] `n_nils`, `n_nans`

  - `n_nulls` is an alias of `n_nils`

- [x] `inspect(limit: 80)`

  - `limit` sets size limit to display long array.

### Functions
#### Unary aggregations: vector.func => scalar

| Method    |Boolean|Numeric|String|Options|Remarks|
| ----------- | --- | --- | --- | --- | --- |
| ✓ `all`     |  ✓  |     |     | ✓ ScalarAggregate|     |
| ✓ `any`     |  ✓  |     |     | ✓ ScalarAggregate|     |
| ✓ `approximate_median`|  |✓|  | ✓ ScalarAggregate| alias `median`|
| ✓ `count`   |  ✓  |  ✓  |  ✓  | ✓  Count  |     |
| ✓ `count_distinct`| ✓ | ✓ | ✓ | ✓  Count  |alias `count_uniq`|
|[ ]`index`   | [ ] | [ ] | [ ] |[ ] Index  |     |
| ✓ `max`     |  ✓  |  ✓  |  ✓  | ✓ ScalarAggregate|     |
| ✓ `mean`    |  ✓  |  ✓  |     | ✓ ScalarAggregate|     |
| ✓ `min`     |  ✓  |  ✓  |  ✓  | ✓ ScalarAggregate|     |
|[ ]`min_max` | [ ] | [ ] | [ ] |[ ] ScalarAggregate|     |
|[ ]`mode`    |     | [ ] |     |[ ] Mode    |     |
| ✓ `product` |  ✓  |  ✓  |     | ✓ ScalarAggregate|     |
|[ ]`quantile`|     | [ ] |     |[ ] Quantile|     |
|[ ]`stddev`  |     |  ✓  |     |[ ] Variance|     |
| ✓ `sum`     |  ✓  |  ✓  |     | ✓ ScalarAggregate|     |
|[ ]`tdigest` |     | [ ] |     |[ ] TDigest |     |
|[ ]`variance`|     |  ✓  |     |[ ] Variance|     |


Options can be used as follows.
See the [document of C++ function](https://arrow.apache.org/docs/cpp/compute.html) for detail.

```ruby
double = RedAmber::Vector.new([1, 0/0.0, -1/0.0, 1/0.0, nil, ""])
#=>
#<RedAmber::Vector(:double, size=6):0x000000000000f910>
[1.0, NaN, -Infinity, Infinity, nil, 0.0]

double.count #=> 5
double.count(opts: {mode: :only_valid}) #=> 5, default
double.count(opts: {mode: :only_null}) #=> 1
double.count(opts: {mode: :all}) #=> 6

boolean = RedAmber::Vector.new([true, true, nil])
#=>
#<RedAmber::Vector(:boolean, size=3):0x000000000000f924>
[true, true, nil]

boolean.all #=> true
boolean.all(opts: {skip_nulls: true}) #=> true
boolean.all(opts: {skip_nulls: false}) #=> false
```

#### Unary element-wise: vector.func => vector

| Method    |Boolean|Numeric|String|Options|Remarks|
| ------------ | --- | --- | --- | --- | ----- |
| ✓ `-@`       |     |  ✓  |     |     |as `-vector`|
| ✓ `negate`   |     |  ✓  |     |     |`-@`   |
| ✓ `abs`      |     |  ✓  |     |     |       |
|[ ]`acos`     |     | [ ] |     |     |       |
|[ ]`asin`     |     | [ ] |     |     |       |
| ✓ `atan`     |     |  ✓  |     |     |       |
| ✓ `bit_wise_not`|  | (✓) |     |     |integer only|
|[ ]`ceil`     |     |  ✓  |     |     |       |
| ✓ `cos`      |     |  ✓  |     |     |       |
|[ ]`floor`    |     |  ✓  |     |     |       |
| ✓ `invert`   |  ✓  |     |     |     |`!`, alias `not`|
|[ ]`ln`       |     | [ ] |     |     |       |
|[ ]`log10`    |     | [ ] |     |     |       |
|[ ]`log1p`    |     | [ ] |     |     |       |
|[ ]`log2`     |     | [ ] |     |     |       |
|[ ]`round`    |     | [ ] |     |[ ] Round|       |
|[ ]`round_to_multiple`| | [ ] | |[ ] RoundToMultiple|       |
| ✓ `sign`     |     |  ✓  |     |     |       |
| ✓ `sin`      |     |  ✓  |     |     |       |
| ✓ `tan`      |     |  ✓  |     |     |       |
|[ ]`trunc`    |     |  ✓  |     |     |       |

#### Binary element-wise: vector.func(vector) => vector

| Method       |Boolean|Numeric|String|Options|Remarks|
| ----------------- | --- | --- | --- | --- | ----- |
| ✓ `add`           |     |  ✓  |     |     | `+`   |
| ✓ `atan2`         |     |  ✓  |     |     |       |
| ✓ `and_kleene`    |  ✓  |     |     |     | `&`   |
| ✓ `and_org   `    |  ✓  |     |     |     |`and` in Red Arrow|
| ✓ `and_not`       |  ✓  |     |     |     |       |
| ✓ `and_not_kleene`|  ✓  |     |     |     |       |
| ✓ `bit_wise_and`  |     | (✓) |     |     |integer only|
| ✓ `bit_wise_or`   |     | (✓) |     |     |integer only|
| ✓ `bit_wise_xor`  |     | (✓) |     |     |integer only|
| ✓ `divide`        |     |  ✓  |     |     | `/`   |
| ✓ `equal`         |  ✓  |  ✓  |  ✓  |     |`==`, alias `eq`|
| ✓ `greater`       |  ✓  |  ✓  |  ✓  |     |`>`, alias `gt`|
| ✓ `greater_equal` |  ✓  |  ✓  |  ✓  |     |`>=`, alias `ge`|
| ✓ `is_finite`     |     |  ✓  |     |     |       |
| ✓ `is_inf`        |     |  ✓  |     |     |       |
| ✓ `is_na`         |  ✓  |  ✓  |  ✓  |     |       |
| ✓ `is_nan`        |     |  ✓  |     |     |       |
|[ ]`is_nil`        |  ✓  |  ✓  |  ✓  |[ ] Null|alias `is_null`|
| ✓ `is_valid`      |  ✓  |  ✓  |  ✓  |     |       |
| ✓ `less`          |  ✓  |  ✓  |  ✓  |     |`<`, alias `lt`|
| ✓ `less_equal`    |  ✓  |  ✓  |  ✓  |     |`<=`, alias `le`|
|[ ]`logb`          |     | [ ] |     |     |       |
|[ ]`mod`           |     | [ ] |     |     | `%`   |
| ✓ `multiply`      |     |  ✓  |     |     | `*`   |
| ✓ `not_equal`     |  ✓  |  ✓  |  ✓  |     |`!=`, alias `ne`|
| ✓ `or_kleene`     |  ✓  |     |     |     | `\|`  |
| ✓ `or_org`        |  ✓  |     |     |     |`or` in Red Arrow|
| ✓ `power`         |     |  ✓  |     |     | `**`  |
| ✓ `subtract`      |     |  ✓  |     |     | `-`   |
| ✓ `shift_left`    |     | (✓) |     |     |`<<`, integer only|
| ✓ `shift_right`   |     | (✓) |     |     |`>>`, integer only|
| ✓ `xor`           |  ✓  |     |     |     | `^`   |

##### (Not impremented)
- [ ] sort, sort_index
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
