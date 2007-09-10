module gui.text;
import tools.base, tools.ext;
public import gui.base;
import contrib.SDL, contrib.SDL_ttf;

import std.random;
class Font {
  SDL_Surface*[wchar] buffer;
  ~this() { foreach (surf; buffer) SDL_FreeSurface(surf); }
  SDL_Surface *getChar(wchar ch) {
    if (ch == wchar.init) ch = ' ';
    if (!(ch in buffer)) buffer[ch] = f.render(cast(char[])[ch], white);
    if (!buffer[ch]) buffer[ch] = getChar('?');
    if (!buffer[ch]) buffer[ch] = getChar('.');
    return buffer[ch];
  }
  class GridTextField : Widget {
    /// returns whether to re-call it (implies newline). Writes self into target.
    /// _May_ change target.
    // /// NO SUCH DELEGATE MUST EVER, AT A LATER TIME, RENDER LESS LINES THAN BEFORE.
    /// ^+-This restriction stems from an earlier phase in development.
    ///  +-It's not relevant anymore. Please ignore it.
    TextGenerator[] gens;
    int glyph_w, glyph_h;
    this(int w, int h) { glyph_w = w; glyph_h = h; }
    wchar[][] screen_area; /// [line] [column]
    void setRegion(Area target) {
      size_t xsize = target.w/glyph_w;
      screen_area = new wchar[][target.h / glyph_h];
      foreach (inout line; screen_area) line = new wchar[xsize];
      super.setRegion(target);
    }
    private wchar[][] eval(size_t xchars, size_t ychars) {
      /// the last line each delegate has rendered.
      int[typeof(gens[0])] lastlines;
      /// [line] [column]
      auto res = field(ychars, new wchar[xchars]);
      auto work = res.dup;
      size_t current = 0;
      foreach (gen; gens) {
        bool recall = false;
        bool initial = true;
        do {
          recall = gen(work[current], initial); /// render line into buffer
          initial = false;
          if (recall) { current++;}
          else lastlines[gen] = current;
          /// while the cursor is below the screen, expand the screen downwards.
          while (current >= work.length) {
            auto newline = new wchar[xchars];
            work ~= newline; res ~= newline;
          }
        } while (recall);
      }
      return res[$ - ychars..$];
    }
    void update() {
      auto newScreen = eval(screen_area[0].length, screen_area.length);
      foreach (line_nr, line; newScreen)
        foreach (col_nr, ch; line)
          if (ch != screen_area[line_nr][col_nr])
            with (area) with (select(col_nr * glyph_w+rand%3,
                              line_nr * glyph_h+rand%3, glyph_w, glyph_h)) {
                                clean; blit(getChar(ch));
                              }
      screen_area = newScreen;
    }
    void draw() { update; } /// :sings: REDUNDANCY! F**K YEAH!
  }
  TTF_FontClass f;
  this(void[] font, int size) { f = new TTF_FontClass(font, size); }
}

bool writeOn(wchar[] target, ref size_t offset, wchar[][] text...) {
  if (offset==size_t.max) {
    return false; /// Ensure the final newline
  }
  wchar[] str=(iterate(text)~reduces!("_~=__"))[offset..$];
  if (str.length>target.length) {
    target[0..$]=str[0..target.length];
    offset+=target.length;
    return true;
  } else {
    target[0..str.length]=str;
    offset=size_t.max; /// last newline
    return true;
  }
}

TextGenerator WriteGrid(wchar[] text) {
  struct holder {
    wchar[] text;
    size_t offset;
    bool call(wchar[] target, bool reset) { if (reset) offset=0; return writeOn(target, offset, text); }
  }
  auto foo=new holder; foo.text=text; return &foo.call;
}
