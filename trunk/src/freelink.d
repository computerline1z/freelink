module freelink;
import std.stdio, std.thread, std.file, std.process, std.utf;
import std.date: getUTCtime;
static import std.date, std.stream;
import tools.threadpool;
import contrib.SDL, gui.all, xml, nls, mystring;
import guest.all, file, computer;

void main ()
{
  auto pool=new Threadpool(1);
  SDL_EnableUNICODE=true;
  SDL_Surface *screen = SDL_SetVideoMode (800, 600, 32,
                                          SDL_HWSURFACE | SDL_ANYFORMAT);

  writefln(nl("freelink"));
  writefln("Switching to German");
  setLanguage("German".dup);
  writefln(nl("freelink"));
  writefln("Switching to default");
  setLanguage;
  File f = new File(1, "Test.txt".dup, 3, 0, false);
  Computer x = new Computer(0, "Localhost".dup);
  writefln(x.name);
  writefln(f.name);
  writefln("Available space: ", x.space.available);

  //Window testWindow = new Window("Test".dup);
  auto fsrc = new FileSource(".." ~ sep ~ "gfx");
  auto stdframe = cast(xmlTag)parse(read(".." ~ sep ~ "gfx"
                                       ~ sep ~ "std-frame.xml")).children[0];
  auto frame = new Frame(fsrc, stdframe, null);
  auto font = new Font(read("cour.ttf"), 20);
  auto myGrid = font.new GridTextField(12, 24);
  auto tty=new TTY(myGrid);
  frame.below = myGrid;
  frame.setRegion(Area(screen));
  pool.addTask("Input Loop", delegate void(){
    while (true) {
      auto inp=tty.readln;
      if (inp=="cycle"w) {
        foreach (x; Range[0..10]) {
          tty.writef(".");
          system("sleep 1");
        }
        tty.writefln();
        continue;
      }
      if (inp=="date"w) {
        //commands["date"](["date"[]])(null, ui);
        continue;
      }
      system("rm tmp");
      system((inp~" 2>>tmp >> tmp").toUTF8());
      foreach (result; (cast(char[])read("tmp")).split("\n")) tty.writefln(result);
      system("rm tmp"); 
    }
  });
  
  SDL_Event event;
  bool running = true;
  size_t count = 0;
  auto start = getUTCtime() / 1000;
  auto current = start;
  bool[SDLKey] handled;
  SDL_FillRect(screen, null, 0);
  while (running) {
    while (SDL_PollEvent (&event)) {
      switch (event.type) {
        case SDL_EventType.SDL_KEYDOWN:
          auto key = event.key.keysym;
          if ((!(key.sym in handled)) && KeyHandler) {
            KeyHandler(key);
            handled[key.sym] = true;
          }
          break;
        case SDL_EventType.SDL_KEYUP:
          auto key=event.key.keysym.sym;
          handled.remove(key);
          writefln ("which key? ", key);
          //if (event.key.keysym.sym == SDLKey.SDLK_q)
          //  running = false;
          break;
        case SDL_EventType.SDL_QUIT:
          running = false;
        default:
          break;
      }
    }
    with (frame) { draw; update; }
    SDL_Flip(screen);
    //Sleep(10);
    Thread.yield;
    ++count;
    if (current != (getUTCtime / 1000)) {
      current = getUTCtime / 1000;
      writefln("FPS: ", (cast(float)count) / (cast(float)(current - start)));
    }
  }
}
