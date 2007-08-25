module tools.iter;
import tools.base;
public import tools.base: elemType;
import std.traits;
/// functional extensions

/// Keep in mind: iterators are throwaway objects. Discard after use.
class Iterator(T) {
  alias T IterType;
  abstract bool next(ref T);
  int opApply(int delegate(ref T) dg) {
    T cur=void;
    while (next(cur)) { auto res=dg(cur); if (res) return res; }
    return 0;
  }
  bool opEquals(U)(U cmp) {
    static if (isArray!(U)) return opEquals(new ArrayIterator!(elemType!(U))(cmp));
    else {
      static assert(is(typeof(&cmp.next)==delegate), "Error: cmp doesn't appear to be an iterator");
      while (true) {
        T res1=void; auto has1=next(res1);
        U.IterType res2=void; auto has2=cmp.next(res2);
        if (has1!=has2) return false; // Evidently, the lengths are different
        if (!has1) return true; /// We're done.
        if (res1!=res2) return false;
      }
    }
  }
}


class NestedIterator(T, U) : Iterator!(T) {
  alias U SubType;
  Iterator!(U) child;
  this(Iterator!(U) iter) { child=iter; }
}

struct toArray {
  static template opCat_r(T) {
    static if (!is(T.IterType))
      pragma(msg, "Failure: Cannot convert "~T.stringof~" to array: not an iterator");
    T.IterType[] opCat_r(T iter) {
      T.IterType[] res;
      foreach (entry; iter) res~=entry;
      return res;
    }
  }
}

struct reverse {
  static Iterator!(T.IterType) opCat_r(T)(T iter) {
    auto array=iter~toArray;
    foreach (id, ref entry; array[0..$/2]) swap(entry, array[$-1-id]);
    return new ArrayIterator!(elemType!(typeof(array)))(array);
  }
}

template ExpandSimplifiedFunc(char[] CODE, char[] VARNAME) {
  const ExpandSimplifiedFunc=RInsert!(Replace!(CODE, "_", VARNAME), ";", "return ");
}

template ExpandSimplifiedReduce(char[] CODE, char[] VAR1, char[] VAR2) {
  const ExpandSimplifiedReduce=Replace!(Replace!(CODE, "__", VAR2), "_", VAR1);
}

template PatchIter(char[] M, T) {
  static if(isArray!(T)) {
    const char[] PatchIter=
      Replace!(M[0..FindOr!(M, ")", 0)], "V.IterType", "elemType!(V)")~M[FindOr!(M, ")", 0)..$];
  } else const char[] PatchIter=M;
  
}

template GenericChain(alias IterClass, char[] StoredValue) {
  IterClass!(typeof(mixin(PatchIter!(StoredValue, V)))) opCat_r(V)(V iter) {
    static if(isArray!(V)) {
      return new IterClass!(typeof(mixin(PatchIter!(StoredValue, V))))
        (iterate(iter), mixin(PatchIter!(StoredValue, V)));
    } else {
      return new IterClass!(typeof(mixin(PatchIter!(StoredValue, V))))
        (iter, mixin(PatchIter!(StoredValue, V)));
    }
  }
}

struct _map(C) {
  C callable;
  mixin GenericChain!(MapIterator, "callable");
}
struct _map(char[] CODE) {
  private const char[] fn="function(V.IterType MapHiddenParameter) { "~ExpandSimplifiedFunc!(CODE, "MapHiddenParameter")~"; }";
  mixin GenericChain!(MapIterator, fn);
}
_map!(CODE) maps(char[] CODE)() { _map!(CODE) e; return e; }
_map!(C) map(C)(C c) { return _map!(C)(c); }
class MapIterator(C) : NestedIterator!(ReturnType!(C), ParameterTypeTuple!(C)) {
  C callable;
  this(Iterator!(ParameterTypeTuple!(C)) iter, C c) { super(iter); callable=c; }
  bool next(ref ReturnType!(C) v) {
    ParameterTypeTuple!(C) sub=void;
    if (!child.next(sub)) return false;
    v=callable(sub);
    return true;
  }
}

