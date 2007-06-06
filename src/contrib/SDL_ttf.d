module SDL_ttf;
import SDL;

struct fontsettings {
  bool bold=false;
  bool italic=false;
  bool underline=false;
}

import std.md5: sum;

struct tcsrtb {
  char[] text;
  SDL_Color col;
  fontsettings settings;
  SDL_Color *bg;
  static int cmp(int a, int b) { if (a<b) return -1; if (a>b) return 1; return 0; }
  int opCmp(tcsrtb s) {
    int myCol=col.r*65536+col.g*256+col.b;
    int otherCol=s.col.r*65536+s.col.g*256+s.col.b;
    int c=cmp(myCol, otherCol); if (c!=0) return c;
    int f1; with (settings) f1=bold?4:0+italic?2:0+underline?1:0;
    int f2; with (s.settings) f2=bold?4:0+italic?2:0+underline?1:0;
    c=cmp(f1, f2); if (c!=0) return c;
    return  std.string.cmp(this.text, s.text);
  }
  uint toHash() {
    uint e; foreach (ubyte b; (cast(ubyte*)this)[col.offsetof..(*this).sizeof]) e^=b;
    foreach (ubyte b; cast(ubyte[])text) e^=b;
    return e;
  }
}

class TTF_FontClass {
  static this() { if (!TTF_WasInit) TTF_Init; }
  static ~this() { if (TTF_WasInit) TTF_Quit; }
  private TTF_Font *font;
  int height() { return TTF_FontHeight(font); }
  int ascent() { return TTF_FontAscent(font); }
  int descent() { return TTF_FontDescent(font); }
  int lineskip() { return TTF_FontLineSkip(font); }
  static fontsettings Default;

  buffer!(SDL_Surface*, tcsrtb) surf_buffer=null;
  private SDL_Surface *dgRender(tcsrtb param) { with (param) return _render(text, col, settings, 2, bg); }
  this() {
    surf_buffer=new typeof(surf_buffer)(&dgRender, delegate uint(SDL_Surface *surf) {
      if (!surf) return 0;
      return surf.w*surf.h;
    }, 512*KB, (tcsrtb k, SDL_Surface *s) {
      SDL_FreeSurface(s);
    });
    //sameStrings=new typeof(sameStrings)((char[] c) { return c; }, (char[] c) { return c.length; }, 16*KB);
  }
  SDL_Surface *render(char[] text, SDL_Color fg, fontsettings s=Default, SDL_Color *bg=null) {
    tcsrtb p; p.text=/*sameStrings.get(*/text/*)*/; p.col=fg; p.settings=s; p.bg=bg;
    return surf_buffer.get(p);
  }
  SDL_Surface *_render(char[] text, SDL_Color fg, fontsettings s=Default, int rendermode=2, SDL_Color *bg=null) {
    //logln("Rendering ", text);
    /// Make sure no two routines change font settings at the same time
    /*synchronized(this)*/ {
      with (s) TTF_SetFontStyle(font, (bold?1:0)+(italic?2:0)+(underline?4:0));
      /// Text mode: 0=Latin1, 1=UTF8, 2=Unicode
      switch(rendermode) {
        case 0: // Solid
          /*switch (textmode) {
            case 0: */return TTF_RenderText_Solid(font, cast(char*)toPointer(text), fg);
            /*case 1: return TTF_RenderUTF8_Solid(font, cast(char*)toPointer(text), fg);
            case 2: return TTF_RenderUNICODE_Solid(font, cast(wchar*)toPointer(text), fg);
            default: assert(false);
          }*/
        case 1: // Shaded
          /*switch (textmode) {
            case 0: */return TTF_RenderText_Shaded(font, cast(char*)toPointer(text), fg, *bg);
            /*case 1: return TTF_RenderUTF8_Shaded(font, cast(char*)toPointer(text), fg, *bg);
            case 2: return TTF_RenderUNICODE_Shaded(font, cast(wchar*)toPointer(text), fg, *bg);
            default: assert(false);
          }*/
        case 2: // Blended
          /*switch (textmode) {
            case 0: */return TTF_RenderText_Blended(font, cast(char*)toPointer(text), fg);
            /*case 1: return TTF_RenderUTF8_Blended(font, cast(char*)toPointer(text), fg);
            case 2: return TTF_RenderUNICODE_Blended(font, cast(wchar*)toPointer(text), fg);
            default: assert(false);
          }*/
        default: assert(false);
      }
    }
    assert(false);
  }
  this(char[] filename, int ptsize) {
    font=TTF_OpenFont(toPointer(filename), ptsize);
    if (!font) throw new Exception("TTF_FontClass.this: Couldn't open font: "~toArray(SDL_GetError));
    this();
  }
  ~this() { TTF_CloseFont(font); if (surf_buffer) delete surf_buffer; }
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
    TTF_Font *TTF_OpenFont(char *file, int ptsize);
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
