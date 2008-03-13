module gui.frame;
import gui.base;
import xml, std.string, std.stdio, contrib.SDL, png, tools.functional;

class Frame : FrameWidget {
  FileSource fsrc;
  private {
    Generator [char[]] parts;
    struct Buffer {
      size_t lastx = invalid;
      size_t lasty = invalid;
      SDL_Surface *buf = null;
    }
    Buffer[char[]] buffer;
  }
  SDL_Surface *getSurf(string name, size_t w = invalid, size_t h = invalid) {
    auto entry = name in buffer;
    if (!entry || (buffer[name].lastx != w && buffer[name].lasty != h)) {
      Buffer newbuf; with (newbuf) {
        lastx = w; lasty = h;
        auto part = name in parts;
        assert(part, "Error: Cannot create surf for invalid name " ~ name);
        buf = (*part)(w, h);
      }
      if (entry) SDL_FreeSurface(entry.buf);
      buffer[name] = newbuf;
    }
    return buffer[name].buf;
  }
  /// generate an SDL surface from an XML description
  private Generator generate(xmlElement thingie) {
    Generator res = null;
    if (auto txt=cast(xmlText) thingie) {
      res = new class(fsrc, txt.data) Generator {
        FileSource fs; char[] filename; mixin DefaultConstructor;
        SDL_Surface *opCall(size_t xs, size_t ys) {
          assert(xs == invalid && ys == invalid ,
                 format("Error: Tried to set image size: [",
                        xs, ", ", ys, "]"));
          return decode(fs.getFile(filename));
        }
      };
    }
    if (auto tag=cast(xmlTag) thingie) {
      assert(tag.children.length == 1,
             "Invalid children length in " ~ tag.toString);
      switch (tag.name) {
        ///\todo: Fixed-shifting case!
        case "repeat":
          assert(tag.children.length == 1);
          res = new class(generate(tag.children[0])) Generator {
            Generator sup; mixin DefaultConstructor;
            SDL_Surface *opCall(size_t xs, size_t ys) {
              // first acquire the surface above us
              auto s = sup(invalid, invalid);
              assert (xs != invalid || ys != invalid,
                      "Error: Repeater: width _and_ height invalid; repeater pointless.");
              // X repetition first
              if (xs != invalid) {
                auto area = Area(MakeSurf(xs, s.h, 32)); // s repeated in x direction
                // now fill new surface with duplicates of s
                size_t offs = 0;
                while (xs-offs > s.w) {
                  // while there's space for a full repetition
                  area.blit(s, offs, 0);
                  offs += s.w;
                }
                // if there's still space left at all, fill it
                if (xs - offs) area.blit(s, offs, 0, xs - offs, s.h);
                SDL_FreeSurface(s);
                s = area.mine;
              }
              // Now Y repetition .. basically the same again
              if (ys != invalid) {
                auto area = Area(MakeSurf(s.w, ys, 32));
                size_t offs = 0;
                while (ys - offs > s.h) {
                  // while there's space for a full repetition
                  area.blit(s, 0, offs);
                  offs += s.h;
                }
                // if there's still space left at all, fill it
                if (ys - offs) area.blit(s, 0, offs, s.w, ys - offs);
                SDL_FreeSurface(s); s = area.mine;
              }
              return s;
            }
          };
          break;
        case "part":
          assert("from" in tag.attributes, "Error: part without from");
          assert("to" in tag.attributes, "Error: part without to");
          assert(tag.children.length == 1, "Error: No surface below "~tag.toString);
          auto supergen = generate(tag.children[0]);
          // rectangle strings
          //char[][] r_str = map(split(tag.attributes["from"], ",")~split(tag.attributes["to"], ","), member!(string, "dup"));
          char[][] r_str = (tag.attributes["from"].split(",")~tag.attributes["to"].split(","))
            /map/ expr!("$.dup");
          foreach (ref text; r_str) text = strip(text).dup;
          assert(r_str.length == 4);
          res = new class(generate(tag.children[0]), r_str) Generator {
            Generator sup; char[][] str; mixin DefaultConstructor;
            SDL_Surface *opCall(size_t xs, size_t ys) {
              assert(xs == invalid && ys == invalid,
                     format("Error: Tried to set image size of part: [",
                            xs, ", ", ys, "]"));
              SDL_Surface *s = sup(xs, ys);
              scope(exit) SDL_FreeSurface(s);
              SDL_Surface *res = void;
              with (*s) res = MakeSurf(eatoi(str[2], w) - eatoi(str[0], w),
                                       eatoi(str[3], h) - eatoi(str[1], h), 32);
              SDL_Rect source = void;
              with (source) {
                x = cast(short)eatoi(str[0], s.w);
                y = cast(short)eatoi(str[1], s.h);
                w = cast(ushort)res.w; h = cast(ushort)res.h;
              }
              SDL_Rect dest = void; with (dest) x = y = 0;
              SDL_BlitSurface(s, &source, res, &dest);
              return res;
            }
          };
          break;
        case "rotate":
          assert("mode" in tag.attributes, "Error: rotate without mode");
          assert(tag.children.length == 1, "Error: No surface below "~tag.toString);
          auto mode = tag.attributes["mode"];
          //res = myBind(function(size_t xs, size_t ys, char[] mode, Generator sup) {
          res = new class(mode, generate(tag.children[0])) Generator {
            char[] mode; Generator sup; mixin DefaultConstructor;
            SDL_Surface *opCall(size_t xs, size_t ys) {
              SDL_Surface *ret = void;
              SDL_Surface *s; scope(exit) if (s) SDL_FreeSurface(s);
              switch (mode) {
                case "right":
                  s = sup(ys, xs);
                  with (*s) ret = MakeSurf(h, w, 32);
                  for (int x = 0; x < ret.w; ++x)
                    for (int y = 0; y < ret.h; ++y)
                      putpixel(ret, x, y, getpixel(s, y, s.h - 1 - x));
                  break;
                case "left":
                  s = sup(ys, xs);
                  with (*s) ret = MakeSurf(h, w, 32);
                  for (int x = 0; x < ret.w; ++x)
                    for (int y = 0; y < ret.h; ++y)
                      putpixel(ret, x, y, getpixel(s, s.w - 1 - y, x));
                  break;
                case "180":
                  s = sup(xs, ys);
                  with (*s) ret = MakeSurf(w, h, 32);
                  for (int x = 0; x < ret.w; ++x)
                    for (int y = 0; y < ret.h; ++y)
                      putpixel(ret, x, y, getpixel(s, s.w - 1 - x,
                                                   s.h - 1 - y));
                  break;
                default: assert(false, "Unknown rotation mode: " ~ mode);
              }
              return ret;
            }
          };
          break;
        default: assert(false, "Unknown mode: " ~ tag.name);
      }
    }
    assert(res); return res;
  }
  /// constructor
  this(FileSource fsrc, xmlTag frame, Widget w) {
    below = w;
    this.fsrc = fsrc;
    assert(frame.name == "frame", "Frame tag data not actually frame");
    xmlElement[char[]] entries;
    char[][char[]] modestr;
    foreach (_ch; frame.children) {
      if (auto ch=cast(xmlTag) _ch) {
        assert(ch.children.length == 1,
               "Invalid number of children in " ~ ch.toString);
        assert(!(ch.name in entries));
        entries[ch.name] = ch.children[0];
        if ("mode" in ch.attributes) modestr[ch.name] = ch.attributes["mode"];
      }
    }
    // extract the SDL surfaces for the stuffies
    foreach (name, tree; entries) parts[name] = generate(tree);
  }
  void setRegion(Area region) {
    auto tlw = getSurf("top-left").w; auto tlh = getSurf("top-left").h;
    auto bottom_right=getSurf("bottom-right");
    with (area = region)
      below.setRegion(select(tlw, tlh, w - tlw - bottom_right.w,
                             h - tlh - bottom_right.h));
    draw;
  }
  void draw() {
    with (area) {
      // draw the frame
      blit(getSurf("top-left"), 0, 0);
      blit(getSurf("top-right"), w - getSurf("top-right").w, 0);
      blit(getSurf("bottom-left"), 0, h - getSurf("bottom-left").h);
      blit(getSurf("bottom-right"), w - getSurf("bottom-right").w,
           h - getSurf("bottom-right").h);

      // draw horizontal stripes
      blit(getSurf("top", w-getSurf("top-left").w - getSurf("top-right").w,
                   invalid), getSurf("top-left").w, 0);
      auto bottom = getSurf("bottom", w - getSurf("bottom-left").w
                                      - getSurf("bottom-right").w, invalid);
      blit(bottom, getSurf("bottom-left").w, h - bottom.h);

      // draw vertical stripes
      blit(getSurf("left", invalid, h - getSurf("top-left").h
                                    - getSurf("bottom-left").h),
           0, getSurf("top-left").h);
      auto right = getSurf("right", invalid, h - getSurf("top-right").h
                                             - getSurf("bottom-right").h);
      blit(right, w - right.w, getSurf("top-right").h);

      // draw below
      assert(below !is null); below.draw;
    }
  }
}
