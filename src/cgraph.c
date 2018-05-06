

#include "cgraph.h"


CDict *cdict_alloc(int n)
{
  CDict *d=0;
  
  d=calloc(1,sizeof(CDict));
  if (d==0) /* calloc FAILED!! */
    return 0;
  d->dict=calloc(n,sizeof(CDictEntry));
  if (d->dict==0) { /* calloc FAILED!! */
    free(d); /* DUMP OUR EMPTY STRUCTURE */
    return 0;
  }
  return d; /* RETURN OUR DATA STRUCTURE */
}


int cdict_free(CDict *d)
{
  free(d->dict);
  free(d);
  return 0;
}


int cdict_qsort_cmp(const void *void_a,const void *void_b)
{ /* STRAIGHTFORWARD COMPARISON OF SIGNED start VALUES, LONGER INTERVALS 1ST */
  CDictEntry *a=(CDictEntry *)void_a,*b=(CDictEntry *)void_b;
  if (a->k<b->k)
    return -1;
  else if (a->k>b->k)
    return 1;
  else
    return 0;
}


CDictEntry *cdict_getitem(CDict *d,int k)
{
  int l=0,mid,r;
  CDictEntry *p;

  if (d==0) /* HANDLE NULL POINTER PROPERLY */
    return 0;

  p=d->dict; /* SORTED ARRAY OF ENTRIES */
  r=d->n;
  while (l<r) {
    mid=(l+r)/2;
    if (p[mid].k==k)
      return p+mid;
    else if (p[mid].k<k)
      l=mid+1;
    else
      r=mid;
  }
  return 0;
}



CGraph *cgraph_alloc(int n)
{
  CGraph *d=0;
  
  d=calloc(1,sizeof(CGraph));
  if (d==0) /* calloc FAILED!! */
    return 0;
  d->dict=calloc(n,sizeof(CGraphEntry));
  if (d->dict==0) { /* calloc FAILED!! */
    free(d); /* DUMP OUR EMPTY STRUCTURE */
    return 0;
  }
  return d; /* RETURN OUR DATA STRUCTURE */
}


int cgraph_free(CGraph *d)
{
  int i;
  for (i=0;i<d->n;i++) /* DUMP ALL ASSOCIATED DICTIONARIES */
    cdict_free(d->dict[i].v);
  free(d->dict);
  free(d);
  return 0;
}


CGraphEntry *cgraph_getitem(CGraph *d,int k)
{
  int l=0,mid,r;
  CGraphEntry *p;

  if (d==0) /* HANDLE NULL POINTER PROPERLY */
    return 0;

  p=d->dict; /* SORTED ARRAY OF ENTRIES */
  r=d->n;
  while (l<r) {
    mid=(l+r)/2;
    if (p[mid].k==k)
      return p+mid;
    else if (p[mid].k<k)
      l=mid+1;
    else
      r=mid;
  }
  return 0;
}


int *calloc_int(int n)
{
  return (int *)calloc(n,sizeof(int));
}
