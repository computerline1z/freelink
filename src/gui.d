module gui;
import contrib.SDL, png, std.stdio, std.file;;

class Widget {
  SDL_Rect r;
  this (short x, short y, ushort w, ushort h) {
    r.x = x;
    r.y = y;
    r.w = w;
    r.h = h;
  }
  void draw (SDL_Surface *) {
  }
}

class Window : Widget {
  char[] title;
  SDL_Surface *titleBar;
  bool dragging;

  this (char[] title, short x, short y, ushort width, ushort height) {
    this.title = title;
    super (x, y, width, height);
    titleBar = decode (cast(ubyte[])read("../gfx/titlebar.png"));
  }

  void draw (SDL_Surface *surf) {
    if (dragging) {
    } else {
      SDL_Rect src;
      with (src) { x=0; y=0; w=cast(ushort)(titleBar.w); h=cast(ushort)(titleBar.h); }
      SDL_Rect dest=r;
      SDL_Surface *temp=SDL_ConvertSurface(titleBar, surf.format, SDL_SWSURFACE);
      SDL_BlitSurface (temp, &src, surf, &dest);
      SDL_FreeSurface(temp);
      putpixel (surf, r.x, r.y, [255, 255, 255]);
      putpixel (surf, r.x+r.w, r.y, [255, 255, 255]);
      putpixel (surf, r.x+r.w, r.y+r.h, [255, 255, 255]);
      putpixel (surf, r.x, r.y+r.h, [255, 255, 255]);
    }
  }
}

class Button : Widget {
  char[] caption;
  this () {
    super (0, 0, 10, 10);
  }
  void draw (SDL_Surface *surf) {
  }
}
