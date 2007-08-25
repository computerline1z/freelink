module xml;

import mystring, tools.ext;

interface xmlElement { char[] toString(); };

class xmlText : xmlElement {
  final char[] data;
  this(char[] whut) { data=whut; }
  char[] toString() { return "\""~data~"\""; } // "
}

class xmlTag : xmlElement {
  char[] name;
  char[][char[]] attributes;
  xmlElement[] children;
  char[] toString() {
    char[] res="<"~name;
    foreach (id, text; attributes) res~=" ["~id~"]=\""~text~"\""; // "
    res~=">";
    foreach (elem; children) res~=elem.toString;
    res~="</"~name~">";
    return res;
  }
}

xmlTag parse(void[] xml) { return parse(cast(char[])xml); }
xmlTag parse(char[] xml) {
  /// generate a flat list first
  xmlElement[] list;
  void addText(char[] c) {
    void addInstead() { list~=new xmlText(c); }
    if (list.length) ifIs(list[$-1], (xmlText t) { list[$-1]=new xmlText(t.data~c); },/*else*/ &addInstead); else addInstead;
  }
  size_t nextTag=xml.find("<");
  while (nextTag!=-1) {
    addText(xml[0..nextTag]);
    xml=xml[nextTag+1..$];
    char[][] parts; parts.length=1; /// space separated

    assert(xml.find(">")!=-1);
    size_t endTag=xml.find(">");

    enum tmMode { normal, string }
    auto mode=tmMode.normal;
    /// read tag into parts
    foreach (ch; xml[0..endTag]) {
      switch (mode) {
        case tmMode.normal:
          if (ch=='"') { mode=tmMode.string; continue; }
          if (ch==' ') { parts.length=parts.length+1; continue; }
          parts[$-1]~=ch;
          break;
        case tmMode.string:
          if (ch=='"') { mode=tmMode.normal; continue; }
          parts[$-1]~=ch;
          break;
        default: assert(false, "uh wtf");
      }
    }

    auto newtag=new xmlTag;
    with (newtag) {
      name=parts[0];
      foreach (pair;
        parts[1..$]~map((char[] c) {
          auto sp=c.split("="); return [sp[0], sp[1..$].join("=")].dup;
        })) {
        attributes[pair[0]]=pair[1].dup;
      }
    }
    list~=newtag;
    xml=xml[endTag+1..$];
    nextTag=xml.find("<");
  }
  list~=new xmlText(xml);
  /// filter practically empty tags
  list=list~filter((xmlElement e) { bool keep=true; ifIs(e, (xmlText tx) {
    if (!tx.data.length) keep=false;
    else {
      keep=false;
      foreach (ch; tx.data) if ((ch!=' ')&&(ch!='\n')&&(ch!='\r')) { keep=true; break; }
    }
  }); return keep; })~toArray;
  /// okay now
  /// while there's still unprocessed tags in the list
  /// take them, and search for the respective ending tag
  /// when found, recurse
  void treeify(ref xmlElement[] array) {
    size_t pos=0;
    while (pos<array.length) {
      ifIs(array[pos], (xmlTag tag) {
        size_t endpos=pos+1;
        while (endpos<array.length) {
          bool found=false;
          ifIs(array[endpos], (xmlTag etag) { if (etag.name=="/"~tag.name) found=true; });
          if (found) break;
          endpos++;
        }
        if (endpos==array.length) assert(false, tag.name~": closing tag not found");
        /// now remove array[pos+1..endpos] from the array; endpos not included.
        xmlElement[] sublist=array[pos+1..endpos];
        array=array[0..pos+1]~array[endpos+1..$]; /// neatly cut it out, keeping pos
        /// ... recurse
        treeify(sublist);
        tag.children=sublist; /// aaaand tree it.
      });
      ++pos;
    }
  }
  treeify(list);
  auto root=new xmlTag; root.children=list;
  return root;
}
