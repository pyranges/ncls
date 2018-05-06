
cdef class NCLS:

    # build NCLS from array of starts, ends, values
    def __cinit__(self, long [::1] starts, long [::1] ends, long[::1] ids):

        cdef int i
        self.close() # DUMP OUR EXISTING MEMORY
        self.n = len(l)
        self.im = interval_map_alloc(self.n)
        if self.im == NULL:
        raise MemoryError('unable to allocate IntervalMap[%d]' % self.n)
    i = 0
        for t in l:
            self.im[i].start = t[0]
            self.im[i].end = t[1]
            self.im[i].target_id = t[2]
            self.im[i].target_start = t[3]
            self.im[i].target_end = t[4]
            self.im[i].sublist = -1
            i = i + 1
            self.runBuildMethod(**kwargs)


    # def __cinit__(self, filename='noname', nsize=0, **kwargs):
    #     cdef int i
    #     cdef FILE *ifile
    #     self.n = nsize
    #     if nsize > 0:
    #     ifile = fopen(filename, "r") # text file, one interval per line
    #     if ifile:
    #         self.im = read_intervals(self.n, ifile)
    #         fclose(ifile)
    #         if self.im != NULL:
    #         self.runBuildMethod(**kwargs)
    #     else:
    #         msg = 'could not open file %s' % filename
    #         raise IOError(msg)

    def save_tuples(self, l, **kwargs):
        'build in-memory NLMSA from list of alignment tuples'
        cdef int i
        self.close() # DUMP OUR EXISTING MEMORY
        self.n = len(l)
        self.im = interval_map_alloc(self.n)
        if self.im == NULL:
        raise MemoryError('unable to allocate IntervalMap[%d]' % self.n)
        i = 0
        for t in l:
        self.im[i].start = t[0]
        self.im[i].end = t[1]
        self.im[i].target_id = t[2]
        self.im[i].target_start = t[3]
        self.im[i].target_end = t[4]
        self.im[i].sublist = -1
        i = i + 1
        self.runBuildMethod(**kwargs)
