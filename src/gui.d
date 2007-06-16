module gui;
import SDL, png, func, std.stdio, std.file, std.path: sep;

class FileSource {
  char[] basepath;
  this(char[] path=".") { basepath=path; }
  static FileSource opCall(char[] path=".") { return new FileSource(path); }
  void[] getFile(char[] name) {
    return read(basepath~sep~name);
  }
}

const invalid=size_t.max;

class Area {
  SDL_Rect me; SDL_Surface *mine;
  int w() { return me.w; } int h() { return me.h; }
  this(SDL_Rect  r, SDL_Surface *s) { me=r; mine=s; }
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
    dest.x=cast(short)x; dest.y=cast(short)y;
    dest.w=cast(ushort)w; dest.h=cast(ushort)h;
    SDL_Rect src=dest;
    src.x=0; src.y=0;
    return SDL_BlitSurface (surf, &src, mine, &dest);
  }
}

class Widget {
  abstract void draw (Area);
}

interface Generator {
  SDL_Surface *render(size_t xs, size_t ys);
}

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

long eatoi(char[] nr, int max) {
  assert(nr.length);
  if (nr[$-1]=='%') return (max*atoi(nr[0..$-1]))/100;
  return atoi(nr);
}

import xml, util, std.string;
class Frame : Widget {
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
  SDL_Surface *getSurf(char[] name, size_t w=invalid, size_t h=invalid) {
    auto entry=name in buffer;
    if (!entry || ((buffer[name].lastx!=w)&&(buffer[name].lasty!=h))) {
      Buffer newbuf; with (newbuf) {
        lastx=w; lasty=h;
        buf=parts[name].render(w, h);
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
    auto txt=cast(xmlText) thingie;
    if (txt) {
    // ifIs(thingie, (xmlText txt) { // triggers gdc bug \todo: reenable on .24
      res=new class(fsrc, txt.data) Generator {
        FileSource fs; char[] filename; this(FileSource _fs, char[] fn) { fs=_fs; filename=fn; }
        SDL_Surface *render(size_t xs, size_t ys) {
          assert((xs==invalid)&&(ys==invalid), format("Error: Tried to set image size: [", xs, ", ", ys, "]"));
          return decode(fs.getFile(filename));
        }
      };
    };
    auto tag=cast(xmlTag) thingie;
    if (tag) {
    // ifIs(thingie, (xmlTag tag) { // triggers a gdc bug \todo: reenable on .24
      assert(tag.children.length==1, "Invalid children length in "~tag.toString);
      switch (tag.name) {
        ///\todo: Fixed-shifting case!
        case "repeat":
          assert(tag.children.length==1);
          res=new class(generate(tag.children[0])) Generator {
            Generator sup; this(Generator _sup) { sup=_sup; }
            SDL_Surface *render(size_t xs, size_t ys) {
              // first acquire the surface above us
              auto s=sup.render(invalid, invalid);
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
            }
          };
          break;
        case "part":
          assert("from" in tag.attributes, "Error: part without from");
          assert("to" in tag.attributes, "Error: part without to");
          assert(tag.children.length==1, "Error: No surface below "~tag.toString);
          auto supergen=generate(tag.children[0]);
          // rectangle strings
          auto r_str=split(tag.attributes["from"], ",")~split(tag.attributes["to"], ",");
          foreach (inout text; r_str) text=strip(text);
          assert(r_str.length==4);
          res=new class (supergen, r_str) Generator {
            Generator sup; char[][] str;
            this(Generator sup, char[][] strings) { this.sup=sup; str=strings; }
            SDL_Surface *render(size_t xs, size_t ys) {
              assert((xs==invalid)&&(ys==invalid), format("Error: Tried to set image size of part: [", xs, ", ", ys, "]"));
              auto s=sup.render(xs, ys); scope(exit) SDL_FreeSurface(s);
              SDL_Surface *res=void;
              with (*s) res=MakeSurf(eatoi(str[2], w)-eatoi(str[0], w), eatoi(str[3], h)-eatoi(str[1], h), 32);
              SDL_Rect source=void;
              with (source) {
                x=cast(short)eatoi(str[0], s.w); y=cast(short)eatoi(str[1], s.h);
                w=cast(ushort)res.w; h=cast(ushort)res.h;
              }
              SDL_Rect dest=void; with (dest) x=y=0;
              SDL_BlitSurface(s, &source, res, &dest);
              return res;
            }
          };
          break;
        case "rotate":
          assert("mode" in tag.attributes, "Error: rotate without mode");
          assert(tag.children.length==1, "Error: No surface below "~tag.toString);
          auto mode=tag.attributes["mode"];
          res=new class (mode, generate(tag.children[0])) Generator {
            char[] mode; Generator sup; this(char[] m, Generator sup) { mode=m; this.sup=sup; }
            SDL_Surface *render(size_t sx, size_t sy) {
              SDL_Surface *ret=void;
              SDL_Surface *s; scope(exit) if (s) SDL_FreeSurface(s);
              switch (mode) {
                case "right":
                  s=sup.render(sy, sx);
                  with (*s) ret=MakeSurf(h, w, 32);
                  for (int x=0; x<ret.w; ++x) for (int y=0; y<ret.h; ++y) putpixel(ret, x, y, getpixel(s, y, s.h-1-x));
                  break;
                case "left":
                  s=sup.render(sy, sx);
                  with (*s) ret=MakeSurf(h, w, 32);
                  for (int x=0; x<ret.w; ++x) for (int y=0; y<ret.h; ++y) putpixel(ret, x, y, getpixel(s, s.w-1-y, x));
                  break;
                case "180":
                  s=sup.render(sx, sy);
                  with (*s) ret=MakeSurf(w, h, 32);
                  for (int x=0; x<ret.w; ++x) for (int y=0; y<ret.h; ++y) putpixel(ret, x, y, getpixel(s, s.w-1-x, s.h-1-y));
                  break;
                default: assert(false, "Unknown rotation mode: "~mode);
              }
              return ret;
            }
          };
          break;
        default: assert(false, "Unknown mode: "~tag.name);
      }
    };
    assert(res); return res;
  }
  /// constructor
  this(FileSource fsrc, xmlTag frame) {
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
    target.blit(getSurf("top-left"), 0, 0);
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
  }
}
