module gui;
import SDL, png, std.stdio, std.file, tools.ext, std.path: sep;

T min(T, U)(T a, U b) { return a<b?a:cast(T)b; }

class FileSource {
  string basepath;
  this(string path=".") { basepath=path; }
  static FileSource opCall(string path=".") { return new FileSource(path); }
  void[] getFile(char[] name) {
    return read(basepath~sep~name);
  }
}

const invalid=size_t.max;

final class Area {
  SDL_Rect me; SDL_Surface *mine;
  int w() { return me.w; } int h() { return me.h; }
  int x() { return me.x; } int y() { return me.y; }
  this(SDL_Rect r, SDL_Surface *s) { me=r; mine=s; }
  static Area opCall(Area a) { with (a) return Area(mine, &me); }
  static Area opCall(SDL_Surface *s, SDL_Rect *r=null) {
    if (!s) *(cast(int*)null)=0;
    if (!r) {
      SDL_Rect full; with (full) { x=0; y=0; w=cast(ushort)s.w; h=cast(ushort)s.h; }
      return new Area(full, s);
    }
    return new Area(*r, s);
  }
  int blit (SDL_Surface *surf, size_t x=0, size_t y=0, size_t w=0, size_t h=0) {
    return blit(Area(surf), x, y, w, h);
  }
  void clean() { SDL_FillRect(mine, &me, 0); }
  int blit (Area area, size_t x=0, size_t y=0, size_t w=0, size_t h=0) { /// blit area on me at x, y
    SDL_Rect dest = void;
    if (!w) w=min(cast(ushort)area.w, this.w); if (!h) h=min(cast(ushort)area.h, this.h);
    dest.x=cast(short)(x+me.x); dest.y=cast(short)(y+me.y);
    dest.w=cast(ushort)w; dest.h=cast(ushort)h;
    SDL_Rect src=dest;
    src.x=area.me.x; src.y=area.me.y;
    return SDL_BlitSurface (area.mine, &src, mine, &dest);
  }
  Area select(size_t x, size_t y, size_t w=invalid, size_t h=invalid) {
    assert(x<this.w);
    assert(y<this.h);
    if (w==invalid) w=this.w-x; if (h==invalid) h=this.h-y;
    assert(x+w<me.x+this.w);
    assert(y+h<me.y+this.h);
    SDL_Rect nr=void; nr.x=cast(short)(x+me.x); nr.y=cast(short)(y+me.y); nr.w=cast(ushort)w; nr.h=cast(ushort)h;
    return new Area(nr, mine);
  }
  bool sameSize(Area foo) { return (foo.w==w)&&(foo.h==h); }
  bool sameRect(Area foo) { return sameSize(foo)&&(foo.x==x)&&(foo.y==y); }
  bool sameSurf(Area foo) { return mine == foo.mine; }
  bool overlaps(Area foo) { return !((foo.x>x+w)||(foo.x+foo.w<x)||(foo.y>y+h)||(foo.y+foo.h<y)); }
  char[] toString() { return format("Area[", me.x, "-", me.y, " : ", me.w, "-", me.h, "]"); }
}

class Widget {
  bool tainted=false; void taint() { tainted=true; }
  //final void taintcheck(void delegate() dg) { if (tainted) { dg(); tainted=false; } }
  abstract void draw ();
  /// check if redraws are necessary
  abstract void update ();
  /// Where we live.
  private Area area=null;
  /// force setRegion to treat area as pristine
  void fullRedraw() { assert(area !is null, "Can't fullRedraw while area not set"); auto backup=area; area=null; setRegion(backup); }
  /// used to position/move the drawing region. Might trigger a re-draw.
  void setRegion(Area region) {
    assert(region.mine);
    if (area&&region.sameSurf(area)&&region.sameSize(area)) {
      if (!region.sameRect(area)) {
        if (!region.overlaps(area)) {
          region.blit(area);
          area=region;
        } else { area=region; draw; }
      }
    } else { area=region; draw; }
  }
}

class ContainerWidget : Widget {
  abstract void setRegion(Area region);
}

class FrameWidget : ContainerWidget {
  private Widget _below;
  void below (Widget w) { _below=w; }
  Widget below () { return _below; }
  void update() { below.update; }
}

interface Generator { SDL_Surface *opCall(size_t xs, size_t ys); }

