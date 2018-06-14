


from ncls import NCLS

import pickle
import pandas as pd
import numpy as np


starts = np.array(list(reversed([3, 5, 8])), dtype=np.long)
ends = np.array(list(reversed([6, 7, 9])), dtype=np.long)
indexes = np.array(list(reversed([0, 1, 2])), dtype=np.long)

# starts = np.array([3, 5, 8], dtype=np.long)
# ends = np.array([6, 7, 9], dtype=np.long)
# indexes = np.array([0, 1, 2], dtype=np.long)

ncls = NCLS(starts, ends, indexes)

starts2 = np.array([1, 6])
ends2 = np.array([10, 7])
indexes2 = np.array([0, 1])

print(ncls.all_overlaps_both(starts2, ends2, indexes2))
