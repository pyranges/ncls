# import numpy as np

from cpython.bytes cimport PyBytes_FromStringAndSize as to_bytes

cimport cython

cimport ncls.src.cncls as cn

# import ctypes as c
from array import array
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
    cpdef set_difference_helper(self, long [::1] starts, long [::1] ends, long [::1] indexes):

        cdef int i
        cdef int nhit = 0
        cdef int length = len(starts)
        cdef int loop_counter = 0
        cdef int nfound = 0
        cdef int overlap_type_nb = 0
        cdef int na = -1

        cdef cn.UT_array *idx_self
        cn.utarray_new(idx_self, &(cn.ut_int_icd))

        cdef cn.UT_array *idx_other
        cn.utarray_new(idx_other, &(cn.ut_int_icd))

        cdef cn.UT_array *overlap_type
        cn.utarray_new(overlap_type, &(cn.ut_int_icd))

        cdef cn.IntervalIterator *it
        cdef cn.IntervalMap im_buf[1024]
        if not self.im: # if empty
            return [], [], []

        while loop_counter < length:

            it = cn.interval_iterator_alloc()
            while it:
                i = 0
                cn.find_intervals(it, starts[loop_counter], ends[loop_counter], self.im, self.ntop,
                                self.subheader, self.nlists, im_buf, 1024,
                                &(nhit), &(it)) # GET NEXT BUFFER CHUNK

                while i < nhit:
                    type_0 = im_buf[i].start < starts[loop_counter]
                    type_1 = im_buf[i].end > ends[loop_counter]
                    type_2 = type_0 and type_1


                    if not type_0 and not type_1:
                        i += 1
                        continue

                    cn.utarray_push_back(idx_other, &(indexes[loop_counter]))
                    cn.utarray_push_back(idx_self, &(im_buf[i].target_id))

                    if type_2:
                        overlap_type_nb = 2
                    elif type_1:
                        overlap_type_nb = 1
                    elif type_0:
                        overlap_type_nb = 0
                    cn.utarray_push_back(overlap_type, &(overlap_type_nb))
                    i += 1

            cn.free_interval_iterator(it)

            loop_counter += 1

        cdef int *arr
        cdef int *arr_other
        cdef int *arr_type

        arr = cn.utarray_eltptr(idx_self, 0)
        arr_other = cn.utarray_eltptr(idx_other, 0)
        arr_type = cn.utarray_eltptr(overlap_type, 0)

        length = cn.utarray_len(idx_self)

        # output = array("i")
        output_arr = np.zeros(length, dtype=np.long)
        output_arr_other = np.zeros(length, dtype=np.long)
        output_arr_type = np.zeros(length, dtype=np.long)
        cdef long [::1] output
        cdef long [::1] output_other
        cdef long [::1] output_type

        output = output_arr
        output_other = output_arr_other
        output_type = output_arr_type

        i = 0
        for i in range(length):
            output_arr[i] = arr[i]
            output_arr_other[i] = arr_other[i]
            output_arr_type[i] = arr_type[i]

        cn.utarray_free(idx_self)
        cn.utarray_free(idx_other)
        cn.utarray_free(overlap_type)


        return output_arr, output_arr_other, output_arr_type


    @cython.boundscheck(False)
    @cython.wraparound(False)
    cpdef all_overlaps_both(self, long [::1] starts, long [::1] ends, long [::1] indexes):

        cdef int i
        cdef int nhit = 0
        cdef int length = len(starts)
        cdef int loop_counter = 0
        cdef int nfound = 0

        cdef cn.UT_array *found
        cn.utarray_new(found, &(cn.ut_int_icd))

        cdef cn.UT_array *found_other
        cn.utarray_new(found_other, &(cn.ut_int_icd))

        cdef cn.IntervalIterator *it
        cdef cn.IntervalMap im_buf[1024]
        if not self.im: # if empty
            return [], []

        while loop_counter < length:

            it = cn.interval_iterator_alloc()
            while it:
                i = 0
                cn.find_intervals(it, starts[loop_counter], ends[loop_counter], self.im, self.ntop,
                                self.subheader, self.nlists, im_buf, 1024,
                                &(nhit), &(it)) # GET NEXT BUFFER CHUNK

                while i < nhit:

                    cn.utarray_push_back(found, &(indexes[loop_counter]))
                    cn.utarray_push_back(found_other, &(im_buf[i].target_id))
                    # found[nfound] = indexes[loop_counter]
                    # found_other[nfound] = im_buf[i].target_id
                    # found.append(indexes[loop_counter])
                    # found_other.append(im_buf[i].target_id)
                    nfound += 1
                    i += 1

            cn.free_interval_iterator(it)

            loop_counter += 1

        cdef int *arr
        cdef int *arr_other

        arr = cn.utarray_eltptr(found, 0)
        arr_other = cn.utarray_eltptr(found_other, 0)

        length = cn.utarray_len(found)

        # output = array("i")
        output_arr = np.zeros(length, dtype=np.long)
        output_arr_other = np.zeros(length, dtype=np.long)
        cdef long [::1] output
        cdef long [::1] output_other

        output = output_arr
        output_other = output_arr_other

        for i in range(length):
            output_arr[i] = arr[i]
            output_arr_other[i] = arr_other[i]

        # # data_pointer = c.cast(arr, c.POINTER(c.c_int))
        # # new_array = np.copy(np.ctypeslib.as_array(data_pointer, shape=(length,)))
        # cdef int[::1] mview = <int[:length:1]>(arr)
        # output = np.copy(np.asarray(mview))

        cn.utarray_free(found)
        cn.utarray_free(found_other)

        return output_arr, output_arr_other


        # return found_arr, found_other_arr

    @cython.boundscheck(False)
    @cython.wraparound(False)
    cpdef all_containments_both(self, long [::1] starts, long [::1] ends, long [::1] indexes):

        cdef int i
        cdef int nhit = 0
        cdef int length = len(starts)
        cdef int loop_counter = 0
        cdef int nfound = 0
        cdef int start, end

        cdef cn.UT_array *found
        cn.utarray_new(found, &(cn.ut_int_icd))

        cdef cn.UT_array *found_other
        cn.utarray_new(found_other, &(cn.ut_int_icd))

        cdef cn.IntervalIterator *it
        cdef cn.IntervalMap im_buf[1024]
        if not self.im: # if empty
            return [], []

        while loop_counter < length:

            it = cn.interval_iterator_alloc()
            start = starts[loop_counter]
            end = ends[loop_counter]
            while it:
                i = 0
                cn.find_intervals(it, start, end, self.im, self.ntop,
                                self.subheader, self.nlists, im_buf, 1024,
                                &(nhit), &(it)) # GET NEXT BUFFER CHUNK

                while i < nhit:

                    if im_buf[i].start <= start and im_buf[i].end >= end:
                        cn.utarray_push_back(found, &(indexes[loop_counter]))
                        cn.utarray_push_back(found_other, &(im_buf[i].target_id))

                    nfound += 1
                    i += 1

            cn.free_interval_iterator(it)

            loop_counter += 1

        cdef int *arr
        cdef int *arr_other

        arr = cn.utarray_eltptr(found, 0)
        arr_other = cn.utarray_eltptr(found_other, 0)

        length = cn.utarray_len(found)

        # output = array("i")
        output_arr = np.zeros(length, dtype=np.long)
        output_arr_other = np.zeros(length, dtype=np.long)
        cdef long [::1] output
        cdef long [::1] output_other

        output = output_arr
        output_other = output_arr_other

        for i in range(length):
            output_arr[i] = arr[i]
            output_arr_other[i] = arr_other[i]

        # # data_pointer = c.cast(arr, c.POINTER(c.c_int))
        # # new_array = np.copy(np.ctypeslib.as_array(data_pointer, shape=(length,)))
        # cdef int[::1] mview = <int[:length:1]>(arr)
        # output = np.copy(np.asarray(mview))

        cn.utarray_free(found)
        cn.utarray_free(found_other)

        return output_arr, output_arr_other


    @cython.boundscheck(False)
    @cython.wraparound(False)
    cpdef has_containment(self, long [::1] starts, long [::1] ends, long [::1] indexes):

        cdef int i = 0
        cdef int loop_counter = 0
        cdef int nhit = 0
        cdef int length = len(starts)
        cdef int start, end

        # cn.UT_array does not seem faster than python list (!)
        # but then we do not need to demarshal the list
        # also much more mem-efficient

        cdef cn.UT_array *found
        cn.utarray_new(found, &(cn.ut_int_icd))

        # found = []
        # found_arr = np.zeros(len(starts), dtype=np.long)
        # cdef long[::1] found = found_arr

        cdef cn.IntervalIterator *it
        cdef cn.IntervalMap im_buf[1024]
        if not self.im: # if empty
            return []

        while loop_counter < length:

            it = cn.interval_iterator_alloc()
            i = 0
            while it:
                cn.find_intervals(it, starts[loop_counter], ends[loop_counter], self.im, self.ntop,
                                self.subheader, self.nlists, im_buf, 1024,
                                &(nhit), &(it)) # GET NEXT BUFFER CHUNK

                start = starts[loop_counter]
                end = ends[loop_counter]


                while i < nhit:

                    if im_buf[i].start <= start and im_buf[i].end >= end:
                        cn.free_interval_iterator(it)
                        it = NULL
                        cn.utarray_push_back(found, &(indexes[i]))

            loop_counter += 1
            cn.free_interval_iterator(it)

        cdef int *arr

        arr = cn.utarray_eltptr(found, 0)

        length = cn.utarray_len(found)


        output_arr_other = np.zeros(length, dtype=np.long)
        cdef long [::1] output_other

        output_other = output_arr_other

        # output = array("i")
        output_arr = np.zeros(length, dtype=np.long)
        cdef long [::1] output
        output = output_arr

        for i in range(length):
            output_arr[i] = arr[i]

        cn.utarray_free(found)

        return output_arr



    @cython.boundscheck(False)
    @cython.wraparound(False)
    cpdef has_overlaps(self, long [::1] starts, long [::1] ends, long [::1] indexes):

        cdef int i = 0
        cdef int nhit = 0
        cdef int length = len(starts)

        # cn.UT_array does not seem faster than python list (!)
        # but then we do not need to demarshal the list
        # also much more mem-efficient

        cdef cn.UT_array *found
        cn.utarray_new(found, &(cn.ut_int_icd))

        # found = []
        # found_arr = np.zeros(len(starts), dtype=np.long)
        # cdef long[::1] found = found_arr

        cdef cn.IntervalIterator *it
        cdef cn.IntervalMap im_buf[1024]
        if not self.im: # if empty
            return []

        while i < length:

            it = cn.interval_iterator_alloc()

            while it:
                cn.find_intervals(it, starts[i], ends[i], self.im, self.ntop,
                                self.subheader, self.nlists, im_buf, 1024,
                                &(nhit), &(it)) # GET NEXT BUFFER CHUNK

                if nhit > 0:
                    cn.free_interval_iterator(it)
                    it = NULL
                    # found.append(indexes[i])
                    # found[nfound] = indexes[i]
                    # nfound += 1
                    cn.utarray_push_back(found, &(indexes[i]))
                    # indexes_of_overlapping.push_back(indexes[i])

            i += 1
            cn.free_interval_iterator(it)

        # cdef int outlength = cn.utarray_len(found);

        cdef int *arr

        arr = cn.utarray_eltptr(found, 0)

        length = cn.utarray_len(found)


        output_arr_other = np.zeros(length, dtype=np.long)
        cdef long [::1] output_other

        output_other = output_arr_other

        # output = array("i")
        output_arr = np.zeros(length, dtype=np.long)
        cdef long [::1] output
        output = output_arr

        for i in range(length):
            output_arr[i] = arr[i]

        # # data_pointer = c.cast(arr, c.POINTER(c.c_int))
        # # new_array = np.copy(np.ctypeslib.as_array(data_pointer, shape=(length,)))
        # cdef int[::1] mview = <int[:length:1]>(arr)
        # output = np.copy(np.asarray(mview))

        cn.utarray_free(found)

        return output_arr


    @cython.boundscheck(False)
    @cython.wraparound(False)
    cpdef no_overlaps(self, long [::1] starts, long [::1] ends, long [::1] indexes):

        cdef int i = 0
        cdef int nhit = 0
        cdef int length = len(starts)

        cdef cn.UT_array *found
        cn.utarray_new(found, &(cn.ut_int_icd))

        # found = []
        # found_arr = np.zeros(len(starts), dtype=np.long)
        # cdef long[::1] found = found_arr

        cdef cn.IntervalIterator *it
        cdef cn.IntervalMap im_buf[1024]
        if not self.im: # if empty
            return []

        while i < length:

            it = cn.interval_iterator_alloc()

            while it:
                cn.find_intervals(it, starts[i], ends[i], self.im, self.ntop,
                                self.subheader, self.nlists, im_buf, 1024,
                                &(nhit), &(it)) # GET NEXT BUFFER CHUNK

                if nhit == 0:
                    cn.free_interval_iterator(it)
                    it = NULL
                    # found.append(indexes[i])
                    # found[nfound] = indexes[i]
                    # nfound += 1
                    cn.utarray_push_back(found, &(indexes[i]))
                    # indexes_of_overlapping.push_back(indexes[i])

            i += 1
            cn.free_interval_iterator(it)

        # cdef int outlength = cn.utarray_len(found);

        cdef int *arr

        arr = cn.utarray_eltptr(found, 0)

        length = cn.utarray_len(found)


        output_arr_other = np.zeros(length, dtype=np.long)
        cdef long [::1] output_other

        output_other = output_arr_other

        # output = array("i")
        output_arr = np.zeros(length, dtype=np.long)
        cdef long [::1] output
        output = output_arr

        for i in range(length):
            output_arr[i] = arr[i]

        # # data_pointer = c.cast(arr, c.POINTER(c.c_int))
        # # new_array = np.copy(np.ctypeslib.as_array(data_pointer, shape=(length,)))
        # cdef int[::1] mview = <int[:length:1]>(arr)
        # output = np.copy(np.asarray(mview))

        cn.utarray_free(found)

        return output_arr


    cpdef find_overlap_list(self, int start, int end):
        cdef int i
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
            i = 0
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
