# @markup markdown

# Comparison of DataFrames

Compare basic features of RedAmber with Python 
[Pandas](https://pandas.pydata.org/),
R [Tidyverse](https://www.tidyverse.org/) and
Julia [Dataframes](https://dataframes.juliadata.org/stable/).

## Select columns (variables)

| Features                        |	RedAmber        |	Tidyverse 	                     | Pandas                                 | DataFrames.jl     |
|---                              |---              |---                              |---                                     |---                |
| Select columns as a dataframe   |	pick, drop, [] 	| dplyr::select, dplyr::select_if | [], loc[], iloc[], drop, select_dtypes | [], select        |
| Select a column as a vector     | 	[], v 	        | dplyr::pull, [, x]	             | [], loc[], iloc[]                      | [!, :x]           |
| Move columns to a new position  |	pick, [] 	      | relocate                        | [], reindex, loc[], iloc[]             | select,transform  |

## Select rows (records, observations)

| Features                                              |	RedAmber 	        | Tidyverse                   | Pandas                   | DataFrames.jl |
|---                                                    |---                |---                          |---                       |---            |
| Select rows that meet logical criteria as a dataframe |	slice, remove, [] | 	dplyr::filter              |	[], filter, query, loc[] | filter        |
| Select rows by position as a dataframe 	              | slice, remove, [] | dplyr::slice 	              | iloc[], drop             | subset        |
| Move rows to a new position 	                         | slice, [] 	       | dplyr::filter, dplyr::slice |	reindex, loc[], iloc[]   | permute       |

## Update columns / create new columns

|Features 	                         | RedAmber 	          | Tidyverse 	                                        | Pandas            | DataFrames.jl |
|---                                |---                  |---                                                 |---                |---            |
| Update existing columns           |	assign 	            | dplyr::mutate                                     	| assign, []=       | mapcols       |
| Create new columns 	              | assign, assign_left |	dplyr::mutate 	                                    | apply             | insertcols,.+ |
| Compute new columns, drop others 	| new 	               | transmute 	                                        | (dfply:)transmute | transform,insertcols,mapcols |
| Rename columns 	                  | rename              |	dplyr::rename, dplyr::rename_with, purrr::set_names |	rename, set_axis  | rename        |
| Sort dataframe 	                  | sort 	              | dplyr::arrange 	                                    | sort_values       | sort          |

## Reshape dataframe

| Features 	                                           | RedAmber 	| Tidyverse 	         | Pandas       | DataFrames.jl |
|---                                                   |---        |---                  |---           |---            |
| Gather columns into rows (create a longer dataframe) |	to_long 	 | tidyr::pivot_longer |	melt         | stack         |
| Spread rows into columns (create a wider dataframe)  | to_wide 	 | tidyr::pivot_wider 	| pivot        | unstack       |
| transpose a wide dataframe 	                         | transpose | transpose, t 	      | transpose, T | permutedims   |

## Grouping

| Features | RedAmber 	              | Tidyverse 	                          | Pandas       | DataFrames.jl   |
|---       |---                      |---                                   |---           |---              |
|Grouping 	| group, group.summarize 	| dplyr::group_by %>% dplyr::summarise | groupby.agg  | combine,groupby |

## Combine dataframes or tables

| Features 	                               |  RedAmber 	                    | Tidyverse          | Pandas  | DataFrames.jl |
|---                                       |---                             |---                 |---      |---            |
| Combine additional columns               | merge, bind_cols               | dplyr::bind_cols   | concat  | combine       |
| Combine additional rows 	                | concatenate, concat, bind_rows |	dplyr::bind_rows 	 | concat  | transform     |
| Inner join                               | join, inner_join 	             | dplyr::inner_join  | merge   | innerjoin     |
| Full join                                | join, full_join, outer_join 	  | dplyr::full_join   | merge   | outerjoin     |
| Left join 	                              | join, left_join                |	dplyr::left_join 	 | merge   | leftjoin      |
| Right join                               | join, right_join               |	dplyr::right_join  | merge   | rightjoin     |
| Semi join 	                              | join, semi_join 	              | dplyr::semi_join 	 | [isin]  | semijoin      |
| Anti join 	                              | join, anti_join                |	dplyr::anti_join 	 | [isin]  | antijoin      |
| Collect rows that appear in x or y       | union 	                        | dplyr::union       | merge   |               |
| Collect rows that appear in both x and y | intersect 	                    | dplyr::intersect 	 | merge   |               |
| Collect rows that appear in x but not y  | difference, setdiff 	          | dplyr::setdiff 	   | merge   |               |

 

