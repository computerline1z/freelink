import std.utf;

struct text {
  // This will later be changed to loading at run-time, for NLS stuff
  // what's the validate(data) do? (UTF-8 validation from std.utf -downs)
  char[] data;
  invariant {
    validate (data);
  }
}
