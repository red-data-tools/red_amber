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

### `tally`

### `n_nils`, `n_nans`

  - `n_nulls` is an alias of `n_nils`

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

(Not impremented functions)
### [ ] sort, sort_index
### [ ] argmin, argmax
### [ ] (array functions)
### [ ] (strings functions)
### [ ] (temporal functions)
### [ ] (conditional functions)
### [ ] (index functions)
### [ ] (other functions)

## Coerce (not impremented)

## Updating (not impremented)
