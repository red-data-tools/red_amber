# DataFrames 操作メソッドの比較

RedAmberの基本的な操作メソッドを [Python pandas](https://pandas.pydata.org/),
[R Tidyverse](https://www.tidyverse.org/),
[Julia DataFrames](https://dataframes.juliadata.org/stable/) と比較します。

## 列 (variables) を選択する

| 機能                               | RedAmber        | Tidyverse (R)	                  | pandas                                 | DataFrames.jl     |
|---                                 |---              |---                              |---                                     |---                |
| 列を選択して dataframe で返す       | pick, drop, []  | dplyr::select, dplyr::select_if | [], loc[], iloc[], drop, select_dtypes | [], select        |
| 列を選択して vector で返す          | [], v	         | dplyr::pull, [, x]	           | [], loc[], iloc[]                      | [!, :x]           |
| 列の順番を入れ替えた dataframeを返す | pick, [] 	     | relocate                        | [], reindex, loc[], iloc[]             | select,transform  |

## 行 (records, observations) を選択する

| 機能                                     | RedAmber 	               | Tidyverse (R)               | pandas                   | DataFrames.jl |
|---                                       |---                        |---                          |---                       |---            |
| 論理値に従って行を選択して dataframe で返す |	slice, filter, remove, [] | dplyr::filter               | [], filter, query, loc[] | filter        |
| インデックスで行を選択して dataframe で返す | slice, remove, []         | dplyr::slice 	            | iloc[], drop             | subset        |
| 行の順番を入れ替えた dataframeを返す       | slice, [] 	             | dplyr::filter, dplyr::slice | reindex, loc[], iloc[]   | permute       |

## 列を更新する / 新しい列を作る

|機能 	                       | RedAmber 	          | Tidyverse (R)                                     | pandas            | DataFrames.jl |
|---                           |---                  |---                                                 |---                |---            |
| 既存の列の内容を変更する       | assign 	            | dplyr::mutate                                    	| assign, []=       | mapcols       |
| 新しい列を作成する 	        | assign, assign_left |	dplyr::mutate 	                                    | apply             | insertcols,.+ |
| 新しい列を作成し、残りは捨てる | new 	               | transmute 	                                         | (dfply:)transmute | transform,insertcols,mapcols |
| 列の名前を変更する            | rename              |	dplyr::rename, dplyr::rename_with, purrr::set_names | rename, set_axis  | rename        |
| dataframe をソートする        | sort 	              | dplyr::arrange 	                                    | sort_values       | sort          |

## dataframe を変形する

| 機能 	                                | RedAmber  | Tidyverse (R)       | pandas      | DataFrames.jl |
|---                                   |---        |---                  |---           |---            |
| 列を行に積む (long dataframe にする)   | to_long   | tidyr::pivot_longer | melt         | stack         |
| 行を列に集める (wide dataframe にする) | to_wide   | tidyr::pivot_wider  | pivot        | unstack       |
| wide dataframe を転置する             | transpose | transpose, t 	      | transpose, T | permutedims   |

## グループ化

| 機能         | RedAmber 	            | Tidyverse 	                       | pandas       | DataFrames.jl   |
|---           |---                     |---                                   |---           |---              |
|グループ化する | group, group.summarize | dplyr::group_by %>% dplyr::summarise | groupby.agg  | combine,groupby |

## dataframes または　tables　を結合する

| 機能 	                                  | RedAmber 	                    | Tidyverse        | pandas  | DataFrames.jl |
|---                                      |---                             |---                |---      |---            |
| 列として連結する (横方向に連結する)        | merge, bind_cols               | dplyr::bind_cols  | concat  | combine       |
| 行として連結する (縦方向に連結する)        | concatenate, concat, bind_rows |	dplyr::bind_rows  | concat  | transform     |
| 一致した行だけを連結する (内部結合)        | inner_join, join               | dplyr::inner_join | merge   | innerjoin     |
| 全ての行を残して連結する (外部結合)        | full_join, outer_join, join 	  | dplyr::full_join  | merge   | outerjoin     |
| 左の一致した値を残して連結する (左外部結合) | left_join, join                | dplyr::left_join  | merge   | leftjoin      |
| 右の一致した値を残して連結する (右外部結合) | right_join, join               | dplyr::right_join | merge   | rightjoin     |
| 左の行のうち、右と一致したものを返す        | semi_join, join 	          | dplyr::semi_join  | [isin]  | semijoin      |
| 左の行のうち、右と一致しなかったものを返す  | anti_join, join                | dplyr::anti_join  | [isin]  | antijoin      |
| 左か右のどちらかに現れる行を返す           | union 	                      | dplyr::union      | merge   |               |
| 左とみごの両方に現れる行を返す             | intersect 	                  | dplyr::intersect  | merge   |               |
| 左にはあるが右にはない行を返す             | difference, setdiff            | dplyr::setdiff 	  | merge   |               |
