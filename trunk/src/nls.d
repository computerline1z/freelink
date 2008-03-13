module nls;
import std.utf, std.file, mystring, tools.functional, std.path: sep;

static this() {
  char[][char[]] init;
  char[] curlang;
  nls[""] = init;
  auto lines = (cast(char[])read("nls" ~ sep ~ "default.txt")).split("\n")
    /map/ (string s) { if (s.length && (s[$-1] == '\r')) return s[0..$-1]; else return s; };
  foreach (line; lines) {
    if (!line.length) continue;
    // begin of a new language section
    if (line[0] == '[') {
      assert(line.find("]") != -1);
      curlang = line[1..line.find("]")].dup;
      nls[curlang] = init;
    } else if (line.find("=") != -1) {
      auto pair = line.split("=");
      nls[curlang][pair[0]] = pair[1..$].join("=").dup;
    } else assert(false, "Invalid NLS data line: " ~ line);
  }
}

void setLanguage(char[] x = "".dup) { assert(x in nls); lang=x; }

char[][char[]][char[]] nls;
char[] lang;

import std.string:tolower;
char[] nl(char[] origin) {
  auto i = origin in nls[lang];
  if (!i) i = origin in nls[""];
  if (!i) {
    origin = tolower(origin);
    foreach (index, entry; nls)
      if (tolower(index) == origin)
        assert(false, origin ~ " not found in language table! Did you mean "
                      ~ index ~ "?");
    assert(false, origin ~ " not found in language table!");
  }
  return *i;
}
