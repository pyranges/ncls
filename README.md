# Nested containment list

A datastructure that uses < half a percent of the build time of the extremely fast interval trees found in the linux kernel! Queries also much much faster.

Paper: https://academic.oup.com/bioinformatics/article/23/11/1386/199545

## Install

```
pip install ncls==0.0.3
```

## Usage

```python
from ncls import NCLS

import pandas as pd

starts = pd.Series(range(0, 5))
ends = starts + 100
ids = starts

ncls = NCLS(starts.values, ends.values, ids.values)

it = ncls.find_overlap(0, 2)
for i in it:
    print(i)
# (0, 100, 0)
# (1, 101, 1)
```

## Timings

NCLS of 10^7 values took one second to build! 10^8: one minute! Wow!

## Citation

> Alexander V. Alekseyenko, Christopher J. Lee; Nested Containment List (NCList): a new algorithm for accelerating interval query of genome alignment and interval databases, Bioinformatics, Volume 23, Issue 11, 1 June 2007, Pages 1386–1393, https://doi.org/10.1093/bioinformatics/btl647

## Develop

Test in C:

```bash
gcc -D=BUILD_C_LIBRARY intervaldb.c -o intervaldb; ./intervaldb
```

Python:

```bash
python setup.py build_ext --inplace; python test.py
```
