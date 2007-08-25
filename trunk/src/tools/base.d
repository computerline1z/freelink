module tools.base;

template Tuple(T...) { alias T Tuple; }

template isArray(T) { const bool isArray=false; }
template isArray(T: T[]) { const bool isArray=true; }

template ElemType(T: T[]) { alias T ElemType; }
template ElemType(T) { alias T.IterType ElemType; }

template apply(alias S, T...) {
  static if(T.length) alias Tuple!(S!(T[0]), apply!(S, T[1..$])) apply;
  else alias Tuple!() apply;
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

void swap(T)(ref T a, ref T b) { T c=a; a=b; b=c; }

template Pair(T) { alias Tuple!(T, T) Pair; }
template Triple(T) { alias Tuple!(T, T, T) Triple; }

template Replace(char[] SOURCE, char[] WHAT, char[] WITH) {
  static if(SOURCE.length<WHAT.length) const char[] Replace=SOURCE; else
  static if(SOURCE[0..WHAT.length]==WHAT) const char[] Replace=WITH~Replace!(SOURCE[WHAT.length..$], WHAT, WITH); else
  const char[] Replace=SOURCE[0]~Replace!(SOURCE[1..$], WHAT, WITH);
}

template FindOr(char[] SRC, char[] WHAT, size_t OR) {
  static if(SRC.length<WHAT.length) const size_t FindOr=OR; else
  static if(SRC[0..WHAT.length]==WHAT) const size_t FindOr=0; else
  const size_t FindOr=FindOr!(SRC[1..$], WHAT, OR)+1;
}

// reverse insert at WHERE or start
template RInsert(char[] SRC, char[] WHERE, char[] WITH) {
  static if(SRC.length<WHERE.length) const char[] RInsert=WITH~SRC; else
  static if(SRC[$-WHERE.length..$]==WHERE) const char[] RInsert=SRC~WITH; else
  const char[] RInsert=RInsert!(SRC[0..$-1], WHERE, WITH)~SRC[$-1];
}

T min(T, U)(T a, U b) { return a<b?a:cast(T)b; }
