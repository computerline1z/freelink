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
  this(SDL_Rect  r, SDL_Surface *s) { me=r; mine=s; }
  static Area opCall(SDL_Surface *s, SDL_Rect *r=null) {
    if (!r) {
      SDL_Rect full; with (full) { x=0; y=0; w=cast(ushort)s.w; h=cast(ushort)s.h; }
      return new Area(full, s);
    }
    return new Area(*r, s);
  }
  int blit (SDL_Surface *surf, ushort x, ushort y) { /// blit surf on me at x, y
    SDL_Rect dest = void;
    dest.x=cast(short)x; dest.y=cast(short)y;
    return SDL_BlitSurface (surf, null, mine, &dest);
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

import xml, util, std.string;
class Frame : Widget {
  FileSource fsrc;
  Widget[char[]] parts;
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
          auto supersurf=getSurface(tag.children[0]);
          // rectangle strings
          auto r_str=split(tag.attributes["from"], ",")~split(tag.attributes["to"], ",");
          foreach (inout text; r_str) text=strip(text);
          long[4] rect; // top-x, top-y, bottom-x, bottom-y
          if (r_str[0][$-1]=='%') rect[0]=(supersurf.w*atoi(r_str[0][0..$-1]))/100; else rect[0]=atoi(r_str[0]);
          if (r_str[1][$-1]=='%') rect[1]=(supersurf.h*atoi(r_str[1][0..$-1]))/100; else rect[1]=atoi(r_str[1]);
          if (r_str[2][$-1]=='%') rect[2]=(supersurf.w*atoi(r_str[2][0..$-1]))/100-1; else rect[2]=atoi(r_str[2])-1;
          if (r_str[3][$-1]=='%') rect[3]=(supersurf.h*atoi(r_str[3][0..$-1]))/100-1; else rect[3]=atoi(r_str[3])-1;
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
          auto supersurf=getSurface(tag.children[0]); // get surface above
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
    char[][char[]] modes;
    foreach (_ch; frame.children) {
      ifIs(_ch, (xmlTag ch) {
        assert(ch.children.length==1, "Invalid number of children in "~ch.toString);
        entries[ch.name]=ch.children[0];
        assert("mode" in ch.attributes, "No mode specification in "~ch.toString);
        modes[ch.name]=ch.attributes["mode"];
      });
    }
    // extract the SDL surfaces for the stuffies
    SDL_Surface*[char[]] surfs;
    foreach (name, tree; entries) surfs[name]=getSurface(tree);
    
    // use the modes to determine the border sizes
    int[][char[]] sizes; // top-left, top, top-right, left, right, bottom-left, bottom, right
    foreach (name, mode; modes) {
      char[] xmode, ymode;
      if (mode.find(",")!=-1) {
        auto sp=mode.split(",");
        assert(sp.length==2, "Property error in mode "~mode);
        xmode=sp[0]; ymode=sp[1];
      } else xmode=ymode=mode;
      xmode=strip(xmode); ymode=strip(ymode);
      // mode can be fixed, repeat, stretch ... only fixed locks the size
      ubyte[char[]] match; match=["fixed".dup: 1, "repeat": 0, "stretch": 0];
      assert(xmode in match, "Unknown mode: "~xmode);
      assert(ymode in match, "Unknown mode: "~ymode);
      assert(name in surfs, "Unknown surface: "~name);
      sizes[name]=[[-1, surfs[name].w][match[xmode]], [-1, surfs[name].h][match[ymode]]];
    }
    // now use the sizes to determine the width of top, left, right and bottom border.
    int getSize(int arrayOffs, char[][] comps...) {
      // all fixed components must have the same size, and there must be at least one fixed component.
      auto sizes=map(comps, (char[] c) { assert(c in sizes, "Warning: size "~c~" does not exist"); return sizes[c][arrayOffs]; });
      int size=-1;
      foreach (s; sizes)
        if (size!=-1) {
          if (s!=-1)
            assert(s==size, "Size conflict: fixed "~.toString(s)~" vs fixed "~.toString(size));
        } else size=s;
      assert(size!=-1, format("Size error: components ", comps, ", being ", sizes, ", do not define a size"));
      return size;
    }
    auto bordersizes=[getSize(1, "top-left", "top", "top-right"), getSize(0, "top-left", "left", "bottom-left"),
      getSize(0, "top-right", "right", "bottom-right"), getSize(1, "bottom-left", "bottom", "bottom-right")];
    writefln("Border sizes: ", bordersizes);
    std.c.stdlib.exit(0);
  }
  void draw(Area target) {
  }
}
