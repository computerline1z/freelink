module util;

alias void delegate() call;

void ifIs(T, P)(P obj, void delegate(T) dg, call alt=null) {
  if (cast(T)obj) dg(cast(T)obj);
  else if (alt) alt();
}

template staticToString(int foo) {
  static if (foo<10) const char[] staticToString=""~"0123456789"[foo];
  else const char[] staticToString=staticToString!(foo/10)~"0123456789"[foo%10];
}

template const_enum(T, string csv, string got="", int offset=0) {
  static if (!csv.length) const char[] const_enum="const "~T.stringof~" "~got~" = "~staticToString!(offset)~";";
  else static if (csv[0]==',') {
    const char[] const_enum="const "~T.stringof~" "~got~" = "~staticToString!(offset)~";" ~
      const_enum!(T, csv[1..$], "", offset+1);
  } else const char[] const_enum=const_enum!(T, csv[1..$], got~csv[0], offset);
}

bool between(T)(T what, T low, T up) { return (what>=low)&&(what<up); }
