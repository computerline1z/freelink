module gui.text;
import gui.base, tools.base;
import contrib.SDL, contrib.SDL_ttf;

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
