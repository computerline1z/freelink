/// functional routines: map, filter
module func;
import util;

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

template ReturnType(C, string M) {
  const C test=void;
  mixin("static if (is(C."~M~"==delegate)) {
    alias typeof(test."~M~"()) type;
  } else {
    alias typeof(test."~M~") type;
  }");
}

template member(T, char[] METHOD) { const member=function(T t) { mixin("return t."~METHOD~"; "); }; }

template sum(T) { const sum=function(ref T a, T b) { a+=b; }; }
template concat(T) { const concat=function(ref T a, T b) { a~=b; }; }

T fold(T)(T[] array, void delegate(ref T to, T from) dg) { assert(array.length); foreach (elem; array[1..$]) dg(array[0], elem); return array[0]; }
T fold(T, Bogus=void)(T[] array, void function(ref T to, T from) fn) { return fold(array, (ref T to, T from) { fn(to, from); }); }

struct _range_foreach {
  int start; int end;
  int opApply(int delegate(ref int) dg) {
    int result=0; for (int c=start; c<end; ++c) {
      result=dg(c); if (result) break;
    }
    return result;
  }
}

struct _Integers {
  _range_foreach opSlice(size_t from, size_t to) {
    _range_foreach res; res.start=from; res.end=to;
    return res;
  }
}
_Integers Integers;
