module gui;
import SDL, png;

class Widget {
  SDL_Rect r;
  void draw (SDL_Surface *) {
  }
}
import std.file;
class Window : Widget {
  char[] title;
  SDL_Surface *titleBar;
  bool dragging;

  this (char[] title, short x, short y, ushort width, ushort height) {
    this.title = title;
    this.r.x = x;
    this.r.y = y;
    this.r.w = width;
    this.r.h = height;
    this.titleBar = decode (cast(ubyte[])read("titlebar.png"));
  }

  void startDrag () {
    dragging = true;
  }
  void stopDrag (short x, short y) {
    dragging = false;
    this.r.x = x;
    this.r.y = y;
  }
  void draw (SDL_Surface *surf) {
    if (dragging) {
    } else {
      SDL_BlitSurface (titleBar, &r, surf, &r);
      putpixel (surf, r.x, r.y, [255, 255, 255]);
      putpixel (surf, r.x+r.w, r.y, [255, 255, 255]);
      putpixel (surf, r.x+r.w, r.y+r.h, [255, 255, 255]);
      putpixel (surf, r.x, r.y+r.h, [255, 255, 255]);
    }
  }
}

class Button : Widget {
  char[] caption;
  void draw (SDL_Surface *surf) {
  }
}
