
from ncls import NCLS

import pandas as pd
import numpy as np

starts = pd.Series(range(0, int(1e7)))
ends = starts + 100
ids = starts

ncls = NCLS(starts.values, ends.values, ids.values)

ncls.write_binaries(b"hello")

ncls2 = NCLS(np.array([0]), np.array([2]), np.array([3]))

ncls2.buildFromUnsortedFile(b"hello.idb", n=int(1e7))

for i in ncls2.find_overlap(0, 500):
    print(i)
