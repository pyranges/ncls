cimport cython

cimport src.cncls as cn

cdef class NCLSIterator:

    cdef cn.IntervalIterator *it
    cdef cn.IntervalIterator *it_alloc
    cdef cn.IntervalMap im_buf[1024]
    cdef int nhit, start, end, ihit
    cdef NCLS db

    def __cinit__(self, int start, int end, NCLS db not None):
        self.it = cn.interval_iterator_alloc()
        self.it_alloc = self.it
        self.start = start
        self.end = end
        self.db = db
        self.nhit = 0
        self.ihit = 0


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
        # print("After second if (should never print)")


    # PYTHON VERSION OF next RETURNS HIT AS A TUPLE
    def __next__(self): # PYREX USES THIS NON-STANDARD NAME INSTEAD OF next()!!!
        cdef int i
        i = self.cnext()
        if i >= 0:
            return (self.im_buf[i].start, self.im_buf[i].end, self.im_buf[i].target_id)
                    # self.im_buf[i].target_start, self.im_buf[i].target_end)
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
    cdef int n, ntop
    cdef int nlists

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
            self.im[i].target_start = starts[i]
            self.im[i].target_end = ends[i]
            self.im[i].sublist = -1
            i = i + 1

        self.subheader = cn.build_nested_list(self.im, self.n, &(self.ntop), &(self.nlists))


    def find_overlap(self, int start, int end):
        self.check_nonempty() # RAISE EXCEPTION IF NO DATA
        return NCLSIterator(start, end, self)


    def find_overlap_list(self, int start, int end):
        cdef int i = 0
        cdef int nhit = 0

        cdef cn.IntervalIterator *it
        cdef cn.IntervalIterator *it_alloc
        cdef cn.IntervalMap im_buf[1024]
        self.check_nonempty() # RAISE EXCEPTION IF NO DATA
        it = cn.interval_iterator_alloc()
        # it_alloc = it
        l = [] # LIST OF RESULTS TO HAND BACK
        while it:
            cn.find_intervals(it, start, end, self.im, self.ntop,
                        self.subheader, self.nlists, im_buf, 1024,
                        &(nhit), &(it)) # GET NEXT BUFFER CHUNK

            print("number hits", nhit)
            while i < nhit:

                l.append((im_buf[i].start, im_buf[i].end, im_buf[i].target_id))
                i += 1

        cn.free_interval_iterator(it)
        return l


    def __dealloc__(self):
        'remember: dealloc cannot call other methods!'
        if self.subheader:
            cn.free(self.subheader)
        if self.im:
            cn.free(self.im)

    def close(self):
        if self.subheader:
            cn.free(self.subheader)
        if self.im:
            cn.free(self.im)
            self.subheader = NULL
            self.im = NULL

        return None

    def check_nonempty(self):
        if self.im:
            return True
        else:
            msg = 'empty NCLS, not searchable!'
        raise IndexError(msg)
