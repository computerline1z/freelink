module SDL_ttf;
import SDL;

struct fontsettings {
  bool bold=false;
  bool italic=false;
  bool underline=false;
}

import std.string: toStringz, toString;

class TTF_FontClass {
  static this() { if (!TTF_WasInit) TTF_Init; }
  static ~this() { if (TTF_WasInit) TTF_Quit; }
  private TTF_Font *font;
  int height() { return TTF_FontHeight(font); }
  int ascent() { return TTF_FontAscent(font); }
  int descent() { return TTF_FontDescent(font); }
  int lineskip() { return TTF_FontLineSkip(font); }
  static fontsettings Default;

  SDL_Surface *render(char[] text, SDL_Color fg, fontsettings s=Default, int rendermode=2, SDL_Color *bg=null) {
    //logln("Rendering ", text);
    /// Make sure no two routines change font settings at the same time
    synchronized(this) {
      with (s) TTF_SetFontStyle(font, (bold?1:0)+(italic?2:0)+(underline?4:0));
      /// Text mode: 0=Latin1, 1=UTF8, 2=Unicode
      switch(rendermode) {
        case 0: // Solid
          return TTF_RenderUTF8_Solid(font, toStringz(text), fg);
        case 1: // Shaded
          return TTF_RenderUTF8_Shaded(font, toStringz(text), fg, *bg);
        case 2: // Blended
          return TTF_RenderUTF8_Blended(font, toStringz(text), fg);
        default: assert(false);
      }
    }
    assert(false);
  }
  this(void[] file, int ptsize) {
    font=TTF_OpenFontRW(SDL_RWFromMem(file.ptr, file.length), 1, ptsize);
    if (!font) throw new Exception("TTF_FontClass.this: Couldn't open font: "~.toString(SDL_GetError));
  }
  ~this() { TTF_CloseFont(font); }
}

extern(C) {
  alias void TTF_Font; /// Opaque struct
  // General
    // Activation
    int TTF_Init();
    int TTF_WasInit();
    void TTF_Quit();
    // Errors
    /// Just use SDL_GetError.
  // Management
    // Loading
    TTF_Font *TTF_OpenFontRW(SDL_RWops *src, int freesrc, int ptsize);
    TTF_Font *TTF_OpenFontIndex(char *file, int ptsize, long index);
    // Freeing
    void TTF_CloseFont(TTF_Font *font);
  // Attributes
    // Global Attributes
    void TTF_ByteSwappedUNICODE(int swapped);
    // Font Style
    int TTF_GetFontStyle(TTF_Font *font);
    void TTF_SetFontStyle(TTF_Font *font, int style);
    // Font Metrics
    int TTF_FontHeight(TTF_Font *font);
    int TTF_FontAscent(TTF_Font *font);
    int TTF_FontDescent(TTF_Font *font);
    int TTF_FontLineSkip(TTF_Font *font); /// Recommended pixel height of a rendered line
    // Face Attributes
    long TTF_FontFaces(TTF_Font *font);
    int TTF_FontFaceIsFixedWidth(TTF_Font *font);
    char *TTF_FontFaceFamilyName(TTF_Font *font);
    char *TTF_FontFaceStyleName(TTF_Font *font);
    // Glyph Metrics
    int TTF_GlyphMetrics(TTF_Font *font, ushort unichar,
                         int *minx, int *maxx,
                         int *miny, int *maxy,
                         int *advance
                        );
    // Text Metrics
    int TTF_SizeText(TTF_Font *font, char *text, int *w, int *h);
    int TTF_SizeUTF8(TTF_Font *font, char *text, int *w, int *h);
    int TTF_SizeUNICODE(TTF_Font *font, wchar *text, int *w, int *h);
  // Render
    // Solid
    SDL_Surface *TTF_RenderText_Solid(TTF_Font *font, char *text, SDL_Color fg);
    SDL_Surface *TTF_RenderUTF8_Solid(TTF_Font *font, char *text, SDL_Color fg);
    SDL_Surface *TTF_RenderUNICODE_Solid(TTF_Font *font, wchar *text, SDL_Color fg);
    SDL_Surface *TTF_RenderGlyph_Solid(TTF_Font *font, ushort unichar, SDL_Color fg);
    // Shaded
    SDL_Surface *TTF_RenderText_Shaded(TTF_Font *font, char *text, SDL_Color fg, SDL_Color bg);
    SDL_Surface *TTF_RenderUTF8_Shaded(TTF_Font *font, char *text, SDL_Color fg, SDL_Color bg);
    SDL_Surface *TTF_RenderUNICODE_Shaded(TTF_Font *font, wchar *text, SDL_Color fg, SDL_Color bg);
    SDL_Surface *TTF_RenderGlyph_Shaded(TTF_Font *font, ushort unichar, SDL_Color fg, SDL_Color bg);
    // Blended
    SDL_Surface *TTF_RenderText_Blended(TTF_Font *font, char *text, SDL_Color fg);
    SDL_Surface *TTF_RenderUTF8_Blended(TTF_Font *font, char *text, SDL_Color fg);
    SDL_Surface *TTF_RenderUNICODE_Blended(TTF_Font *font, wchar *text, SDL_Color fg);
    SDL_Surface *TTF_RenderGlyph_Blended(TTF_Font *font, ushort unichar, SDL_Color fg);
}
