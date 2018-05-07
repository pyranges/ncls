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
