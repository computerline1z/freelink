/// Extensions to the D language
module tools.ext;
import tools.base;
public import tools.iter, tools.mrv;
import std.traits;

struct _TSzip(T) {
  Iterator!(T) iter;
  TSZipIterator!(U.IterType, T) opCat_r(U)(U iter2) {
    return new TSZipIterator!(U.IterType, T)(iter2, iter);
  }
}
_TSzip!(T.IterType) tszip(T)(T i) { return _TSzip!(T.IterType)(i); }
class TSZipIterator(T, U) : NestedIterator!(TupleStruct!(T, U), T) {
  Iterator!(U) child2;
  this(Iterator!(T) iter, Iterator!(U) iter2) { super(iter); child2=iter2; }
  bool next(ref TupleStruct!(T, U) v) {
    if (!(child.next(v.values[0])&&child2.next(v.values[1]))) return false;
    return true;
  }
}

struct _TScross(T) {
  T delegate() iter;
  TSCrossIterator!(U.IterType, T) opCat_r(U)(U iter2) {
    return new TSCrossIterator!(U.IterType, T)(iter2, iter);
  }
}
_TScross!(T) tscross(T)(T delegate() i) { return _TScross!(T)(i); }
class TSCrossIterator(T, U) : NestedIterator!(TupleStruct!(T, U.IterType), T) {
  U delegate() c2gen;
  T current;
  U current2=null;
  this(Iterator!(T) iter, U delegate() iter2) { super(iter); c2gen=iter2; }
  bool next(ref TupleStruct!(T, U.IterType) v) {
restart: // I'M SORRY! I WON'T DO IT AGAIN! ... hopefully
    if (!current2) { if (!child.next(current)) return false; current2=c2gen(); }
    v.values[0]=current;
    if (!current2.next(v.values[1])) { current2=null; goto restart; }
    return true;
  }
}

T delegate(T) Loop(T)(int count, T delegate(T) dg) {
  assert(count>0);
  if (count==1) return dg; return (chain~Loop(count-1, dg)~dg).ptr;
}

/// The actual chain
/// Filters Q through R
class MultiChain(Q, R) {
  Q func; R wrapper;
  this(Q whu, R whee) { func=whu; wrapper=whee; }
  static if(is(R==delegate)||is(R==function)) { alias ReturnType!(R) Ret; }
  else alias R.Ret Ret;
  static if(is(Q==delegate)||is(Q==function)) { alias ParameterTypeTuple!(Q) Par; }
  else alias Q.Par Par;
  Ret opCall(Par p) { return wrapper(func(p)); }
  MultiChain!(chain!(Q, R), S) opCat(S)(S s) {
    auto res=new __chain!(chain!(Q, R), S); res.func=*this; res.wrapper=s; return res;
  }
  Ret delegate(Par) ptr() { return &opCall; }
}

/// A single callable thing that stuff can be appended to
class SingleChain(Q) {
  Q func;
  this(Q whu) { func=whu; }
  static if(is(Q==delegate)||is(Q==function)) { alias ReturnType!(Q) Ret; alias ParameterTypeTuple!(Q) Par; }
  else static assert(false, "Cannot build chain from "~Q.stringof~", must be function or delegate!");
  Ret opCall(Par p) { return func(p); } /// execute the chain
  MultiChain!(Q, R) opCat(R)(R r) { return new MultiChain!(Q, R)(func, r); }
  Ret delegate(Par) ptr() { return &opCall; }
}

/// The new "chain" keyword, handled by a struct
struct chain {
  static SingleChain!(E) opCat(E)(E e) { return new SingleChain!(E)(e); }
}

T tee(T)(T v, void delegate(T) dg) { dg(v); return v; }

class Integers : Iterator!(int) {
  int cur=0, end=int.max;
  this() { }
  this(int a, int b) { cur=a; end=b; }
  override bool next(ref int whuh) {
    if (cur==end) return false;
    synchronized(this) whuh=cur++; return true;
  }
  static Integers opSlice(int a, int b) { return new Integers(a, b); }
}

/// If obj is C, then dg(cast(C)obj). Else dgElse.
R ifIs(Base, R, C)(Base obj, R delegate(C) dg, R delegate() dgElse) {
  auto c=cast(C)obj;
  static if(is(R==void)) { if (c) dg(c); else if (dgElse) dgElse(); }
  else {
    if (c) return dg(c); else if (dgElse) return dgElse(); else throw new Exception("ifIs return failed to match");
  }
}

