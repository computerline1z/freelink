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

template ArrayOrVoid(T) {
  static if (is(T==void)) alias void ArrayOrVoid;
  else alias T[] ArrayOrVoid;
}

ArrayOrVoid!(U) map(T, U)(T[] array, U delegate(T) dg) {
  static if (is(U==void)) foreach (d; array) dg(d);
  else {
    auto res=new U[array.length];
    foreach (i, d; array) res[i]=dg(d);
    return res;
  }
}

ArrayOrVoid!(U) map(T, U, Bogus=void)(T[] array, U function(T) fn) {
  return map(array, (T foo) { return fn(foo); });
}

template ReturnType(C, char[] M) {
  const C test=void;
  mixin("static if (is(C."~M~"==delegate)) {
    alias typeof(test."~M~"()) type;
  } else {
    alias typeof(test."~M~") type;
  }");
}

ReturnType!(CLASS, METHOD).type member(CLASS, char[] METHOD)(CLASS cl) {
  mixin("return cl."~METHOD~"; ");
}

void sum(T)(inout T a, T b) { a+=b; }

T fold(T)(T[] array, void delegate(inout T to, T from) dg) { assert(array.length); foreach (elem; array[1..$]) dg(array[0], elem); return array[0]; }
T fold(T, Bogus=void)(T[] array, void function(inout T to, T from) fn) { return fold(array, (inout T to, T from) { fn(to, from); }); }