class Stack : ContainerWidget {
  Widget[] widgets; int height; bool fillRest;
  this(int height, bool fillRest, Widget[] widgets...) { this.height=height; this.widgets=widgets; this.fillRest=fillRest; }
  void update() { foreach (w; widgets) w.update; }
  void setRegion(Area target) {
    assert(widgets.length*height<target.h);
    if (fillRest) {
      foreach (i, w; widgets[0..$-1]) w.setRegion(target.select(0, height*i, target.w, height));
      widgets[$-1].setRegion(target.select(0, (widgets.length-1)*height));
    } else foreach (i, w; widgets) w.setRegion(target.select(0, height*i, target.w, height));
  }
  void draw () { foreach (w; widgets) w.draw; }
}

alias bool delegate(ref wchar[], bool reset) TextGenerator;

T[] field(T)(size_t count, lazy T generate) {
  assert(!is(T==void));
  auto res=new T[count];
  foreach (inout v; res) v=generate();
  return res;
}

import SDL_ttf;
class Font {
  SDL_Surface*[wchar] buffer;
  ~this() { foreach (surf; buffer) SDL_FreeSurface(surf); }
  SDL_Surface *getChar(wchar ch) {
    if (ch==wchar.init) ch=' ';
    if (!(ch in buffer)) buffer[ch]=f.render(cast(char[])[ch], white);
    if (!buffer[ch]) buffer[ch]=getChar('?');
    if (!buffer[ch]) buffer[ch]=getChar('.');
    return buffer[ch];
  }
  class GridTextField : Widget {
    /// returns whether to re-call it (implies newline). Writes self into target.
    /// _May_ change target.
    // /// NO SUCH DELEGATE MUST EVER, AT A LATER TIME, RENDER LESS LINES THAN BEFORE.
    /// ^+-This restriction stems from an earlier phase in development.
    ///  +-It's not relevant anymore. Please ignore it.
    TextGenerator[] gens;
    int glyph_w, glyph_h; this(int w, int h) { glyph_w=w; glyph_h=h; }
    wchar[][] screen_area; /// [line] [column]
    void setRegion(Area target) {
      size_t xsize=target.w/glyph_w;
      screen_area=new wchar[][target.h/glyph_h]; foreach (inout line; screen_area) line=new wchar[xsize];
      super.setRegion(target);
    }
    private wchar[][] eval(size_t xchars, size_t ychars) {
      /// the last line each delegate has rendered.
      int[typeof(gens[0])] lastlines;
      /// [line] [column]
      auto res=field(ychars, new wchar[xchars]);
      auto work=res.dup;
      size_t current=0;
      foreach (gen; gens) {
        bool recall=false;
        bool initial=true;
        do {
          recall=gen(work[current], initial); /// render line into buffer
          initial=false;
          if (recall) { current++;}
          else lastlines[gen]=current;
          /// while the cursor is below the screen, expand the screen downwards.
          while (current>=work.length) {
            auto newline=new wchar[xchars];
            work~=newline; res~=newline;
          }
        } while (recall);
      }
      return res[$-ychars..$];
    }
    void update() {
      auto newScreen=eval(screen_area[0].length, screen_area.length);
      foreach (line_nr, line; newScreen)
        foreach (col_nr, ch; line)
          if (ch != screen_area[line_nr][col_nr])
            with (area) with (select(col_nr*glyph_w, line_nr*glyph_h, glyph_w, glyph_h)) {
              clean; blit(getChar(ch));
            }
      screen_area=newScreen;
    }
    void draw() { update; } /// :sings: REDUNDANCY! F**K YEAH!
  }
  TTF_FontClass f;
  this(void[] font, int size) { f=new TTF_FontClass(font, size); }
}
class Nothing : Widget { void draw (Area target) { } }

int eatoi(char[] nr, int max) {
  assert(nr.length);
  if (nr[$-1]=='%') return cast(int)(max*atoi(nr[0..$-1]))/100;
  return cast(int)atoi(nr);
}

template DefaultConstructor() { this(typeof(this.tupleof) t) { foreach (id, bogus; this.tupleof) this.tupleof[id]=cast(typeof(bogus))t[id]; } }