R ifIs(Base, R, C, BOGUS=void)(Base obj, R delegate(C) dg) {
  static if(is(R==void)) ifIs!(Base, R, C)(obj, dg, null);
  else return ifIs!(Base, R, C)(obj, dg, null);
}

/// Like ifIs, but throws an exception when the cast fails
R mustBe(R, C)(Object obj, R delegate(C) dg) {
  return ifIs(obj, dg, () { throw new Exception("mustBe: cast to "~C.stringof~" failed!"); return R.init; });
}

T[] times(T, U)(T[] source, U _count) {
  static assert(is(U: size_t));
  size_t count=_count;
  auto res=new T[source.length*count];
  while (count--) res[count*source.length..(count+1)*source.length]=source;
  return res;
}

T[] field(T)(size_t count, lazy T generate) {
  assert(!is(T==void));
  // avoid array initialization to default values (that's why it's not new void[count])
  auto res=(cast(T*)(new void[count*T.sizeof]).ptr)[0..count];
  assert(res.length==count, "Sanity failed: redetermine length manually");
  foreach (inout v; res) v=generate();
  return res;
}

struct _fix(T...) {
  T what;
  R delegate(P[T.length..$]) opCat_r(R, P...)(R delegate(P) dg) {
    struct holder {
      T what; R delegate(P) dg;
      R call(P[T.length..$] p) { return dg(what, p); }
    }
    auto h=new holder; foreach (id, entry; what) h.what[id]=entry; h.dg=dg;
    return &h.call;
  }
}
_fix!(T) fix(T...)(T v) { return _fix!(T)(v); }

import tools.tests;
unittest {
  mustEqual("ChainTest", (chain~(int e) { return e*2; }~(int e) { return e/2; })(5), 5);
  mustEqual("LoopSquares", Loop(4, (int e) { return e*e; })(2), 65536);
  mustEqual("IntegerSlice", Integers[4..6]~toArray, [4, 5]);
  mustEqual("IntegerSliceMap", (Integers[3..6]~map((int e) { return e*2; }))~toArray, [6, 8, 10]);
  class A { } class B : A { }
  A foo=new B;
  Assert("ifIs", ifIs(foo, (B b) { return true; }, () { return false; }));
  A fwhee=new A;
  mustFail("mustBeMustFail", mustBe(fwhee, (B b) { return true; }));
  mustEqual("IntegerMap",
    Integers[5..10]~maps!("_*3")~toArray,
    [15, 18, 21, 24, 27]
  );
  mustEqual("IntegerReduce",
    Integers[0..10]~reduce((ref int a, int b) { a+=b; }),
    45
  );
  mustEqual("IntegerFilter",
    Integers[10..20]~filters!("(_%2)?true:false"),
    Integers[10..20]~filter(function(int foo) { return (foo%2)?true:false; }),
    [11, 13, 15, 17, 19]
  );
  mustEqual("ZipFilter",
    Integers[5..10]~zip(Integers[10..15])~toArray,
    [5, 10, 6, 11, 7, 12, 8, 13, 9, 14]
  );
  mustEqual("ConcatFilter",
    Integers[5..10]~cat(Integers[10..15]),
    Integers[5..15]
  );
  mustEqual("ReverseFilter",
    Integers[5..10]~reverse,
    [9, 8, 7, 6, 5]
  );
  mustEqual("TsZipFilter",
    Integers[0..10]~tszip(Integers[10..20])~
    map((TupleStruct!(Pair!(int)) ts) { return ts.values[0]*ts.values[1]; })~reduce((ref int a, int b) { a+=b; }),
    Integers[0..10]~tszip(Integers[10..20])~maps!("_.values[0]*_.values[1]")~reduces!("_+=__"),
    735
  );
  class odds : Iterator!(int) {
    int x=0;
    bool next(ref int foo) {
      if (x!<36) return false; foo=x; x+=1; return true;
    }
  }
  writefln("Foobie: ", (new odds)~filters!("_>30")~maps!("_*_")~toArray);
  writefln("Foobie2: ", Integers[0..3]~map((int e) { return Integers[0..3]~map((int f) { return f+e; })~toArray; })~toArray);
  writefln("Foobie3: ", Integers[0..16]~filters!("_&1")~maps!("_*_")~toArray);
  writefln("Foobie4: ", Integers[0..5]~filters!("_&1")
    ~tscross({return Integers[0..5]; })
    ~maps!("_.values[0]+_.values[1]")~toArray);
}
