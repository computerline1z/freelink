module mystring;
static import std.string;

/// YES INT GETS THE SPECIAL TREATMENT
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
