import computer, file, nls;
import std.stdio;
import SDL;

void main ()
{
  writefln(nl("freelink"));
  writefln("Switching to German");
  setLanguage("German");
  writefln(nl("freelink"));
  writefln("Switching to default");
  setLanguage;
  File f = new File (1, "Test.txt", 3, 0, false);
  Computer x = new Computer (0, "Localhost");
  writefln (x.name);
  writefln (f.name);
  writefln ("Available space: ", x.space.available);

  SDL_Init (SDL_INIT_VIDEO | SDL_INIT_AUDIO);
  scope (exit) SDL_Quit;

  SDL_Surface *screen = SDL_SetVideoMode (640, 480, 32, SDL_HWSURFACE);
  while (1) {
    
  }
}
