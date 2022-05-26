# Vector

Class `RedAmber::Vector` represents a series of data in the DataFrame.

## Constructor

- [x] Create from a column in a DataFrame

- [x] New from an Array

## Properties

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

## Functions
### Unary aggregations: vector.func => scalar

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

### Unary element-wise: vector.func => vector

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

### Binary element-wise: vector.func(vector) => vector

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

#### (Not impremented)
- [ ] sort, sort_index
- [ ] argmin, argmax
- [ ] (array functions)
- [ ] (strings functions)
- [ ] (temporal functions)
- [ ] (conditional functions)
- [ ] (index functions)
- [ ] (other functions)

## Coerce (not impremented)

## Updating (not impremented)
