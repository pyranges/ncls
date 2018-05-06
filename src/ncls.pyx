cimport src.cncls as cn

cdef class NCLSIterator:

    cdef cn.IntervalIterator *it
    cdef cn.IntervalIterator *it_alloc
    cdef cn.IntervalMap *im_buf
    cdef int nhit
    cdef NCLS db

    def __cinit__(self, int start, int end, NCLS db not None):
        self.it = cn.interval_iterator_alloc()
        self.it_alloc = self.it
        self.start = start
        self.end = end
        self.db = db


    def __iter__(self):
        return self


    cdef int cnext(self): # C VERSION OF ITERATOR next METHOD RETURNS INDEX
        cdef int i
        if self.ihit >= self.nhit: # TRY TO GET ONE MORE BUFFER CHUNK OF HITS
            if self.it == NULL: # ITERATOR IS EXHAUSTED
                return -1
            cn.find_intervals(self.it, self.start, self.end, self.db.im, self.db.ntop,
                           self.db.subheader, self.db.nlists, self.im_buf, 1024,
                           &(self.nhit), &(self.it)) # GET NEXT BUFFER CHUNK
            self.ihit = 0 # START ITERATING FROM START OF BUFFER
        if self.ihit < self.nhit: # RETURN NEXT ITEM FROM BUFFER
            i = self.ihit
            self.ihit = self.ihit + 1 # ADVANCE THE BUFFER COUNTER
            return i
        else: # BUFFER WAS EMPTY, NO HITS TO ITERATE OVER...
            return -1


    # PYTHON VERSION OF next RETURNS HIT AS A TUPLE
    def __next__(self): # PYREX USES THIS NON-STANDARD NAME INSTEAD OF next()!!!
        cdef int i
        i = self.cnext()
        if i >= 0:
            return (self.im_buf[i].start, self.im_buf[i].end, self.im_buf[i].target_id,
                    self.im_buf[i].target_start, self.im_buf[i].target_end)
        else:
            raise StopIteration

    def __dealloc__(self):
        'remember: dealloc cannot call other methods!'
        cn.free_interval_iterator(self.it_alloc)


    def find_overlap(self, int start, int end):
        self.check_nonempty() # RAISE EXCEPTION IF NO DATA
        return NCLSIterator(start, end, self)

cdef class NCLS:

    cdef cn.SublistHeader *subheader
    cdef cn.IntervalMap *im
    cdef int n, nlists, ntop
    # build NCLS from array of starts, ends, values
    def __cinit__(self, long [::1] starts, long [::1] ends, long[::1] ids):

        cdef int i
        self.close() # DUMP OUR EXISTING MEMORY
        self.n = len(starts)
        self.im = cn.interval_map_alloc(self.n)
        if self.im == NULL:
            raise MemoryError('unable to allocate IntervalMap[%d]' % self.n)
        i = 0
        while i < len(starts):
            self.im[i].start = starts[i]
            self.im[i].end = ends[i]
            self.im[i].target_id = ids[i]
            self.im[i].target_start = 0
            self.im[i].target_end = 0
            self.im[i].sublist = -1
            i = i + 1

        cn.build_nested_list_inplace(self.im, self.n, &(self.ntop), &(self.nlists))



    def find_overlap(self, int start, int end):
        self.check_nonempty() # RAISE EXCEPTION IF NO DATA
        return NCLSIterator(start, end, self)


    def find_overlap_list(self, int start, int end):
        cdef int i, nhit
        cdef cn.IntervalIterator *it
        cdef cn.IntervalIterator *it_alloc
        cdef cn.IntervalMap im_buf[1024]
        self.check_nonempty() # RAISE EXCEPTION IF NO DATA
        it = cn.interval_iterator_alloc()
        it_alloc = it
        l = [] # LIST OF RESULTS TO HAND BACK
        while it:
            cn.find_intervals(it, start, end, self.im, self.ntop,
                        self.subheader, self.nlists, im_buf, 1024,
                        &(nhit), &(it)) # GET NEXT BUFFER CHUNK
        for i from 0 <= i < nhit:
            l.append((im_buf[i].start, im_buf[i].end, im_buf[i].target_id, im_buf[i].target_start, im_buf[i].target_end))
            cn.free_interval_iterator(it_alloc)
        return l


    def __dealloc__(self):
        'remember: dealloc cannot call other methods!'
        if self.subheader:
            cn.free(self.subheader)
        if self.im:
            cn.free(self.im)

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

    # def save_tuples(self, l, **kwargs):
    #     'build in-memory NLMSA from list of alignment tuples'
    #     cdef int i
    #     self.close() # DUMP OUR EXISTING MEMORY
    #     self.n = len(l)
    #     self.im = interval_map_alloc(self.n)
    #     if self.im == NULL:
    #         raise MemoryError('unable to allocate IntervalMap[%d]' % self.n)
    #     i = 0
    #     for t in l:
    #     self.im[i].start = t[0]
    #     self.im[i].end = t[1]
    #     self.im[i].target_id = t[2]
    #     self.im[i].target_start = t[3]
    #     self.im[i].target_end = t[4]
    #     self.im[i].sublist = -1
    #     i = i + 1
    #     self.runBuildMethod(**kwargs)
