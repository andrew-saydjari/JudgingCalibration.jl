# JudgingCalibration

[![][action-img]][action-url]
[![][codecov-img]][codecov-url]

The purpose of this package is to allow the calibration of judges scores of students in the limit of sparse sampling, where each judge sees only a few students and each student has only a few judges. This limit is common at conferences, but unfortunately makes score standardization difficult. For example, one cannot try to standardize each judge to a normal distribution since there are so few samples that a variance cannot be learned robustly. Instead, this package estimates a simple constant offset per judge, but does not rely on a mean of all of that judge's scores, which in the low sample limit, would be extraordinarily noisy. These offsets are estimated via a relative calibration comparing how different judges rate the same student, assuming that student has some fixed true score. 

## Installation

Currently, installation is directly from the GitHub

```julia
import Pkg
Pkg.add(url="https://github.com/andrew-saydjari/JudgingCalibration.jl")
```

## Example

Suppose you have a set of students whose "true" performance at some task (a poster presentation) is given by `gt` and you have some judges scores for each student. Students will be denoted with capital letters, judges with lower case letters. Note that judge `a` and `b` are overly harsh and score `-3` and `-2` below the truth, respectively. 

```julia
students = ["A","E","B","E","F","F","A","B","C","D","C","D"]
judges = ["a","a","b","b","c","d","c","d","e","e","f","f"]
scores = [1,6,3,7,7,7,4,5,8,8,8,8]
gt = [4,5,8,8,9,7];
```

Running the code to recalibrate the scores is as simple as 

```julia
df_stu, df_jud = reeval_scores(students, judges, scores);
```

and it will print some information about the number of unconnected judging blocks (disconnected subgraphs), the number of judges and students in each, and the average score given within the block. The main data product provided is the `cscores` column of `df_stu` which is the corrected mean score for that student, accounting for the learned offset per judge. The offsets for each judge are provided in `df_jud` as the `judge_offsets` column. The `judvar` column of that DataFrame is a rough estimate of the uncertainty on that offset.

In this case, accounting for the offsets corrects the rank-ordering of the students. The offsets correct for the overly hard scoring that student `E` experienced by being given judges `a` and `b`. The corrected scores also have a lower RMSE (root mean squared error) relative to the truth.

```
Block	 Judges	 Students	 Mean Score
1 	 4 	 4 		 5.0
2 	 2 	 2 		 8.0
```

Finally, you can of course save your dataframe to disk, for example as a CSV

```julia
CSV.write(fname,sort(df_stu,:cscores,rev=true))
```

<img width="0" src="https://visitor-badge.glitch.me/badge?page_id=andrew-saydjari.JudgingCalibration.jl" />

<!-- URLS -->
[action-img]: https://github.com/andrew-saydjari/JudgingCalibration.jl/workflows/CI/badge.svg
[action-url]: https://github.com/andrew-saydjari/JudgingCalibration.jl/actions

[codecov-img]: https://codecov.io/github/andrew-saydjari/JudgingCalibration.jl/coverage.svg?branch=main
[codecov-url]: https://codecov.io/github/andrew-saydjari/JudgingCalibration.jl?branch=main
