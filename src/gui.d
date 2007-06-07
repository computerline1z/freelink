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
  int blit (SDL_Surface *surf, int x, int y, int w=0, int h=0) {
    return blit(surf, cast(ushort)x, cast(ushort)y, cast(ushort)w, cast(ushort)h);
  }
  int blit (SDL_Surface *surf, ushort x, ushort y, ushort w=0, ushort h=0) { /// blit surf on me at x, y
    SDL_Rect dest = void;
    if (!w) w=cast(ushort)surf.w; if (!h) h=cast(ushort)surf.h;
    dest.x=cast(short)x; dest.y=cast(short)y;
    dest.w=w; dest.h=h;
    SDL_Rect src=dest;
    src.x=0; src.y=0;
    return SDL_BlitSurface (surf, &src, mine, &dest);
  }
}

class Widget {
  abstract void draw (Area);
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
  SDL_Surface *[char[]] parts;
  ubyte[] modes; invariant { assert(modes.length==4); }
  /// generate a SDL surface from an XML description
  private SDL_Surface *getSurface(xmlElement thingie) {
    SDL_Surface *res=null;
    ifIs(thingie, (xmlText txt) {
      res=decode(fsrc.getFile(txt.data));
    });
    ifIs(thingie, (xmlTag tag) {
      assert(tag.children.length==1, "Invalid children length in "~tag.toString);
      switch (tag.name) {
        case "part":
          assert("from" in tag.attributes, "Error: part without from");
          assert("to" in tag.attributes, "Error: part without to");
          assert(tag.children.length==1, "Error: No surface below "~tag.toString);
          auto supersurf=getSurface(tag.children[0]); scope(exit) if (supersurf) SDL_FreeSurface(supersurf);
          // rectangle strings
          auto r_str=split(tag.attributes["from"], ",")~split(tag.attributes["to"], ",");
          foreach (inout text; r_str) text=strip(text);
          // top-x, top-y, bottom-x, bottom-y
          long[4] rect;
          with (*supersurf) rect[]=[eatoi(r_str[0], w), eatoi(r_str[1], h), eatoi(r_str[2], w), eatoi(r_str[3], h)];
          res=MakeSurf(rect[2]-rect[0], rect[3]-rect[1], 32);
          SDL_Rect source=void;
          with (source) {
            x=cast(short)rect[0];
            y=cast(short)rect[1];
            w=cast(ushort)res.w;
            h=cast(ushort)res.h;
          }
          SDL_Rect dest=void; with (dest) { x=0; y=0; }
          // blit selected area into target surface
          SDL_BlitSurface(supersurf, &source, res, &dest);
          break;
        case "rotate":
          assert("mode" in tag.attributes, "Error: rotate without mode");
          assert(tag.children.length==1, "Error: No surface below "~tag.toString);
          auto supersurf=getSurface(tag.children[0]); scope(exit) SDL_FreeSurface(supersurf);
          auto mode=tag.attributes["mode"];
          switch (mode) {
            case "right":
              res=MakeSurf(supersurf.h, supersurf.w, 32);
              for (int x=0; x<res.w; ++x) for (int y=0; y<res.h; ++y)
                putpixel(res, x, y, getpixel(supersurf, y, supersurf.h-1-x));
              break;
            case "left":
              res=MakeSurf(supersurf.h, supersurf.w, 32);
              for (int x=0; x<res.w; ++x) for (int y=0; y<res.h; ++y)
                putpixel(res, x, y, getpixel(supersurf, supersurf.w-1-y, x));
              break;
            case "180":
              res=MakeSurf(supersurf.w, supersurf.h, 32);
              for (int x=0; x<res.w; ++x) for (int y=0; y<res.h; ++y)
               putpixel(res, x, y, getpixel(supersurf, supersurf.w-x-1, supersurf.h-y-1));
              break;
            default: assert(false, "Unknown rotate mode: "~mode);
          }
          break;  
        default: assert(false, "Unknown transformation: "~tag.name);
      }
    });
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
    foreach (name, tree; entries) parts[name]=getSurface(tree);
    
    // use the modes to determine the border sizes
    foreach (n; ["top-left", "top-right", "bottom-left", "bottom-right"])
      assert(!(n in modestr), "Error: The size of corners is determined by the sides");
    foreach (n; ["top", "left", "right", "bottom"])
      assert(n in modestr, "Error: Side "~n~" : Scale mode not defined");
    void mustBeEqual(int a, int b, int c) {
      assert((a==b)&&(a==c), format("Error: Sizes ", a, ", ", b, ", ", c, " unequal!"));
    }
    mustBeEqual(parts["top-left"].h, parts["top"].h, parts["top-right"].h);
    mustBeEqual(parts["bottom-left"].h, parts["bottom"].h, parts["bottom-right"].h);
    mustBeEqual(parts["top-left"].w, parts["left"].w, parts["bottom-left"].w);
    mustBeEqual(parts["top-right"].w, parts["right"].w, parts["bottom-right"].w);
    static ubyte[char[]] map; if (!map.keys.length)
      map=["repeat".dup: 0, "stretch": 1];
    modes=[map[modestr["top"]], map[modestr["left"]], map[modestr["right"]], map[modestr["bottom"]]];
  }
  void draw(Area target) {
    // draw the frame
    target.blit(parts["top-left"], 0, 0);
    target.blit(parts["top-right"], target.w-parts["top-right"].w, 0);
    target.blit(parts["bottom-left"], 0, target.h-parts["bottom-left"].h);
    target.blit(parts["bottom-right"], target.w-parts["bottom-right"].w, target.h-parts["bottom-right"].h);
    
    foreach (m; modes) assert(m==0, r"\todo: implement stretching");
    
    // draw horizontal stripes
    int offs=parts["top-left"].w;
    while (offs+parts["top"].w<target.w-parts["top-right"].w) {
      target.blit(parts["top"], offs, 0);
      target.blit(parts["bottom"], offs, target.h-parts["bottom"].h);
      offs+=parts["top"].w;
    }
    target.blit(parts["top"], offs, 0, target.w-parts["top-right"].w-offs, parts["top"].h);
    target.blit(parts["bottom"], offs, target.h-parts["bottom"].h, target.w-parts["top-right"].w-offs, parts["top"].h);
    
    // draw vertical stripes
    offs=parts["top-left"].h;
    while (offs+parts["left"].h<target.h-parts["bottom-left"].h) {
      target.blit(parts["left"], 0, offs);
      target.blit(parts["right"], target.w-parts["right"].w, offs);
      offs+=parts["left"].h;
    }
    target.blit(parts["left"], 0, offs, parts["left"].w, target.h-parts["bottom-left"].h-offs);
    target.blit(parts["right"], target.w-parts["right"].w, offs, parts["left"].w, target.h-parts["bottom-left"].h-offs);
  }
}
