import computer, file, nls;
import std.stdio, std.file;
version(Windows) import std.c.windows.windows: Sleep;
import SDL, gui, xml;

import std.bind;
bool delegate(ref wchar[] target, ref bool newline) WriteGridLine(wchar[] text) {
  struct holder { wchar[] text;
    bool call(ref wchar[] target, ref bool newline) {
      assert(text.length<=target.length);
      target[0..text.length]=text;
      newline=true; return false;
    }
  }
  auto foo=new holder; foo.text=text; return &foo.call;
}

import std.date:getUTCtime;
bool delegate(ref wchar[] target, ref bool newline) Cursor(long ms=500) {
  struct holder { long ms;
    char[] input;
    bool call(ref wchar[] target, ref bool newline) {
      target[0..2]=cast(wchar[])"> ";
      wchar[] wch; foreach (ch; input) wch~=cast(wchar)ch;
      target[2..2+wch.length]=wch;
      if ((getUTCtime/ms)%2) target[2+input.length]='_';
      newline=true; return false;
    }
    void handle(SDL_keysym sym) {
      if (sym.sym<128) input~=sym.unicode;
    }
  }
  auto foo=new holder; foo.ms=ms;
  KeyHandler=&foo.handle;
  return &foo.call;
}

void delegate(SDL_keysym) KeyHandler=null;

import png;
void main ()
{
  SDL_EnableUNICODE=true;
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

  //Window testWindow = new Window ("Test".dup);
  auto fsrc=new FileSource(".."~sep~"gfx");
  auto stdframe=cast(xmlTag)parse(read(".."~sep~"gfx"~sep~"std-frame.xml")).children[0];
  auto frame=new Frame(fsrc, stdframe, null);
  auto font=new Font(read("cons.ttf"), 20);
  auto myGrid=font.new GridTextField(12, 20);
  myGrid.lines~=[WriteGridLine("Hello World"), WriteGridLine(" --Foobar-- "), Cursor];

  //frame.below=new Stack(32, true, font.new TextLine("AVL FOOBAR whEEzle".dup), font.new TextLine("AVL FOOBAR whEEzle".dup, true), myGrid);
  frame.below=myGrid;

  SDL_Event event;
  bool running = true;
  size_t count=0;
  auto start=getUTCtime()/1000;
  auto current=start;
  bool[SDLKey] handled;
  SDL_FillRect(screen, null, 0);
  frame.setRegion(Area(screen));
  while (running) {
    while (SDL_PollEvent (&event)) {
      switch (event.type) {
        case SDL_EventType.SDL_KEYDOWN:
          auto key=event.key.keysym;
          if ((!(key.sym in handled))&&KeyHandler) { KeyHandler(key); handled[key.sym]=true; }
          break;
        case SDL_EventType.SDL_KEYUP:
          auto key=event.key.keysym.sym;
          handled.remove(key);
          writefln ("which key? ", key);
          /*if (event.key.keysym.sym == SDLKey.SDLK_q)
            running = false;*/
          break;
        case SDL_EventType.SDL_QUIT:
          running = false;
        default:
          break;
      }
    }
    //frame.draw(Area(screen));
    frame.update;
    SDL_Flip(screen);
    Sleep(10);
    ++count;
    if (current!=(getUTCtime/1000)) {
      current=getUTCtime/1000;
      writefln("FPS: ", (cast(float)count)/(cast(float)(current-start)));
    }
  }
}
