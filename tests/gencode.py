import pandas as pd
from ncls import NCLS

d = pd.read_table("../gencode.v28.annotation.gtf.gz", usecols=[0, 3, 4], header=None, comment="#", names="Chromosome Start End".split(),  dtype={"Chromosome": "category"})

d = d[d.Chromosome == "chr1"]

n = NCLS(d.Start.values, d.End.values, d.index.values)

print(n)