struct _filter(C) {
  C callable;
  mixin GenericChain!(FilterIterator, "callable");
}
struct _filter(char[] CODE) {
  private const char[] fn="function(V.IterType FilterHiddenParameter) { "~ExpandSimplifiedFunc!(CODE, "FilterHiddenParameter")~"; }";
  mixin GenericChain!(FilterIterator, fn);
}
_filter!(CODE) filters(char[] CODE)() { _filter!(CODE) e; return e; }
_filter!(C) filter(C)(C c) {
  static assert(is(ReturnType!(C): bool), "filter: bool expected from "~C.stringof);
  return _filter!(C)(c);
}
class FilterIterator(C) : NestedIterator!(Pair!(ParameterTypeTuple!(C))) {
  C callable;
  this(Iterator!(ParameterTypeTuple!(C)[0]) iter, C c) { super(iter); callable=c; }
  bool next(ref ParameterTypeTuple!(C)[0] v) {
    do if (!child.next(v)) return false; while (!callable(v));
    return true;
  }
}

struct _zip(T) {
  T iter2;
  mixin GenericChain!(ZipIterator, "iter2");
}
_zip!(T) zip(T)(T i2) { return _zip!(T)(i2); }
class ZipIterator(T) : NestedIterator!(T.IterType, T.IterType) {
  T child2;
  bool useFirst=true;
  this(T iter, T iter2) { super(iter); child2=iter2; }
  bool next(ref T.IterType v) {
    bool myState=void; synchronized(this) { myState=useFirst; useFirst=!useFirst; }
    auto it=myState?child:child2;
    if (!it.next(v)) return false;
    return true;
  }
}

struct _cat(C) {
  C iter2;
  mixin GenericChain!(ConcatIterator, "iter2");
}
_cat!(T) cat(T)(T i2) { return _cat!(T)(i2); }
class ConcatIterator(T) : NestedIterator!(T.IterType, T.IterType) {
  T second;
  this(T iter, T s) { super(iter); second=s; }
  bool next(ref T.IterType v) {
    if (!child.next(v)) if (!second.next(v)) return false; return true;
  }
}

struct _reduce(C) {
  C callable;
  static assert(ParameterTypeTuple!(C).length==2);
  static assert(is(ReturnType!(C)==void));
  alias ParameterTypeTuple!(C)[0] Type;
  static assert(is(Type==ParameterTypeTuple!(C)[1]));
  Type opCat_r(T)(T thing) {
    static if(isArray!(T)) return opCat_r(iterate(array)); else {
      Type res=void;
      if (!thing.next(res)) throw new Exception("Stream too short to reduce further");
      Type next=void;
      while (thing.next(next)) callable(res, next);
      return res;
    }
  }
}
struct _reduce(char[] CODE) {
  private const char[] fn="function(ref V.IterType RedChangeP, V.IterType RedSrcP) { "~
    ExpandSimplifiedReduce!(CODE, "RedChangeP", "RedSrcP")~"; }";
  V.IterType opCat_r(V)(V iter) {
    V.IterType res=void;
    if (!iter.next(res)) throw new Exception("Stream too short to further reduce");
    typeof(res) next=void;
    while (iter.next(next)) mixin(fn~"(res, next);");
    return res;
  }
}
_reduce!(C) reduce(C)(C c) { return _reduce!(C)(c); }
_reduce!(CODE) reduces(char[] CODE)() { _reduce!(CODE) e; return e; }

class ArrayIterator(T) : Iterator!(T) {
  T *end;
  T *cur;
  this(T[] a) { end=cur=a.ptr; end+=a.length; }
  bool next(ref T v) {
    if (cur==end) return false;
    synchronized(this) { v=*cur; cur++; } return true;
  }
}

ArrayIterator!(T) iterate(T)(T[] array) { return new ArrayIterator!(T)(array); }
