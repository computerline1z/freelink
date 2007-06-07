import computer, file, nls;
import std.stdio, std.file;
import SDL, gui, xml;

void main ()
{
  writefln (nl("freelink"));
  writefln ("Switching to German");
  setLanguage ("German");
  writefln (nl("freelink"));
  writefln ("Switching to default");
  setLanguage;
  File f = new File (1, "Test.txt", 3, 0, false);
  Computer x = new Computer (0, "Localhost");
  writefln (x.name);
  writefln (f.name);
  writefln ("Available space: ", x.space.available);

  Window testWindow = new Window ("Test");
  auto frame=new Frame(FileSource(".."~sep~"gfx"), cast(xmlTag)parse(read(".."~sep~"gfx"~sep~"std-frame.xml")).children[0]);

  SDL_Surface *screen = SDL_SetVideoMode (640, 480, 32, SDL_SWSURFACE);
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
    frame.draw(Area(screen));
    //testWindow.draw(Area(screen));
    SDL_Flip(screen);
  }
}
