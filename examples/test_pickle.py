

from ncls import NCLS

import pickle
import pandas as pd
import numpy as np

starts = pd.Series(range(0, int(1e2)))
ends = starts + 100
ids = starts

ncls = NCLS(starts.values, ends.values, ids.values)

for i in ncls.find_overlap(0, 2):
    print(i)

pickle.dump(ncls, open("test.pckl", "wb"))



import pickle

ncls2 = pickle.load(open("test.pckl", "rb"))


for i in ncls2.find_overlap(0, 2):
    print(i)
