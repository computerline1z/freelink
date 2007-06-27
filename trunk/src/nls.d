import std.utf, std.file, mystring, func, std.path: sep;

static this() {
  char[][char[]] init;
  char[] curlang;
  nls[""]=init;
  auto lines=map(
    split(cast(char[])read("nls"~sep~"default.txt"), "\n"),/// split into lines
    (string c) { if (c.length&&(c[$-1]=='\r')) c=c[0..$-1]; return c; } /// remove trailing \r
  );
  foreach (line; lines) {
    if (!line.length) continue;
    if (line[0]=='[') {/// begin of a new language section
      assert(line.find("]")!=-1);
      curlang=line[1..line.find("]")].dup;
      nls[curlang]=init;
    } else if (line.find("=")!=-1) {
      auto pair=line.split("=");
      nls[curlang][pair[0]]=pair[1..$].join("=").dup;
    } else assert(false, "Invalid NLS data line: "~line);
  }
}

void setLanguage(char[] l="".dup) { assert(l in nls); lang=l; }

char[][char[]][char[]] nls;
char[] lang;

import std.string:tolower;
char[] nl(string origin) {
  auto i=origin in nls[lang];
  if (!i) i=origin in nls[""];
  if (!i) {
    origin=tolower(origin);
    foreach (index, entry; nls) if (tolower(index)==origin) assert(false, origin~" not found in language table! Did you mean "~index~"?");
    assert(false, origin~" not found in language table!");
  }
  return *i;
}
