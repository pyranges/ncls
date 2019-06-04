from libc.stdint cimport int32_t
# cdef extern from "string.h":
#   ctypedef int32_t size_t
#   void *memcpy(void *dst,void *src,size_t len)
#   void *memmove(void *dst,void *src,size_t len)
#   void *memset(void *b,int32_t c,size_t len)

cdef extern from "stdlib.h":
  void free(void *)
  void *malloc(size_t)
  void *calloc(size_t,size_t)
  void *realloc(void *,size_t)
  int32_t c_abs "abs" (int32_t)
  void qsort(void *base, size_t nmemb, size_t size,
             int32_t (*compar)(void *,void *))

cdef extern from "stdio.h":
  ctypedef struct FILE:
    pass

  FILE *fopen(char *,char *)
  FILE *open_memstream(void *, size_t *)
  FILE *fmemopen (void *, size_t, const char *)

  int32_t fclose(FILE *)
  int32_t fflush(FILE *)
  int32_t sscanf(char *str,char *fmt,...)
  int32_t sprintf(char *str,char *fmt,...)
  int32_t fprintf(FILE *ifile,char *fmt,...)
  char *fgets(char *str,int32_t size,FILE *ifile)

# cdef extern from "string.h":
#   int32_t strcmp(char *s1, char *s2)
#   int32_t strncmp(char *s1,char *s2,size_t len)
#   char *strcpy(char *dest,char *src)
#   char *strdup(char *)
#   char *strcat(char *,char *)


cdef extern from "ncls/src/intervaldb.h":
    ctypedef struct IntervalMap:
        int32_t start
        int32_t end
        int32_t target_id
        int32_t sublist

    ctypedef struct IntervalIterator:
        pass

    ctypedef struct SublistHeader:
        int32_t start
        int32_t len

    int32_t find_overlap_start(int32_t start, int32_t end, IntervalMap im[], int32_t n)
    int32_t imstart_qsort_cmp(void *void_a,void *void_b)
    # int32_t target_qsort_cmp(void *void_a,void *void_b)
    IntervalMap *read_intervals(int32_t n,FILE *ifile)
    SublistHeader *build_nested_list(IntervalMap im[],int32_t n,int32_t *p_n,int32_t *p_nlists)
    SublistHeader *build_nested_list_inplace(IntervalMap im[],int32_t n,int32_t *p_n,int32_t *p_nlists)
    IntervalMap *interval_map_alloc(int32_t n)
    IntervalIterator *interval_iterator_alloc()
    int32_t free_interval_iterator(IntervalIterator *it)
    IntervalIterator *reset_interval_iterator(IntervalIterator *it)
    int32_t *alloc_array(int32_t n)
    int32_t find_intervals_stack(int32_t start_stack[], int32_t end_stack[], int32_t sp, int32_t start,
                             int32_t end, IntervalMap im[], int32_t n,
                             SublistHeader subheader[], IntervalMap buf[],
                             int32_t *nfound)

    int32_t find_intervals(IntervalIterator *it0,
                       int32_t start,
                       int32_t end,
                       IntervalMap im[],
                       int32_t n,
                       SublistHeader subheader[],
                       int32_t nlists,
                       IntervalMap buf[],
                       int32_t nbuf,
                       int32_t *p_nreturn,
                       IntervalIterator **it_return)
    void find_k_next(int32_t start, int32_t end,
                    IntervalMap im[], int32_t n,
                    SublistHeader subheader[], int32_t nlists,
                    IntervalMap buf[], int32_t ktofind,
                    int32_t *p_nreturn)

    # char *write_binary_files(IntervalMap im[],int32_t n,int32_t ntop,int32_t div,SublistHeader *subheader,int32_t nlists,char filestem[])
    # IntervalDBFile *read_binary_files(char filestem[],char err_msg[],int32_t subheader_nblock) except NULL
    # int32_t free_interval_dbfile(IntervalDBFile *db_file)
    # int32_t find_file_intervals(IntervalIterator *it0,int32_t start,int32_t end,IntervalIndex ii[],int32_t nii,SublistHeader subheader[],int32_t nlists,SubheaderFile *subheader_file,int32_t ntop,int32_t div,FILE *ifile,IntervalMap buf[],int32_t nbuf,int32_t *p_nreturn,IntervalIterator **it_return) except -1
    # int32_t write_padded_binary(IntervalMap im[],int32_t n,int32_t div,FILE *ifile)

    int32_t read_imdiv(FILE *ifile,IntervalMap imdiv[],int32_t div,int32_t i_div,int32_t ntop)

    # int32_t save_text_file(char filestem[],char basestem[],char err_msg[],FILE *ofile)
    # int32_t text_file_to_binaries(FILE *infile,char buildpath[],char err_msg[])
    # int32_t C_int_max

# cdef extern from "ncls/src/utarray.h":

#     ctypedef struct UT_icd:
#         pass

#     ctypedef struct UT_array:
#         pass

#     const UT_icd ut_int_icd

#     utarray_free(UT_array *a)
#     UT_array utarray_new(UT_array *a, UT_icd *icd)
#     utarray_len(UT_array *a)
#     int32_t* utarray_eltptr(UT_array *a, int32_t j)
#     utarray_push_back(UT_array *a, void *p)


# cdef class NCLS:
#     cdef int32_t n
#     cdef int32_t ntop
#     cdef int32_t nlists
#     cdef IntervalMap *im
#     cdef SublistHeader *subheader


# cdef extern from "ncls/src/utarray.h":

#     ctypedef struct UT_icd:
#         pass

#     ctypedef struct UT_array:
#         pass

#     const UT_icd ut_int_icd

#     void utarray_new(UT_array *a, UT_icd *icd)
#     int32_t utarray_len(UT_array *a)
#     int32_t* utarray_eltptr(UT_array *a, int32_t j)
#     void utarray_push_back(UT_array *a, void *p)
#     void utarray_free(UT_array *a)
