from ncls.src.ncls import NCLS64
from ncls.src.ncls32 import NCLS32

import numpy as np


def NCLS(starts, ends, ids):
    if starts.dtype == np.int64:
        return NCLS64(starts, ends, ids)
    elif starts.dtype == np.int32:
        return NCLS32(starts, ends, ids)
    else:
        return NCLS32()


def NCLSD():
    return NCLS64()


from ncls.version import __version__
