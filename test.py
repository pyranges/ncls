# from src.ncls import NCLS
# from pyncls.src import NCLS
from src.ncls import NCLS

import numpy as np
import pandas as pd

starts = pd.Series([0, 3, 5])
ends = pd.Series([1, 12, 7])
ids = pd.Series([1, 2, 3])

ncls = NCLS(starts.values, ends.values, ids.values)

print("hullo")
it = ncls.find_overlap_list(0, 4)
print(it)
# print([o for o in ncls.find_overlap(0, 4)])