import xml, std.string;
class Frame : FrameWidget {
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
  /// generate a SDL surface from an XML description
  private Generator generate(xmlElement thingie) {
    Generator res=null;
    ifIs(thingie, (xmlText txt) { // triggers gdc bug \todo: reenable on .24
      res=new class(fsrc, txt.data) Generator {
        FileSource fs; char[] filename; mixin DefaultConstructor;
        SDL_Surface *opCall(size_t xs, size_t ys) {
          assert((xs==invalid)&&(ys==invalid), format("Error: Tried to set image size: [", xs, ", ", ys, "]"));
          return decode(fs.getFile(filename));
        }
      };
    });
    ifIs(thingie, (xmlTag tag) { // triggers a gdc bug \todo: reenable on .24
      assert(tag.children.length==1, "Invalid children length in "~tag.toString);
      switch (tag.name) {
        ///\todo: Fixed-shifting case!
        case "repeat":
          assert(tag.children.length==1);
          res=new class(generate(tag.children[0])) Generator {
            Generator sup; mixin DefaultConstructor;
            SDL_Surface *opCall(size_t xs, size_t ys) {
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
            }
          };
          break;
        case "part":
          assert("from" in tag.attributes, "Error: part without from");
          assert("to" in tag.attributes, "Error: part without to");
          assert(tag.children.length==1, "Error: No surface below "~tag.toString);
          auto supergen=generate(tag.children[0]);
          // rectangle strings
          //char[][] r_str=map(split(tag.attributes["from"], ",")~split(tag.attributes["to"], ","), member!(string, "dup"));
          char[][] r_str=(tag.attributes["from"].split(",")~tag.attributes["to"].split(","))
            ~maps!("_.dup")~toArray;
          foreach (ref text; r_str) text=strip(text).dup;
          assert(r_str.length==4);
          res=new class(generate(tag.children[0]), r_str) Generator {
            Generator sup; char[][] str; mixin DefaultConstructor;
            SDL_Surface *opCall(size_t xs, size_t ys) {
              assert((xs==invalid)&&(ys==invalid), format("Error: Tried to set image size of part: [", xs, ", ", ys, "]"));
              SDL_Surface *s=sup(xs, ys); scope(exit) SDL_FreeSurface(s);
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
          //res=myBind(function(size_t xs, size_t ys, char[] mode, Generator sup) {
          res=new class(mode, generate(tag.children[0])) Generator {
            char[] mode; Generator sup; mixin DefaultConstructor;
            SDL_Surface *opCall(size_t xs, size_t ys) {
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
            }
          };
          break;
        default: assert(false, "Unknown mode: "~tag.name);
      }
    });
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
        assert(!(ch.name in entries));
        entries[ch.name]=ch.children[0];
        if ("mode" in ch.attributes) modestr[ch.name]=ch.attributes["mode"];
      });
    }
    // extract the SDL surfaces for the stuffies
    foreach (name, tree; entries) parts[name]=generate(tree);
  }
  void setRegion(Area region) {
    auto tlw=getSurf("top-left").w; auto tlh=getSurf("top-left").h;
    with (area=region) below.setRegion(select(tlw, tlh, w-tlw-getSurf("bottom-right").w, h-tlh-getSurf("bottom-right").h));
    draw;
  }
  void draw() {
    with (area) {
      // draw the frame
      blit(getSurf("top-left"), 0, 0);
      blit(getSurf("top-right"), w-getSurf("top-right").w, 0);
      blit(getSurf("bottom-left"), 0, h-getSurf("bottom-left").h);
      blit(getSurf("bottom-right"), w-getSurf("bottom-right").w, h-getSurf("bottom-right").h);

      // draw horizontal stripes
      blit(getSurf("top", w-getSurf("top-left").w-getSurf("top-right").w, invalid), getSurf("top-left").w, 0);
      auto bottom=getSurf("bottom", w-getSurf("bottom-left").w-getSurf("bottom-right").w, invalid);
      blit(bottom, getSurf("bottom-left").w, h-bottom.h);

      // draw vertical stripes
      blit(getSurf("left", invalid, h-getSurf("top-left").h-getSurf("bottom-left").h), 0, getSurf("top-left").h);
      auto right=getSurf("right", invalid, h-getSurf("top-right").h-getSurf("bottom-right").h);
      blit(right, w-right.w, getSurf("top-right").h);

      // draw below
      assert(below !is null); below.draw;
    }
  }
}
