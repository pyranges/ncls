
from ncls import NCLS

from numpy.random import randint
import numpy as np

import pandas as pd

from joblib import Parallel, delayed


def create_ncls(seed):

    np.random.seed(seed)

    total_nb = int(1e7)

    starts = randint(0, int(1e8), total_nb)
    ends = starts + 100

    ncls = NCLS(starts, ends, starts)

    return ncls

nclses = Parallel(n_jobs=5)(delayed(create_ncls)(i) for i in randint(0, int(1e8), 5))

for j, ncls in enumerate(nclses):
    for i in ncls.find_overlap(0, 100):
        print(j, i)
