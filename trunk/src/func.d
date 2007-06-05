/// functional routines: map, filter
module func;

/// This version is actually faster than ~=.
T[] filter(T)(T[] array, bool delegate(T) pick) {
  auto buffer=new bool[array.length];
  size_t sum=0;
  foreach (i, element; array)
    if (pick(element)) {
      ++sum;
      buffer[i]=true;
    }
  auto result=new T[sum];
  size_t offset=0;
  foreach (i, element; array)
    if (buffer[i])
      result[offset++]=element;
  return result;
}

U[] map(T, U)(T[] array, U delegate(T) dg) {
  auto res=new U[array.length];
  foreach (i, d; array) res[i]=dg(d);
  return res;
}
