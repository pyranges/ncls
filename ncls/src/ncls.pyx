# import numpy as np

from cpython.bytes cimport PyBytes_FromStringAndSize as to_bytes

cimport cython

cimport ncls.src.cncls as cn

# from libcpp.vector cimport vector

import numpy as np


try:
    dummy = profile
except:
    profile = lambda x: x


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
        if not self.im:
            return []

        return NCLSIterator(start, end, self)


cdef class NCLS:

    cdef cn.SublistHeader *subheader
    cdef cn.IntervalMap *im
    cdef int n, ntop
    cdef int nlists

    # build NCLS from array of starts, ends, values
    @cython.boundscheck(False)
    @cython.wraparound(False)
    def __cinit__(self, long [::1] starts=None, long [::1] ends=None, long[::1] ids=None):

        if None in (starts, ends, ids):
            return

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
        if not self.im: # RAISE EXCEPTION IF NO DATA
            return []

        return NCLSIterator(start, end, self)


    cpdef has_overlap(self, int start, int end):
        cdef int nhit = 0

        cdef cn.IntervalIterator *it
        cdef cn.IntervalMap im_buf[1024]
        if not self.im: # if empty
            return 0

        it = cn.interval_iterator_alloc()

        while it:
            cn.find_intervals(it, start, end, self.im, self.ntop,
                                self.subheader, self.nlists, im_buf, 1024,
                                &(nhit), &(it)) # GET NEXT BUFFER CHUNK

            if nhit > 0:
                cn.free_interval_iterator(it)
                return True

        cn.free_interval_iterator(it)

        return False


    @cython.boundscheck(False)
    @cython.wraparound(False)
    cpdef has_overlaps(self, long [::1] starts, long [::1] ends, long [::1] indexes):

        cdef int i = 0
        cdef int nhit = 0
        cdef int length = len(starts)

        found = []

        cdef cn.IntervalIterator *it
        cdef cn.IntervalMap im_buf[1024]
        if not self.im: # if empty
            return 0

        while i < length:

            it = cn.interval_iterator_alloc()

            while it:
                cn.find_intervals(it, starts[i], ends[i], self.im, self.ntop,
                                self.subheader, self.nlists, im_buf, 1024,
                                &(nhit), &(it)) # GET NEXT BUFFER CHUNK

                if nhit > 0:
                    cn.free_interval_iterator(it)
                    it = NULL
                    found.append(indexes[i])
                    # indexes_of_overlapping.push_back(indexes[i])

            i += 1
            cn.free_interval_iterator(it)

        return found



    cpdef find_overlap_list(self, int start, int end):
        cdef int i = 0
        cdef int nhit = 0

        cdef cn.IntervalIterator *it
        cdef cn.IntervalMap im_buf[1024]
        if not self.im: # if empty
            return []

        it = cn.interval_iterator_alloc()

        l = [] # LIST OF RESULTS TO HAND BACK
        while it:
            cn.find_intervals(it, start, end, self.im, self.ntop,
                        self.subheader, self.nlists, im_buf, 1024,
                        &(nhit), &(it)) # GET NEXT BUFFER CHUNK

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

    # cdef inline check_nonempty(self):
    #     if self.im:
    #         return True
    #     else:
    #         return False


    def __getstate__(self):

        cdef char *bp
        cdef size_t size
        cdef cn.FILE *stream

        stream = cn.open_memstream(&bp, &size)

        cn.write_padded_binary(self.im, self.n, 256, stream)
        cn.fflush(stream)

        cn.fclose(stream)

        output = to_bytes(bp, size)

        cn.free(bp)

        return (self.n, output)


    def __setstate__(self, d):

        "Takes as much time as building anew so multithreading not a speedup"

        size, bytes_ = d

        self.build_from_array(bytes_, size)


    def build_from_array(self, array, int n):

        cdef cn.FILE *stream
        cdef int i
        cdef cn.IntervalMap *im_new

        self.close()

        # http://cython.readthedocs.io/en/latest/src/tutorial/strings.html#passing-byte-strings
        cdef char* bytestr = array

        stream = cn.fmemopen(bytestr, n, "r")

        if stream == NULL:
            raise IOError('unable to read from bytearray')

        im_new = cn.interval_map_alloc(n)

        i = cn.read_imdiv(stream, im_new, n, 0, n)

        cn.fclose(stream)

        if i != n:
            raise IOError('IntervalMap file corrupted? Expected {} entries, got {}.'.format(n, i))

        self.n = n
        self.im = im_new
        self.subheader = cn.build_nested_list_inplace(self.im, self.n, &(self.ntop), &(self.nlists))



        # i = cn.read_imdiv(stream, im_new, n, 0, n)

        # cn.fclose(stream)

        # if i != n:
        #     raise IOError('IntervalMap file corrupted? Expected im of size {n} got {i}'.format(n=n, i=i))




    # def buildFromUnsortedFile(self, filename, int n, **kwargs):

    #     "This actually just reads the .idb files, not everything written by write_binaries"

    #     'load unsorted binary data, and build nested list'
    #     cdef cn.FILE *ifile
    #     cdef int i
    #     cdef cn.IntervalMap *im_new
    #     self.close()

    #     print("decoding")
    #     ifile = cn.fopen(filename,
    #                      'rb') # binary file

    #     if ifile == NULL:
    #         print("we are in ifile==NULL")
    #         raise IOError('unable to open ' + filename)

    #     im_new = cn.interval_map_alloc(n)

    #     if im_new == NULL:
    #         raise MemoryError('unable to allocate IntervalMap[%d]' % n)

    #     i = cn.read_imdiv(ifile, im_new, n, 0, n)
    #     cn.fclose(ifile)

    #     if i != n:
    #         raise IOError('IntervalMap file corrupted?')

    #     self.n = n
    #     self.im = im_new
    #     self.subheader = cn.build_nested_list_inplace(self.im, self.n, &(self.ntop), &(self.nlists))


    # def write_binaries(self, filestem, div=256):
    #     cdef char *err_msg
    #     err_msg = cn.write_binary_files(self.im, self.n, self.ntop, div,
    #                                     self.subheader, self.nlists, filestem)
    #     if err_msg:
    #         raise IOError(err_msg)
