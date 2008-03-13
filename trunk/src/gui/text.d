module gui.text;
import tools.base;
public import gui.base;
import contrib.SDL, contrib.SDL_ttf;
import std.stdio: format;

T take(T)(ref T[] array) {
  auto res=array[0];
  array=array[1..$];
  return res;
}

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
    int glyph_w, glyph_h;
    this(int w, int h) { glyph_w = w; glyph_h = h; }
    wchar[][] screen_area; /// [line] [column]
    size_t row, col; /// cursor position
    void write(wstring text) {
      if (row!<screen_area.length) throw new Exception(format("Row out of bounds: [0..", screen_area.length, "]"));
      while (text.length) {
        screen_area[row][col++]=text.take();
        if (col==screen_area[row].length) newline();
      }
    }
    void newline() {
      col=0;
      row++;
      while (row!<screen_area.length) {
        screen_area=screen_area[1..$]~new wchar[screen_area[$-1].length];
        --row;
      }
    }
    void backspace() {
      if (col) --col; else if (row) col=screen_area[--row].length-1;
    }
    void put(wchar ch) { if (screen_area.length>row) if (screen_area[row].length>col) screen_area[row][col]=ch; }
    void setRegion(Area target) {
      size_t xsize = target.w/glyph_w;
      screen_area.length=target.h/glyph_h;
      foreach (inout line; screen_area) line.length=xsize;
      super.setRegion(target);
    }
    void update() {
      foreach (line_nr, line; screen_area)
        foreach (col_nr, ch; line)
          with (area)
            with (select(col_nr * glyph_w/*+rand%2*/,
              line_nr * glyph_h/*+rand%2*/, glyph_w, glyph_h)) {
                clean; blit(getChar(ch));
              }
    }
    void draw() { update; } /// :sings: REDUNDANCY! F**K YEAH!
  }
  TTF_FontClass f;
  this(void[] font, int size) { f = new TTF_FontClass(font, size); }
}
