module mystring;
static import std.string;

/// YES INT GETS THE SPECIAL TREATMENT OVER LONG
/// \todo: need to find out whose ass to kick over this
int find(T, U)(T string, U match) {
  return cast(int) std.string.find(string, match);
}

template StdStringAlias(T...) {
  static if (T.length > 1)
    mixin StdStringAlias!(T[1..$]);
  mixin("alias std.string." ~ T[0] ~ " " ~ T[0] ~ "; ");
}
mixin StdStringAlias!("split", "join");

import std.utf, std.traits: isStaticArray;
wchar[] mysformat(T)(T t) {
  static if(is(T: wchar[])) return t; else
  static if(isStaticArray!(T)) return mysformat(t[]); else
  static if(is(T: char[])) return t.toUTF16(); else
  static if(is(T: long)) return std.string.toString(cast(long)t); else
  static assert(false, T.stringof~" not supported (yet)!");
}

wchar[] myformat(T...)(T t) {
  wchar[] res;
  foreach (v; t) res~=mysformat(v);
  return res;
}
