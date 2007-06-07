import computer, file, nls;
import std.stdio;
import SDL, gui;

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

  SDL_Init (SDL_INIT_VIDEO | SDL_INIT_AUDIO);
  scope (exit) SDL_Quit;

  Window testWindow = new Window ("Test", 10, 10, 10, 20);

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
    testWindow.draw (screen);
    SDL_UpdateRect (screen, 0, 0, 0, 0);
  }
}
