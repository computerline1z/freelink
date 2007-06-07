module gui;
import SDL, png, std.stdio, std.file;;
 
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
