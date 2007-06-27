import computer, file, nls;
import std.stdio, std.file;
import SDL, gui, xml;

import png;
void main ()
{
  SDL_Surface *screen = SDL_SetVideoMode (640, 480, 32, SDL_SWSURFACE);

  writefln (nl("freelink"));
  writefln ("Switching to German");
  setLanguage ("German".dup);
  writefln (nl("freelink"));
  writefln ("Switching to default");
  setLanguage;
  File f = new File (1, "Test.txt".dup, 3, 0, false);
  Computer x = new Computer (0, "Localhost".dup);
  writefln (x.name);
  writefln (f.name);
  writefln ("Available space: ", x.space.available);

  Window testWindow = new Window ("Test".dup);
  auto fsrc=new FileSource(".."~sep~"gfx");
  auto stdframe=cast(xmlTag)parse(read(".."~sep~"gfx"~sep~"std-frame.xml")).children[0];
  auto frame=new Frame(fsrc, stdframe, new Frame(fsrc, stdframe, new Nothing));
  auto font=new Font(read("ariali.ttf"), 20);
  frame.below=new Stack(32, font.new TextLine("AVL FOOBAR whEEzle".dup), font.new TextLine("AVL FOOBAR whEEzle".dup, true));

  SDL_Event event;
  bool running = true;
  while (running) {
    while (SDL_PollEvent (&event)) {
      switch (event.type) {
        case SDL_EventType.SDL_KEYDOWN:
        case SDL_EventType.SDL_KEYUP:
          writefln ("which key? ", event.key.keysym.sym);
          if (event.key.keysym.sym == SDLKey.SDLK_q)
            running = false;
          break;
        case SDL_EventType.SDL_QUIT:
          running = false;
        default:
          break;
      }
    }
    SDL_FillRect(screen, null, 0);
    frame.draw(Area(screen));
    SDL_Flip(screen);
  }
}
