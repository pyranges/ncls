
cdef extern from "string.h":
  ctypedef int size_t
  void *memcpy(void *dst,void *src,size_t len)
  void *memmove(void *dst,void *src,size_t len)
  void *memset(void *b,int c,size_t len)

cdef extern from "stdlib.h":
  void free(void *)
  void *malloc(size_t)
  void *calloc(size_t,size_t)
  void *realloc(void *,size_t)
  int c_abs "abs" (int)
  void qsort(void *base, size_t nmemb, size_t size,
             int (*compar)(void *,void *))

cdef extern from "stdio.h":
  ctypedef struct FILE:
    pass
  FILE *fopen(char *,char *)
  int fclose(FILE *)
  int sscanf(char *str,char *fmt,...)
  int sprintf(char *str,char *fmt,...)
  int fprintf(FILE *ifile,char *fmt,...)
  char *fgets(char *str,int size,FILE *ifile)

cdef extern from "string.h":
  int strcmp(char *s1, char *s2)
  int strncmp(char *s1,char *s2,size_t len)
  char *strcpy(char *dest,char *src)
  char *strdup(char *)
  char *strcat(char *,char *)



cdef extern from "src/intervaldb.h":
    ctypedef struct IntervalMap:
        int start
        int end
        int target_id
        int target_start
        int target_end
        int sublist

    ctypedef struct IntervalIterator:
        pass

    ctypedef struct SublistHeader:
        int start
        int len

    int imstart_qsort_cmp(void *void_a,void *void_b)
    int target_qsort_cmp(void *void_a,void *void_b)
    IntervalMap *read_intervals(int n,FILE *ifile) except NULL
    SublistHeader *build_nested_list(IntervalMap im[],int n,int *p_n,int *p_nlists) except NULL
    SublistHeader *build_nested_list_inplace(IntervalMap im[],int n,int *p_n,int *p_nlists) except NULL
    IntervalMap *interval_map_alloc(int n) except NULL
    IntervalIterator *interval_iterator_alloc() except NULL
    int free_interval_iterator(IntervalIterator *it)
    IntervalIterator *reset_interval_iterator(IntervalIterator *it)
    int find_intervals(IntervalIterator *it0,
                       int start,
                       int end,
                       IntervalMap im[],
                       int n,
                       SublistHeader subheader[],
                       int nlists,
                       IntervalMap buf[],
                       int nbuf,
                       int *p_nreturn,
                       IntervalIterator **it_return) except -1
    # char *write_binary_files(IntervalMap im[],int n,int ntop,int div,SublistHeader *subheader,int nlists,char filestem[])
    # IntervalDBFile *read_binary_files(char filestem[],char err_msg[],int subheader_nblock) except NULL
    # int free_interval_dbfile(IntervalDBFile *db_file)
    # int find_file_intervals(IntervalIterator *it0,int start,int end,IntervalIndex ii[],int nii,SublistHeader subheader[],int nlists,SubheaderFile *subheader_file,int ntop,int div,FILE *ifile,IntervalMap buf[],int nbuf,int *p_nreturn,IntervalIterator **it_return) except -1
    # int write_padded_binary(IntervalMap im[],int n,int div,FILE *ifile)
    # int read_imdiv(FILE *ifile,IntervalMap imdiv[],int div,int i_div,int ntop)
    # int save_text_file(char filestem[],char basestem[],char err_msg[],FILE *ofile)
    # int text_file_to_binaries(FILE *infile,char buildpath[],char err_msg[])
    # int C_int_max


cdef class NCLS:
    cdef int n
    cdef int ntop
    cdef int nlists
    cdef IntervalMap *im
    cdef SublistHeader *subheader
