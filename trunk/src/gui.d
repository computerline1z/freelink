module gui;
import SDL, png, func, std.stdio, std.file, std.path: sep;

class FileSource {
  string basepath;
  this(string path=".") { basepath=path; }
  static FileSource opCall(string path=".") { return new FileSource(path); }
  void[] getFile(char[] name) {
    return read(basepath~sep~name);
  }
}

const invalid=size_t.max;

class Area {
  SDL_Rect me; SDL_Surface *mine;
  int w() { return me.w; } int h() { return me.h; }
  this(SDL_Rect r, SDL_Surface *s) { me=r; mine=s; }
  static Area opCall(SDL_Surface *s, SDL_Rect *r=null) {
    if (!r) {
      SDL_Rect full; with (full) { x=0; y=0; w=cast(ushort)s.w; h=cast(ushort)s.h; }
      return new Area(full, s);
    }
    return new Area(*r, s);
  }
  int blit (SDL_Surface *surf, size_t x=0, size_t y=0, size_t w=0, size_t h=0) { /// blit surf on me at x, y
    SDL_Rect dest = void;
    if (!w) w=cast(ushort)surf.w; if (!h) h=cast(ushort)surf.h;
    dest.x=cast(short)(x+me.x); dest.y=cast(short)(y+me.y);
    dest.w=cast(ushort)w; dest.h=cast(ushort)h;
    SDL_Rect src=dest;
    src.x=0; src.y=0;
    return SDL_BlitSurface (surf, &src, mine, &dest);
  }
  Area select(size_t x, size_t y, size_t w, size_t h) {
    SDL_Rect nr=void; nr.x=cast(short)(x+me.x); nr.y=cast(short)(y+me.y); nr.w=cast(ushort)w; nr.h=cast(ushort)h;
    return new Area(nr, mine);
  }
}

class Widget {
  abstract void draw (Area);
}

class ContainerWidget : Widget {
  private Widget _below;
  void below (Widget w) { _below=w; }
  Widget below () { return _below; }
}

alias SDL_Surface *delegate(size_t xs, size_t ys) Generator;

class Window : Widget {
  char[] title;
  SDL_Surface *titleBar, left, right, corner, bottom; // We can flip/copy corners right?
  this (char[] title) {
    this.title = title;
    titleBar = decode (read("../gfx/titlebar.png"));
  }

  void draw (Area target) {
    target.blit(titleBar, 10, 10);
  }
}

class Button : Widget {
  char[] caption;
  SDL_Surface *clickedImg, normalImg;
  bool clicked;
  void draw (Area target) {
    if (clicked) {
      target.blit (clickedImg, 10, 10);
    } else {
      target.blit (normalImg, 10, 10);
    }
  }
}

import SDL_ttf;
class Font {
  class RenderText : Widget {
    char[] caption;
    SDL_Surface *clickedImg, normalImg;
    bool clicked;
    SDL_Surface *surf;
    this(char[] text) { surf=f.render(text, white); }
    ~this() { SDL_FreeSurface(surf); }
    void draw (Area target) {
      target.blit(surf);
    }
  }
  TTF_FontClass f;
  this(void[] font, int size) { f=new TTF_FontClass(font, size); }
}
class Nothing : Widget { void draw (Area target) { } }

long eatoi(char[] nr, int max) {
  assert(nr.length);
  if (nr[$-1]=='%') return (max*atoi(nr[0..$-1]))/100;
  return atoi(nr);
}

RES delegate(size_t, size_t) myBind(RES, EXTRA...)(RES function(size_t, size_t, EXTRA) func, EXTRA e) {
  struct estorage {
    EXTRA e;
    RES function(size_t, size_t, EXTRA) fn;
    RES call(size_t w, size_t h) { return fn(w, h, e); }
  }
  auto res=new estorage;
  foreach (idx, value; e) res.e[idx]=value; res.fn=func;
  return &res.call;
}

