# import numpy as cnp
import sys


cimport cython

from libc.stdint cimport int32_t, int64_t
# from cython.stdint import int32

cimport ncls.src.cncls32 as cn

from libc.stdlib cimport malloc
import numpy as np

cdef inline int int_max(int a, int b): return a if a >= b else b
cdef inline int int_min(int a, int b): return a if a <= b else b
# cdef inline int overlap(int a_start, int a_end, int b_start, b_end): int_max(0, int_min(a_end, b_end) - int_max(a_start, b_start))
# import ctypes as c

try:
    dummy = profile
except:
    profile = lambda x: x

cdef class NCLS32:

    cdef cn.SublistHeader *subheader
    cdef cn.IntervalMap *im
    cdef int n, ntop
    cdef int nlists

    # build NCLS from array of starts, ends, values
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.initializedcheck(False)
    def __cinit__(self, const int32_t [::1] starts=None, const int32_t [::1] ends=None, const int64_t [::1] ids=None):

        if None in (starts, ends, ids):
            return

        if len(starts) == 0 or len(ends) == 0 or len(ids) == 0:
            return

        cdef int i
        cdef length = len(starts)
        self.close() # DUMP OUR EXISTING MEMORY
        self.n = len(starts)
        self.im = cn.interval_map_alloc(self.n)
        if self.im == NULL:
            raise MemoryError('unable to allocate IntervalMap[%d]' % self.n)
        i = 0
        for i in range(length):
            self.im[i].start = starts[i]
            self.im[i].end = ends[i]
            self.im[i].target_id = ids[i]
            self.im[i].sublist = -1

        self.subheader = cn.build_nested_list(self.im, self.n, &(self.ntop), &(self.nlists))

    def intervals(self, take=None):
        intervals = []

        cdef int i = 0
        cdef int _take = int(take) if not take is None else len(self)
        if not self.im: # if empty
            return []

        for i in range(_take):
            intervals.append((self.im[i].start, self.im[i].end, self.im[i].target_id))

        return intervals

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.initializedcheck(False)
    cpdef all_overlaps_both(self, const int32_t [::1] starts, const int32_t [::1] ends, const int64_t [::1] indexes):

        cdef int i = 0
        cdef int nhit = 0
        cdef int length = len(starts)
        cdef int loop_counter = 0
        cdef int nfound = 0

        output_arr = np.zeros(length, dtype=long)
        output_arr_other = np.zeros(length, dtype=long)
        cdef long [::1] output
        cdef long [::1] output_other

        output = output_arr
        output_other = output_arr_other

        cdef cn.IntervalIterator *it
        cdef cn.IntervalIterator *it_alloc

        cdef cn.IntervalMap im_buf[1024]
        if not self.im: # if empty
            return [], []

        it_alloc = cn.interval_iterator_alloc()
        it = it_alloc
        for loop_counter in range(length):

            # remember first pointer for dealloc
            while it:
                i = 0
                cn.find_intervals(it, starts[loop_counter], ends[loop_counter], self.im, self.ntop,
                                self.subheader, self.nlists, im_buf, 1024,
                                &(nhit), &(it)) # GET NEXT BUFFER CHUNK

                # print("nhit", nhit)
                # print("length", length)
                # print("nfound", nfound)
                # print(nfound + nhit >= length)
                if nfound + nhit >= length:

                    length = (length + nhit) * 2
                    output_arr = np.resize(output_arr, length)
                    output_arr_other = np.resize(output_arr_other, length)
                    output = output_arr
                    output_other = output_arr_other

                while i < nhit:

                    # print("length", length)
                    # print("nfound", nfound)
                    # print("loop_counter", loop_counter)
                    output[nfound] = indexes[loop_counter]
                    output_other[nfound] = im_buf[i].target_id

                    nfound += 1
                    i += 1

            cn.reset_interval_iterator(it_alloc)
            it = it_alloc

        cn.free_interval_iterator(it_alloc)

        return output_arr[:nfound], output_arr_other[:nfound]


    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.initializedcheck(False)
    cpdef k_overlaps_both(self, const int32_t [::1] starts, const int32_t [::1] ends, const int64_t [::1] indexes, int k):

        cdef int i = 0
        cdef int nhit = 0
        cdef int length = len(starts)
        cdef int loop_counter = 0
        cdef int nfound = 0

        output_arr = np.zeros(length, dtype=long)
        output_arr_other = np.zeros(length, dtype=long)
        cdef long [::1] output
        cdef long [::1] output_other

        output = output_arr
        output_other = output_arr_other

        cdef cn.IntervalIterator *it
        cdef cn.IntervalIterator *it_alloc

        cdef cn.IntervalMap im_buf[1024]
        if not self.im: # if empty
            return [], []

        it_alloc = cn.interval_iterator_alloc()
        it = it_alloc
        for loop_counter in range(length):

            # remember first pointer for dealloc
            while it:
                i = 0
                cn.find_intervals(it, starts[loop_counter], ends[loop_counter], self.im, self.ntop,
                                self.subheader, self.nlists, im_buf, 1024,
                                &(nhit), &(it)) # GET NEXT BUFFER CHUNK

                # print("nhit", nhit)
                # print("length", length)
                # print("nfound", nfound)
                # print(nfound + nhit >= length)
                if nfound + nhit >= length:

                    length = (length + nhit) * 2
                    output_arr = np.resize(output_arr, length)
                    output_arr_other = np.resize(output_arr_other, length)
                    output = output_arr
                    output_other = output_arr_other

                if k < nhit:
                    nhit = k

                while i < nhit:

                    # print("length", length)
                    # print("nfound", nfound)
                    # print("loop_counter", loop_counter)
                    output[nfound] = indexes[loop_counter]
                    output_other[nfound] = im_buf[i].target_id

                    nfound += 1
                    i += 1

            cn.reset_interval_iterator(it_alloc)
            it = it_alloc

        cn.free_interval_iterator(it_alloc)

        return output_arr[:nfound], output_arr_other[:nfound]



    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.initializedcheck(False)
    cpdef all_overlaps_self(self, const int32_t [::1] starts, const int32_t [::1] ends, const int64_t [::1] indexes):

        cdef int i
        cdef int nhit = 0
        cdef int length = len(starts)
        cdef int loop_counter = 0
        cdef int nfound = 0

        output_arr = np.zeros(length, dtype=long)
        cdef long [::1] output

        output = output_arr

        cdef cn.IntervalIterator *it
        cdef cn.IntervalIterator *it_alloc

        cdef cn.IntervalMap im_buf[1024]
        if not self.im: # if empty
            return [], []

        it_alloc = cn.interval_iterator_alloc()
        it = it_alloc
        for loop_counter in range(length):

            # remember first pointer for dealloc

            while it:
                i = 0
                cn.find_intervals(it, starts[loop_counter], ends[loop_counter], self.im, self.ntop,
                                self.subheader, self.nlists, im_buf, 1024,
                                &(nhit), &(it)) # GET NEXT BUFFER CHUNK

                if nfound + nhit >= length:

                    length = (length + nhit) * 2
                    output_arr = np.resize(output_arr, length)
                    output = output_arr

                for i in range(nhit):

                    output[nfound] = indexes[loop_counter]

                    nfound += 1

            cn.reset_interval_iterator(it_alloc)
            it = it_alloc

        cn.free_interval_iterator(it_alloc)

        return output_arr[:nfound]


    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.initializedcheck(False)
    cpdef coverage(self, const int32_t [::1] starts, const int32_t [::1] ends, const int64_t [::1] indexes):

        # assumes the ncls to not contain any overlapping intervals

        cdef int i = 0
        cdef int start = 0
        cdef int end = 0
        cdef int other_start = 0
        cdef int other_end = 0
        cdef int nhit = 0
        cdef int length = len(starts)
        cdef int loop_counter = 0
        cdef int nfound = 0

        # output_arr = np.zeros(length, dtype=long)
        output_arr_length = np.zeros(length, dtype=long)
        # cdef long [::1] output
        cdef long [::1] output_length

        # output = output_arr
        output_length = output_arr_length

        cdef cn.IntervalIterator *it
        cdef cn.IntervalIterator *it_alloc

        cdef cn.IntervalMap im_buf[1024]
        if not self.im: # if empty
            return [], []

        it_alloc = cn.interval_iterator_alloc()
        it = it_alloc
        for loop_counter in range(length):

            start = starts[loop_counter]
            end = ends[loop_counter]
            # remember first pointer for dealloc
            while it:
                i = 0
                cn.find_intervals(it, starts[loop_counter], ends[loop_counter], self.im, self.ntop,
                                self.subheader, self.nlists, im_buf, 1024,
                                &(nhit), &(it)) # GET NEXT BUFFER CHUNK

                while i < nhit:
                    output_length[loop_counter] += int_min(im_buf[i].end, end) - int_max(im_buf[i].start, start)
                    i += 1


            cn.reset_interval_iterator(it_alloc)
            it = it_alloc

        cn.free_interval_iterator(it_alloc)

        return output_arr_length

    def __len__(self):
        return self.n

    def __str__(self):

        contents = ["Number intervals:", self.n, "Number of intervals in main list:", self.ntop, "Number of intervals with subintervals:", self.nlists, "Percentage in top-level interval", self.ntop/float(self.n)]
        return "NCLS32\n------\n" + "\n".join(str(c) for c in contents)

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

    def find_overlap(self, int32_t start, int32_t end):
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
    @cython.initializedcheck(False)
    cpdef set_difference_helper(self, const int32_t [::1] starts, const int32_t [::1] ends, const int64_t [::1] indexes):

        cdef int i
        cdef int nhit = 0
        cdef int nfound = 0
        cdef int nstart = 0
        cdef int nend = 0
        cdef int length = len(starts)
        cdef int loop_counter = 0
        cdef int overlap_type_nb = 0
        cdef int na = -1


        output_arr = np.zeros(length, dtype=np.int64)
        output_arr_start = np.zeros(length, dtype=np.int32)
        output_arr_end = np.zeros(length, dtype=np.int32)
        cdef long [::1] output
        cdef int32_t [::1] output_start
        cdef int32_t [::1] output_end

        output = output_arr
        output_start = output_arr_start
        output_end = output_arr_end

        cdef cn.IntervalIterator *it
        cdef cn.IntervalIterator *it_alloc
        cdef cn.IntervalMap im_buf[1024]
        if not self.im: # if empty
            return [], [], []


        it_alloc = cn.interval_iterator_alloc()
        it = it_alloc
        for loop_counter in range(length):

            while it:
                i = 0
                cn.find_intervals(it, starts[loop_counter], ends[loop_counter], self.im, self.ntop,
                                self.subheader, self.nlists, im_buf, 1024,
                                &(nhit), &(it)) # GET NEXT BUFFER CHUNK

                #print("nhits:", nhit)

                nstart = starts[loop_counter]
                nend = ends[loop_counter]

                # print("nstart", nstart)
                # print("nend", nend)

                if nfound + nhit >= length:

                    length = length * 2
                    output_arr = np.resize(output_arr, length)
                    output_arr_start = np.resize(output_arr_start, length)
                    output = output_arr
                    output_start = output_arr_start
                    output_arr_end = np.resize(output_arr_end, length)
                    output_end = output_arr_end

                # B covers whole of A; ignore
                if nhit == 1 and starts[loop_counter] > im_buf[i].start and ends[loop_counter] < im_buf[i].end:
                    # print("ignore me!")
                    output_start[nfound] = -1
                    output_end[nfound] = -1
                    output[nfound] = indexes[loop_counter]
                    i = nhit
                    nfound += 1

                while i < nhit:
                    # print("--- i:", i)
                    # print("--- im_buf[i]", im_buf[i])
                    #print("  B start:", im_buf[i].start)
                    #print("  B end:", im_buf[i].end)

                    # in case the start contributes nothing
                    if i < nhit - 1:
                        # print("  i < nhit - 1")

                        if nstart < im_buf[i].start:
                            #print("  new_start", nstart)
                            #print("  new_end", im_buf[i].start)
                            output[nfound] = indexes[loop_counter]
                            output_start[nfound] = nstart
                            output_end[nfound] = im_buf[i].start
                            nfound += 1

                        nstart = im_buf[i].end
                    elif i == nhit - 1:

                        # print("i == nhit -1")
                        #print("im_buf[i].start", im_buf[i].start)
                        #print("im_buf[i].end", im_buf[i].end)
                        #print("nstart", nstart)
                        #print("ends[loop_counter]", ends[loop_counter])

                        if im_buf[i].start <= nstart and im_buf[i].end >= ends[loop_counter]:
                            # print("im_buf[i].start <= nstart and im_buf[i].end >= ends[loop_counter]")
                            #print("we are here " * 10)

                            output_start[nfound] = -1
                            output_end[nfound] = -1
                            output[nfound] = indexes[loop_counter]
                            nfound += 1
                        else:
                            if im_buf[i].start > nstart:
                                # print("im_buf[i].start > nstart", im_buf[i].start, nstart)
                                output[nfound] = indexes[loop_counter]
                                output_start[nfound] = nstart
                                output_end[nfound] = im_buf[i].start
                                nfound += 1

                            if im_buf[i].end < ends[loop_counter]:
                                # print("im_buf[i].end < ends[loop_counter]", im_buf[i].end, ends[loop_counter])
                                # print("i, loop_counter", i, loop_counter)
                                # print("indexes[loop_counter]", indexes[loop_counter])
                                # print("indexes", indexes[loop_counte  rloop_counter])

                                output[nfound] = indexes[loop_counter]
                                output_start[nfound] = im_buf[i].end
                                output_end[nfound] = ends[loop_counter]
                                nfound += 1

                    i += 1

            cn.reset_interval_iterator(it_alloc)
            it = it_alloc

        cn.free_interval_iterator(it_alloc)

        return output_arr[:nfound], output_arr_start[:nfound], output_arr_end[:nfound]


    # this one is actually slower!!!!
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.initializedcheck(False)
    cpdef first_overlap_both(self, const int32_t [::1] starts, const int32_t [::1] ends, const int64_t [::1] indexes):

        cdef int ix = 0
        cdef int length = len(starts)
        cdef int loop_counter = 0
        cdef int nfound = 0

        output_arr = np.zeros(length, dtype=np.long)
        output_arr_other = np.zeros(length, dtype=np.long)
        cdef long [::1] output
        cdef long [::1] output_other

        output = output_arr
        output_other = output_arr_other

        cdef cn.IntervalIterator *it
        cdef cn.IntervalIterator *it_alloc

        cdef cn.IntervalMap im_buf[1024]
        if not self.im: # if empty
            return [], []


        for loop_counter in range(length):

            # remember first pointer for dealloc
            ix = cn.find_overlap_start(starts[loop_counter], ends[loop_counter], self.im, self.ntop)

            if ix != -1:
                output[nfound] = indexes[loop_counter]
                output_other[nfound] = self.im[ix].target_id

                nfound += 1

        return output_arr[:nfound], output_arr_other[:nfound]


    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.initializedcheck(False)
    cpdef all_containments_both(self, const int32_t [::1] starts, const int32_t [::1] ends, const int64_t [::1] indexes):

        cdef int i
        cdef int nhit = 0
        cdef int length = len(starts)
        cdef int loop_counter = 0
        cdef int nfound = 0
        cdef int start, end

        output_arr = np.zeros(length, dtype=np.long)
        output_arr_other = np.zeros(length, dtype=np.long)
        cdef long [::1] output
        cdef long [::1] output_other

        output = output_arr
        output_other = output_arr_other

        cdef cn.IntervalIterator *it
        cdef cn.IntervalIterator *it_alloc


        cdef cn.IntervalMap im_buf[1024]
        if not self.im: # if empty
            return [], []


        it_alloc = cn.interval_iterator_alloc()
        it = it_alloc

        for loop_counter in range(length):

            start = starts[loop_counter]
            end = ends[loop_counter]
            while it:
                i = 0
                cn.find_intervals(it, start, end, self.im, self.ntop,
                                self.subheader, self.nlists, im_buf, 1024,
                                &(nhit), &(it)) # GET NEXT BUFFER CHUNK

                while i < nhit:

                    if im_buf[i].start <= start and im_buf[i].end >= end:

                        if nfound >= length:

                            length = length * 2
                            output_arr = np.resize(output_arr, length)
                            output_arr_other = np.resize(output_arr_other, length)
                            output = output_arr
                            output_other = output_arr_other

                        output[nfound] = indexes[loop_counter]
                        output_other[nfound] = im_buf[i].target_id

                        nfound += 1
                    i += 1

            cn.reset_interval_iterator(it_alloc)
            it = it_alloc

        cn.free_interval_iterator(it_alloc)

        return output_arr[:nfound], output_arr_other[:nfound]




    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.initializedcheck(False)
    cpdef has_overlaps(self, const int32_t [::1] starts, const int32_t [::1] ends, const int64_t [::1] indexes):

        cdef int i = 0
        cdef int ix = 0
        cdef int length = len(starts)
        cdef int nfound = 0

        # cdef cn.IntervalIterator *it
        cdef cn.IntervalMap im_buf[1024]
        if not self.im: # if empty
            return []

        output_arr = np.zeros(length, dtype=long)
        cdef long [::1] output
        output = output_arr

        for i in range(length):

            ix = cn.find_overlap_start(starts[i], ends[i], self.im, self.ntop)

            if ix != -1:
                output[nfound] = indexes[i]
                nfound += 1

            i += 1

        return output_arr[:nfound]



cdef class NCLSIterator:

    cdef cn.IntervalIterator *it
    cdef cn.IntervalIterator *it_alloc
    cdef cn.IntervalMap im_buf[1024]
    cdef int nhit, start, end, ihit
    cdef NCLS32 db

    def __cinit__(self, int32_t start, int32_t end, NCLS32 db not None):
        self.it = cn.interval_iterator_alloc()
        self.it_alloc = self.it
        self.start = start
        self.end = end
        self.db = db
        self.nhit = 0
        self.ihit = 0


    def __iter__(self):
        return self


    cdef int cnext(self): # c VERSION OF ITERATOR next METHOD RETURNS INDEX
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
            return (self.im_buf[i].start, self.im_buf[i].end, self.im_buf[i].target_id)
        else:
            raise StopIteration

    def __dealloc__(self):
        'remember: dealloc cannot call other methods!'
        cn.free_interval_iterator(self.it_alloc)


    def find_overlap(self, int32_t start, int32_t end):
        if not self.im:
            return []

        return NCLSIterator(start, end, self)
