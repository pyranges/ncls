
cdef extern from "src/intervaldb.h":
    ctypedef struct IntervalMap:
        int start
        int end
        int target_id
        int target_start
        int target_end
        int sublist


    int imstart_qsort_cmp(void *void_a,void *void_b)
    int target_qsort_cmp(void *void_a,void *void_b)
    IntervalMap *read_intervals(int n,FILE *ifile) except NULL
    SublistHeader *build_nested_list(IntervalMap im[],int n,int *p_n,int *p_nlists) except NULL
    SublistHeader *build_nested_list_inplace(IntervalMap im[],int n,int *p_n,int *p_nlists) except NULL
    IntervalMap *interval_map_alloc(int n) except NULL
    IntervalIterator *interval_iterator_alloc() except NULL
    int free_interval_iterator(IntervalIterator *it)
    IntervalIterator *reset_interval_iterator(IntervalIterator *it)
    int find_intervals(IntervalIterator *it0,int start,int end,IntervalMap im[],int n,SublistHeader subheader[],int nlists,IntervalMap buf[],int nbuf,int *p_nreturn,IntervalIterator **it_return) except -1
    char *write_binary_files(IntervalMap im[],int n,int ntop,int div,SublistHeader *subheader,int nlists,char filestem[])
    IntervalDBFile *read_binary_files(char filestem[],char err_msg[],int subheader_nblock) except NULL
    int free_interval_dbfile(IntervalDBFile *db_file)
    int find_file_intervals(IntervalIterator *it0,int start,int end,IntervalIndex ii[],int nii,SublistHeader subheader[],int nlists,SubheaderFile *subheader_file,int ntop,int div,FILE *ifile,IntervalMap buf[],int nbuf,int *p_nreturn,IntervalIterator **it_return) except -1
    int write_padded_binary(IntervalMap im[],int n,int div,FILE *ifile)
    int read_imdiv(FILE *ifile,IntervalMap imdiv[],int div,int i_div,int ntop)
    int save_text_file(char filestem[],char basestem[],char err_msg[],FILE *ofile)
    int text_file_to_binaries(FILE *infile,char buildpath[],char err_msg[])
    int C_int_max

    ctypedef struct SublistHeader:
        int start
        int len


cdef class NCLS:
    cdef int n
    cdef int ntop
    cdef int nlists
    cdef IntervalMap *im
    cdef SublistHeader *subheader
