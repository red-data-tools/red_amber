# Comparison of DataFrames

Compare basic features of RedAmber with [Python pandas](https://pandas.pydata.org/),
[R Tidyverse](https://www.tidyverse.org/) and
[Julia DataFrames](https://dataframes.juliadata.org/stable/).

## Select columns (variables)

| Features                        |	RedAmber        |	Tidyverse 	                     | pandas                                 | DataFrames.jl     |
|---                              |---              |---                              |---                                     |---                |
| Select columns as a dataframe   |	pick, drop, [] 	| dplyr::select, dplyr::select_if | [], loc[], iloc[], drop, select_dtypes | [], select        |
| Select a column as a vector     | 	[], v 	        | dplyr::pull, [, x]	             | [], loc[], iloc[]                      | [!, :x]           |
| Move columns to a new position  |	pick, [] 	      | relocate                        | [], reindex, loc[], iloc[]             | select,transform  |

## Select rows (records, observations)

| Features                                              |	RedAmber 	        | Tidyverse                   | pandas                   | DataFrames.jl |
|---                                                    |---                |---                          |---                       |---            |
| Select rows that meet logical criteria as a dataframe |	slice, remove, [] | 	dplyr::filter              |	[], filter, query, loc[] | filter        |
| Select rows by position as a dataframe 	              | slice, remove, [] | dplyr::slice 	              | iloc[], drop             | subset        |
| Move rows to a new position 	                         | slice, [] 	       | dplyr::filter, dplyr::slice |	reindex, loc[], iloc[]   | permute       |

## Update columns / create new columns

|Features 	                         | RedAmber 	          | Tidyverse 	                                        | pandas            | DataFrames.jl |
|---                                |---                  |---                                                 |---                |---            |
| Update existing columns           |	assign 	            | dplyr::mutate                                     	| assign, []=       | mapcols       |
| Create new columns 	              | assign, assign_left |	dplyr::mutate 	                                    | apply             | insertcols,.+ |
| Compute new columns, drop others 	| new 	               | transmute 	                                        | (dfply:)transmute | transform,insertcols,mapcols |
| Rename columns 	                  | rename              |	dplyr::rename, dplyr::rename_with, purrr::set_names |	rename, set_axis  | rename        |
| Sort dataframe 	                  | sort 	              | dplyr::arrange 	                                    | sort_values       | sort          |

## Reshape dataframe

| Features 	                                           | RedAmber 	| Tidyverse 	         | pandas       | DataFrames.jl |
|---                                                   |---        |---                  |---           |---            |
| Gather columns into rows (create a longer dataframe) |	to_long 	 | tidyr::pivot_longer |	melt         | stack         |
| Spread rows into columns (create a wider dataframe)  | to_wide 	 | tidyr::pivot_wider 	| pivot        | unstack       |
| transpose a wide dataframe 	                         | transpose | transpose, t 	      | transpose, T | permutedims   |

## Grouping

| Features | RedAmber 	              | Tidyverse 	                          | pandas       | DataFrames.jl   |
|---       |---                      |---                                   |---           |---              |
|Grouping 	| group, group.summarize 	| dplyr::group_by %>% dplyr::summarise | groupby.agg  | combine,groupby |

## Combine dataframes or tables

| Features 	                               |  RedAmber 	                    | Tidyverse          | pandas  | DataFrames.jl |
|---                                       |---                             |---                 |---      |---            |
| Combine additional columns               | merge, bind_cols               | dplyr::bind_cols   | concat  | combine       |
| Combine additional rows 	                | concatenate, concat, bind_rows |	dplyr::bind_rows 	 | concat  | transform     |
| Join right to left, leaving only the matching rows| inner_join, join      | dplyr::inner_join  | merge   | innerjoin     |
| Join right to left, leaving all rows     | full_join, outer_join, join 	  | dplyr::full_join   | merge   | outerjoin     |
| Join matching values to left from right  | left_join, join                |	dplyr::left_join 	 | merge   | leftjoin      |
| Join matching values from left to right  | right_join, join               |	dplyr::right_join  | merge   | rightjoin     |
| Return rows of left that have a match in right | semi_join, join 	        | dplyr::semi_join 	 | [isin]  | semijoin      |
| Return rows of left that do not have a match in right | anti_join, join   |	dplyr::anti_join 	 | [isin]  | antijoin      |
| Collect rows that appear in left or right | union 	                       | dplyr::union       | merge   |               |
| Collect rows that appear in both left and right | intersect 	             | dplyr::intersect 	 | merge   |               |
| Collect rows that appear in left but not right | difference, setdiff      | dplyr::setdiff 	   | merge   |               |
