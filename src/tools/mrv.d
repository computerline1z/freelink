module tools.mrv;
import tools.base;

import std.stdio: format;
struct TupleStruct(T...) {
  T values;
  char[] toString() {
    static if(!T.length) return "()";
    char[] res="(";
    foreach (entry; values[0..$-1]) res~=format(entry)~", ";
    res~=format(values[$-1])~")";
    return res;
  }
}

TupleStruct!(T) mval(T...)(T t) {
  TupleStruct!(T) res=void;
  foreach (id, entry; t) res.values[id]=entry;
  return res;
}

template Pointer(T) { alias T *Pointer; }
template Pointers(T...) { alias apply!(Pointer, T) Pointers; }

struct MultiVariableHolder(T...) {
  private Pointers!(T) pointers;
  static MultiVariableHolder opCall(ref T vars) {
    MultiVariableHolder res=void;
    foreach (id, bogus; vars) res.pointers[id]=&vars[id];
    return res;
  }
  void opAssign(U)(U ts) {
    static if(is(typeof(ts.values))) {
      foreach (id, ptr; pointers) {
        static assert(is(T[id]: typeof(ts.values[id])), "Error: cannot convert "~U[id].stringof~" to "~T[id].stringof~"!");
        *ptr=ts.values[id];
      }
    } else {
      static if((T.length==1)&&is(T[0]: U)) {
        *pointers[0]=ts;
      } else static assert(false, U.stringof~" is not a valid parameter for MultiVariableHolder!"~T.stringof);
    }
  }
}

MultiVariableHolder!(T) vars(T...)(ref T v) {
  return MultiVariableHolder!(T)(v);
}

import tools.tests;
unittest {
  TupleStruct!(int, float) tstest;
  int e=5;
  TupleStruct!(int, float) test() { return mval(4, 3f); }
  vars(e)=test(); mustEqual("Simple MRV test", e, 4);
  vars(e)=3; mustEqual("Single Value 'MRV'", e, 3);
}
