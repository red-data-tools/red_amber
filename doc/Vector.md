# Vector

Class `RedAmber::Vector` represents a series of data in the DataFrame.

## Constructor

### Create from a column in a DataFrame
  
  ```ruby
  df = RedAmber::DataFrame.new(x: [1, 2, 3])
  df[:x]
  # =>
  #<RedAmber::Vector(:uint8, size=3):0x000000000000f4ec>
  [1, 2, 3]
  ```

### New from an Array

  ```ruby
  vector = RedAmber::Vector.new([1, 2, 3])
  # =>
  #<RedAmber::Vector(:uint8, size=3):0x000000000000f514>
  [1, 2, 3]
  ```

## Properties

### `to_s`

### `values`, `to_a`, `entries`

### `size`, `length`, `n_rows`, `nrow`

### `type`

### `boolean?`, `numeric?`, `string?`, `temporal?`

### `type_class`

### [ ] `each` (not impremented yet)

### [ ] `chunked?` (not impremented yet)

### [ ] `n_chunks` (not impremented yet)

### [ ] `each_chunk` (not impremented yet)

### `n_nils`, `n_nans`

  - `n_nulls` is an alias of `n_nils`

### `has_nil?`

  Returns `true` if self has any `nil`. Otherwise returns `false`.

### `inspect(limit: 80)`

  - `limit` sets size limit to display long array.

    ```ruby
    vector = RedAmber::Vector.new((1..50).to_a)
    # =>
    #<RedAmber::Vector(:uint8, size=50):0x000000000000f528>
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, ... ]
    ```

## Functions

### Unary aggregations: `vector.func => scalar`

  ![unary aggregation](doc/image/../../image/vector/unary_aggregation_w_option.png)

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
| ✓ `min_max` |  ✓  |  ✓  |  ✓  | ✓ ScalarAggregate|     |
|[ ]`mode`    |     | [ ] |     |[ ] Mode    |     |
| ✓ `product` |  ✓  |  ✓  |     | ✓ ScalarAggregate|     |
|[ ]`quantile`|     | [ ] |     |[ ] Quantile|     |
| ✓ `sd    `  |     |  ✓  |     |          |ddof: 1 at `stddev`|
| ✓ `stddev`  |     |  ✓  |     | ✓ Variance|ddof: 0 by default|
| ✓ `sum`     |  ✓  |  ✓  |     | ✓ ScalarAggregate|     |
|[ ]`tdigest` |     | [ ] |     |[ ] TDigest |     |
| ✓ `var    `|     |  ✓  |     |   |ddof: 1 at `variance`<br>alias `unbiased_variance`|
| ✓ `variance`|     |  ✓  |     | ✓ Variance|ddof: 0 by default|


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

### Unary element-wise: `vector.func => vector`

  ![unary element-wise](doc/image/../../image/vector/unary_element_wise.png)

| Method    |Boolean|Numeric|String|Options|Remarks|
| ------------ | --- | --- | --- | --- | ----- |
| ✓ `-@`       |     |  ✓  |     |     |as `-vector`|
| ✓ `negate`   |     |  ✓  |     |     |`-@`   |
| ✓ `abs`      |     |  ✓  |     |     |       |
|[ ]`acos`     |     | [ ] |     |     |       |
|[ ]`asin`     |     | [ ] |     |     |       |
| ✓ `atan`     |     |  ✓  |     |     |       |
| ✓ `bit_wise_not`|  | (✓) |     |     |integer only|
| ✓ `ceil`     |     |  ✓  |     |     |       |
| ✓ `cos`      |     |  ✓  |     |     |       |
| ✓`fill_nil_backward`| ✓ | ✓ | ✓ |    |       |
| ✓`fill_nil_forward` | ✓ | ✓ | ✓ |    |       |
| ✓ `floor`    |     |  ✓  |     |     |       |
| ✓ `invert`   |  ✓  |     |     |     |`!`, alias `not`|
|[ ]`ln`       |     | [ ] |     |     |       |
|[ ]`log10`    |     | [ ] |     |     |       |
|[ ]`log1p`    |     | [ ] |     |     |       |
|[ ]`log2`     |     | [ ] |     |     |       |
| ✓ `round`    |     |  ✓  |     | ✓ Round (:mode, :n_digits)|    |
| ✓ `round_to_multiple`| | ✓ |   | ✓ RoundToMultiple :mode, :multiple| multiple must be an Arrow::Scalar|
| ✓ `sign`     |     |  ✓  |     |     |       |
| ✓ `sin`      |     |  ✓  |     |     |       |
| ✓`sort_indexes`| ✓  | ✓  | ✓  |:order|alias `sort_indices`|
| ✓ `tan`      |     |  ✓  |     |     |       |
| ✓ `trunc`    |     |  ✓  |     |     |       |

