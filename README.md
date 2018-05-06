# Nested containment list

Much faster than intervaltrees? Paper claims so: https://academic.oup.com/bioinformatics/article/23/11/1386/199545 GenomicRanges uses it.

## Develop

```bash
gcc -D=BUILD_C_LIBRARY intervaldb.c -o intervaldb; ./intervaldb
```

## Timings

NCLS of 10^7 values took one second to build! 10^8: one minute! Wow!
