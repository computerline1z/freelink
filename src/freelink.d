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
  SDL_Init (SDL_INIT_VIDEO);
}