### Binary element-wise: `vector.func(vector) => vector`

  ![binary element-wise](doc/image/../../image/vector/binary_element_wise.png)

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

### `uniq`

  Returns a new array with distinct elements.

(Not impremented functions)

### `tally` and `value_counts`

  Compute counts of unique elements and return a Hash.

  It returns almost same result as Ruby's tally. These methods consider NaNs are same.

  ```ruby
  array = [0.0/0, Float::NAN]
  array.tally #=> {NaN=>1, NaN=>1}

  vector = RedAmber::Vector.new(array)
  vector.tally #=> {NaN=>2}
  vector.value_counts #=> {NaN=>2}
  ```

### `sort_indexes`, `sort_indices`, `array_sort_indices`

### [ ] `sort`, `sort_by`
### [ ] argmin, argmax
### [ ] (array functions)
### [ ] (strings functions)
### [ ] (temporal functions)
### [ ] (conditional functions)
### [ ] (index functions)
### [ ] (other functions)

## Coerce (not impremented)

## Update vector's value
### `replace_with(booleans, replacements)` => vector

- Accepts Vector, Array, Arrow::Array for booleans and replacements.
  - Replacements can accept scalar
- Booleans specifies the position of replacement in true.
- Replacements specifies the vaues to be replaced.
  - The number of true in booleans must be equal to the length of replacement

```ruby
vector = RedAmber::Vector.new([1, 2, 3])
booleans = [true, false, true]
replacemants = [4, 5]
vector.replace_with(booleans, replacemants)
# => 
#<RedAmber::Vector(:uint8, size=3):0x000000000001ee10>
[4, 2, 5] 
```

- Scalar value in replacements can be broadcasted.

```ruby
replacemant = 0
vector.replace_with(booleans, replacement)
# => 
#<RedAmber::Vector(:uint8, size=3):0x000000000001ee10>
[0, 2, 0] 
```

- Returned data type is automatically up-casted by replacement.

```ruby
replacement = 1.0
vector.replace_with(booleans, replacement)
# => 
#<RedAmber::Vector(:double, size=3):0x0000000000025d78>
[1.0, 2.0, 1.0]
```

- Position of nil in booleans is replaced with nil.

```ruby
booleans = [true, false, nil]
replacemant = -1
vec.replace_with(booleans, replacement)
=> 
#<RedAmber::Vector(:int8, size=3):0x00000000000304d0>
[-1, 2, nil]
```

- Replacemants can have nil in it.

```ruby
booleans = [true, false, true]
replacemants = [nil]
vec.replace_with(booleans, replacemants)
=> 
#<RedAmber::Vector(:int8, size=3):0x00000000000304d0>
[nil, 2, nil]
```

- If no replacemants specified, it is same as to specify nil.

```ruby
booleans = [true, false, true]
vec.replace_with(booleans)
=> 
#<RedAmber::Vector(:int8, size=3):0x00000000000304d0>
[nil, 2, nil]
```

- An example to replace 'NA' to nil.

```ruby
vector = RedAmber::Vector.new(['A', 'B', 'NA'])
vector.replace_with(vector == 'NA', nil)
# =>
#<RedAmber::Vector(:string, size=3):0x000000000000f8ac>
["A", "B", nil]
```

### `fill_nil_forward`, `fill_nil_backward` => vector

Propagate the last valid observation forward (or backward).
Or preserve nil if all previous values are nil or at the end.

```ruby
integer = RedAmber::Vector.new([0, 1, nil, 3, nil])
integer.fill_nil_forward
# =>
#<RedAmber::Vector(:uint8, size=5):0x000000000000f960>
[0, 1, 1, 3, 3]

integer.fill_nil_backward
# =>
#<RedAmber::Vector(:uint8, size=5):0x000000000000f974>
[0, 1, 3, 3, nil]
```