import xml, util, std.string;
class Frame : ContainerWidget {
  FileSource fsrc;
  private {
    Generator [char[]] parts;
    struct Buffer {
      size_t lastx=invalid;
      size_t lasty=invalid;
      SDL_Surface *buf=null;
    }
    Buffer[char[]] buffer;
  }
  SDL_Surface *getSurf(string name, size_t w=invalid, size_t h=invalid) {
    auto entry=name in buffer;
    if (!entry || ((buffer[name].lastx!=w)&&(buffer[name].lasty!=h))) {
      Buffer newbuf; with (newbuf) {
        lastx=w; lasty=h;
        auto part=name in parts;
        assert(part, "Error: Cannot create surf for invalid name "~name);
        buf=(*part)(w, h);
      }
      if (entry) SDL_FreeSurface(entry.buf);
      buffer[name]=newbuf;
    }
    return buffer[name].buf;
  }
  //ubyte[] modes; invariant { assert(modes.length==4); }
  /// generate a SDL surface from an XML description
  private Generator generate(xmlElement thingie) {
    Generator res=null;
    // ifIs(thingie, (xmlText txt) { // triggers gdc bug \todo: reenable on .24
    auto txt=cast(xmlText) thingie;
    if (txt) {
      res=myBind(function(size_t xs, size_t ys, FileSource fs, char[] filename) {
        assert((xs==invalid)&&(ys==invalid), format("Error: Tried to set image size: [", xs, ", ", ys, "]"));
        return decode(fs.getFile(filename));
      }, fsrc, txt.data);
    }
    // ifIs(thingie, (xmlTag tag) { // triggers a gdc bug \todo: reenable on .24
    auto tag=cast(xmlTag) thingie;
    if (tag) {
      assert(tag.children.length==1, "Invalid children length in "~tag.toString);
      switch (tag.name) {
        ///\todo: Fixed-shifting case!
        case "repeat":
          assert(tag.children.length==1);
          res=myBind(function(size_t xs, size_t ys, Generator sup) {
            // first acquire the surface above us
            auto s=sup(invalid, invalid);
            assert ((xs!=invalid)||(ys!=invalid), "Error: Repeater: width _and_ height invalid; repeater pointless.");
            // X repetition first
            if (xs != invalid) {
              auto area=Area(MakeSurf(xs, s.h, 32)); // s repeated in x direction
              // now fill new surface with duplicates of s
              size_t offs=0;
              while (xs-offs>s.w) { // while there's space for a full repetition
                area.blit(s, offs, 0);
                offs+=s.w;
              }
              // if there's still space left at all, fill it
              if (xs-offs) area.blit(s, offs, 0, xs-offs, s.h);
              SDL_FreeSurface(s); s=area.mine;
            }
            // Now Y repetition .. basically the same again
            if (ys != invalid) {
              auto area=Area(MakeSurf(s.w, ys, 32));
              size_t offs=0;
              while (ys-offs>s.h) { // while there's space for a full repetition
                area.blit(s, 0, offs);
                offs+=s.h;
              }
              // if there's still space left at all, fill it
              if (ys-offs) area.blit(s, 0, offs, s.w, ys-offs);
              SDL_FreeSurface(s); s=area.mine;
            }
            return s;
          }, generate(tag.children[0]));
          break;
        case "part":
          assert("from" in tag.attributes, "Error: part without from");
          assert("to" in tag.attributes, "Error: part without to");
          assert(tag.children.length==1, "Error: No surface below "~tag.toString);
          auto supergen=generate(tag.children[0]);
          // rectangle strings
          char[][] r_str=map(split(tag.attributes["from"], ",")~split(tag.attributes["to"], ","), member!(string, "dup"));
          foreach (inout text; r_str) text=strip(text).dup;
          assert(r_str.length==4);
          res=myBind(function(size_t xs, size_t ys, Generator sup, char[][] str) {
            assert((xs==invalid)&&(ys==invalid), format("Error: Tried to set image size of part: [", xs, ", ", ys, "]"));
            SDL_Surface *s=sup(xs, ys); scope(exit) SDL_FreeSurface(s);
            writefln("Sup: ", s.w, "-", s.h);
            SDL_Surface *res=void;
            try {
              with (*s) res=MakeSurf(eatoi(str[2], w)-eatoi(str[0], w), eatoi(str[3], h)-eatoi(str[1], h), 32);
            } catch (Exception e) { writefln("Exception ", e); throw e; }
            SDL_Rect source=void;
            with (source) {
              x=cast(short)eatoi(str[0], s.w); y=cast(short)eatoi(str[1], s.h);
              w=cast(ushort)res.w; h=cast(ushort)res.h;
            }
            SDL_Rect dest=void; with (dest) x=y=0;
            SDL_BlitSurface(s, &source, res, &dest);
            return res;
          }, generate(tag.children[0]), r_str);
          break;
        case "rotate":
          assert("mode" in tag.attributes, "Error: rotate without mode");
          assert(tag.children.length==1, "Error: No surface below "~tag.toString);
          auto mode=tag.attributes["mode"];
          res=myBind(function(size_t xs, size_t ys, char[] mode, Generator sup) {
            SDL_Surface *ret=void;
            SDL_Surface *s; scope(exit) if (s) SDL_FreeSurface(s);
            switch (mode) {
              case "right":
                s=sup(ys, xs);
                with (*s) ret=MakeSurf(h, w, 32);
                for (int x=0; x<ret.w; ++x) for (int y=0; y<ret.h; ++y) putpixel(ret, x, y, getpixel(s, y, s.h-1-x));
                break;
              case "left":
                s=sup(ys, xs);
                with (*s) ret=MakeSurf(h, w, 32);
                for (int x=0; x<ret.w; ++x) for (int y=0; y<ret.h; ++y) putpixel(ret, x, y, getpixel(s, s.w-1-y, x));
                break;
              case "180":
                s=sup(xs, ys);
                with (*s) ret=MakeSurf(w, h, 32);
                for (int x=0; x<ret.w; ++x) for (int y=0; y<ret.h; ++y) putpixel(ret, x, y, getpixel(s, s.w-1-x, s.h-1-y));
                break;
              default: assert(false, "Unknown rotation mode: "~mode);
            }
            return ret;
          }, mode, generate(tag.children[0]));
          break;
        default: assert(false, "Unknown mode: "~tag.name);
      }
    }
    assert(res); return res;
  }
  /// constructor
  this(FileSource fsrc, xmlTag frame, Widget w) {
    below=w;
    this.fsrc=fsrc;
    assert(frame.name=="frame", "Frame tag data not actually frame");
    xmlElement[char[]] entries;
    char[][char[]] modestr;
    foreach (_ch; frame.children) {
      ifIs(_ch, (xmlTag ch) {
        assert(ch.children.length==1, "Invalid number of children in "~ch.toString);
        entries[ch.name]=ch.children[0];
        if ("mode" in ch.attributes) modestr[ch.name]=ch.attributes["mode"];
      });
    }
    // extract the SDL surfaces for the stuffies
    foreach (name, tree; entries) parts[name]=generate(tree);
  }
  void draw(Area target) {
    // draw the frame
    writefln("Frame");
    target.blit(getSurf("top-left"), 0, 0);
    writefln("/Frame");
    target.blit(getSurf("top-right"), target.w-getSurf("top-right").w, 0);
    target.blit(getSurf("bottom-left"), 0, target.h-getSurf("bottom-left").h);
    target.blit(getSurf("bottom-right"), target.w-getSurf("bottom-right").w, target.h-getSurf("bottom-right").h);

    // draw horizontal stripes
    target.blit(getSurf("top", target.w-getSurf("top-left").w-getSurf("top-right").w, invalid), getSurf("top-left").w, 0);
    auto bottom=getSurf("bottom", target.w-getSurf("bottom-left").w-getSurf("bottom-right").w, invalid);
    target.blit(bottom, getSurf("bottom-left").w, target.h-bottom.h);

    // draw vertical stripes
    target.blit(getSurf("left", invalid, target.h-getSurf("top-left").h-getSurf("bottom-left").h), 0, getSurf("top-left").h);
    auto right=getSurf("right", invalid, target.h-getSurf("top-right").h-getSurf("bottom-right").h);
    target.blit(right, target.w-right.w, getSurf("top-right").h);

    // draw below
    assert(below !is null);
    auto tlw=getSurf("top-left").w; auto tlh=getSurf("top-left").h;
    writefln("Now as for below .. ");
    below.draw(target.select(tlw, tlh, target.w-tlw-getSurf("bottom-right").w, target.h-tlh-getSurf("bottom-right").h));
  }
}
