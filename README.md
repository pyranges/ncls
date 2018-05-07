# Nested containment list

A datastructure that uses < half a percent of the build time of the extremely fast interval trees found in the linux kernel! Queries also much much faster.

Paper: https://academic.oup.com/bioinformatics/article/23/11/1386/199545

GenomicRanges uses it.

## Develop

Test in C:

```bash
gcc -D=BUILD_C_LIBRARY intervaldb.c -o intervaldb; ./intervaldb
```

Python:

```bash
python setup.py build_ext --inplace; python test.py
```

## Timings

NCLS of 10^7 values took one second to build! 10^8: one minute! Wow!
