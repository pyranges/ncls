from src.ncls import NCLS

import pandas as pd

starts = pd.Series(range(0, 5000))
ends = starts + 100
ids = starts

ncls = NCLS(starts.values, ends.values, ids.values)

it = ncls.find_overlap(0, 10000)
for i in it:
    print(i)
