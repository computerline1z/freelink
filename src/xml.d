module xml;

import mystring, tools.functional;

interface xmlElement { char[] toString(); };

class xmlText : xmlElement {
  final char[] data;
  this(char[] whut) { data = whut; }
  char[] toString() { return '"'~data~'"'; }
}

class xmlTag : xmlElement {
  char[] name;
  char[][char[]] attributes;
  xmlElement[] children;
  char[] toString() {
    char[] res = "<" ~ name;
    /// quoted strings
    foreach (id, text; attributes) res ~= " [" ~ id ~ "]=" ~ '"'~text~'"';
    res ~= ">";
    foreach (elem; children) res ~= elem.toString;
    res ~= "</" ~ name ~ ">";
    return res;
  }
}

xmlTag parse(void[] xml) { return parse(cast(char[])xml); }
xmlTag parse(char[] xml) {
  /// generate a flat list first
  xmlElement[] list;
  void addText(char[] c) {
    if (list.length)
      if (auto t=cast(xmlText) list[$-1]) list[$ - 1] = new xmlText(t.data ~ c);
      else list ~= new xmlText(c);
    else
      list ~= new xmlText(c);
  }
  size_t nextTag = xml.find("<");
  while (nextTag != -1) {
    addText(xml[0..nextTag]);
    xml=xml[nextTag + 1..$];
    char[][] parts; parts.length = 1; // space separated

    assert(xml.find(">") != -1);
    size_t endTag = xml.find(">");

    enum tmMode { normal, string }
    auto mode = tmMode.normal;
    /// read tag into parts
    foreach (ch; xml[0..endTag]) {
      switch (mode) {
        case tmMode.normal:
          if (ch == '"') { mode = tmMode.string; continue; }
          if (ch == ' ') { parts.length = parts.length + 1; continue; }
          parts[$-1] ~= ch;
          break;
        case tmMode.string:
          if (ch == '"') { mode = tmMode.normal; continue; }
          parts[$-1] ~= ch;
          break;
        default: assert(false, "uh wtf");
      }
    }

    auto newtag=new xmlTag;
    with (newtag) {
      name=parts[0];
      foreach (pair; parts[1..$] /map/ (&splitOff /reverse /curry)("=")) attributes[pair._0] = pair._1.dup;
    }
    list ~= newtag;
    xml = xml[endTag + 1..$];
    nextTag = xml.find("<");
  }
  list ~= new xmlText(xml);
  /// filter practically empty tags
  list = list /select/ (xmlElement e) {
    bool keep = true;
    if (auto tx = cast(xmlText) e) {
      if (tx.data.length)
        foreach (ch; tx.data)
          if (ch != ' ' && ch != '\n' && ch != '\r')
            return true;
      return false;
    } else return true;
  };
  /// okay now
  /// while there's still unprocessed tags in the list
  /// take them, and recurse
  /// return when found the respective ending tag
  xmlElement[] treeify(char[] scopename = "") {
    xmlElement[] res;
    while (list.length) {
      xmlElement current = list[0]; list = list[1..$];
      auto tag = cast(xmlTag) current;
      if (tag) {
        if (tag.name[0] == '/') {
          if (tag.name[1..$] != scopename)
            throw new Exception("Invalid structure: " ~ tag.name[1..$]
                                ~ " closed but " ~ scopename ~ " still open");
          return res;
        } else {
          tag.children = treeify(tag.name);
          res ~= tag; // fill tag up and append
        }
      } else res ~= current;
    }
    if (scopename.length)
      throw new Exception("Invalid structure: " ~ scopename ~ " never closed");
    return res;
  }
  auto root = new xmlTag;
  root.children = treeify;
  return root;
}
