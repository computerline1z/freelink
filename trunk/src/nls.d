import std.utf, std.file, std.string, func, std.path: sep;

static this() {
  char[][char[]] init;
  nls[""]=init;
  map(
    map(
      filter(
        map(
          split(cast(char[])read("nls"~sep~"default.txt"), "\n"),/// split into lines
          (char[] c) { if (c.length&&(c[$-1]=='\r')) c=c[0..$-1]; return c; } /// remove trailing \r
        ), (char[] line) { return line.find("=")!=-1; }
      ), (char[] c) { auto s=c.split("="); return [s[0], s[1..$].join("=")].dup; } /// split at =
    ), (char[][] pair) { nls[""][pair[0]]=pair[1]; assert(pair.length==2); } /// assign to AA
  );
}

char[][char[]][char[]] nls;
char[] lang;

char[] nl(char[] origin) {
  auto i=origin in nls[lang];
  if (!i) i=origin in nls[""];
  if (!i) assert(false, origin~" not found in language table!");
  return *i;
}
