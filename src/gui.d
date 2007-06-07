module gui;
import contrib.SDL, png, std.stdio, std.file;;

class Area {
  SDL_Rect me; SDL_Surface *mine;
  this(SDL_Rect  r, SDL_Surface *s) { me=r; mine=s; }
  static Area opCall(SDL_Rect r, SDL_Surface *s) { return new Area(r, s); }
  //int blit(
}

class Widget {
  abstract void draw (Area);
}

class Window : Widget {
  char[] title;
  SDL_Surface *titleBar;
  bool dragging;

  this (char[] title) {
    this.title = title;
    titleBar = decode (read("../gfx/titlebar.png"));
  }

  void draw (Area target) {
    if (dragging) {
    } else {
      /*SDL_Rect src;
      with (src) { x=0; y=0; w=cast(ushort)(titleBar.w); h=cast(ushort)(titleBar.h); }
      SDL_Rect dest=r;
      SDL_Surface *temp=SDL_ConvertSurface(titleBar, surf.format, SDL_SWSURFACE);
      SDL_BlitSurface (temp, &src, surf, &dest);
      SDL_FreeSurface(temp);
      putpixel (surf, r.x, r.y, [255, 255, 255]);
      putpixel (surf, r.x+r.w, r.y, [255, 255, 255]);
      putpixel (surf, r.x+r.w, r.y+r.h, [255, 255, 255]);
      putpixel (surf, r.x, r.y+r.h, [255, 255, 255]);*/
    }
  }
}

class Button : Widget {
  char[] caption;
  void draw (SDL_Surface *surf) {
  }
}
