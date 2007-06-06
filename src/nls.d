import std.utf, std.file, std.string, func, std.path: sep;

static this() {
  char[][char[]] init;
  char[] curlang="";
  nls[""]=init;
  auto lines=map(
    split(cast(char[])read("nls"~sep~"default.txt"), "\n"),/// split into lines
    (char[] c) { if (c.length&&(c[$-1]=='\r')) c=c[0..$-1]; return c; } /// remove trailing \r
  );
  foreach (line; lines) {
    if (!line.length) continue;
    if (line[0]=='[') {/// begin of a new language section
      assert(line.find("]")!=-1);
      curlang=line[1..$-1];
      nls[curlang]=init;
    } else if (line.find("=")!=-1) {
      auto pair=line.split("=");
      nls[curlang][pair[0]]=pair[1..$].join("=");
    } else assert(false, "Invalid NLS data line: "~line);
  }
}

void setLanguage(char[] l="") { assert(l in nls); lang=l; }

char[][char[]][char[]] nls;
char[] lang;

char[] nl(char[] origin) {
  auto i=origin in nls[lang];
  if (!i) i=origin in nls[""];
  if (!i) assert(false, origin~" not found in language table!");
  return *i;
}
