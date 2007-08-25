module gui.area;
import SDL, tools.base, std.stdio: format;

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
