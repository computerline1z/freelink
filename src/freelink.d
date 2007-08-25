module freelink;
import computer, file, nls;
import std.stdio, std.file;
version(Windows) import std.c.windows.windows: Sleep;
import std.thread: Thread;
import contrib.SDL, gui.base, gui.frame, gui.text, xml;

import std.bind;
TextGenerator WriteGridLine(wchar[] text) {
  struct holder { wchar[] text;
    bool call(ref wchar[] target, bool reset) {
      assert(text.length<=target.length);
      if (!reset) return false; /// One line should be enough for anybody!
      target[0..text.length]=text;
      return true; /// Re-call for newline
    }
  }
  auto foo=new holder; foo.text=text; return &foo.call;
}

import tools.iter;
bool writeOn(ref wchar[] target, ref size_t offset, wchar[][] text...) {
  if (offset==size_t.max) return false; /// Ensure the final newline
  wchar[] str=(iterate(text)~reduces!("_~=__"))[offset..$];
  if (str.length>target.length) {
    target[0..$]=str[0..target.length];
    offset+=target.length;
    return true;
  } else {
    target[0..str.length]=str;
    offset=size_t.max; /// last newline
    return true;
  }
}

bool between(T)(T v, T lower, T upper) { return (v>=lower)&&(v<upper); }

import std.date:getUTCtime;
class Cursor {
  long ms;
  wchar[] input; size_t offset; void delegate(wchar[]) lineCB;
  bool show=true;
  bool generate(ref wchar[] target, bool reset) {
    assert(target.length>2, "Text field width too small to be usable any more; must be >2");
    bool blink=((getUTCtime/ms)%2)?true:false;
    if (reset) offset=0;
    if (show) return writeOn(target, offset, "> "w, input, blink?"_"w:" "w);
    else return writeOn(target, offset, blink?"_"w:" "w);
  }
  void handle(SDL_keysym sym) {
    if (between(cast(int)sym.sym, 32, 128)) {
      input~=sym.unicode;
      writefln("Added character ", cast(ubyte[])[sym.unicode], " == ", sym.unicode);
    } else switch (cast(int)sym.sym) {
      case 8: if (input.length) input=input[0..$-1]; break; /// backspace
      case 13: lineCB(input); input=""; break; /// CR
      default: writefln("Strange sym: ", sym.sym, " which is '", sym.unicode, "'");
    }
  }
  this(void delegate(wchar[]) lineCB, long ms=500) {
    this.ms=ms; this.lineCB=lineCB;
    KeyHandler=&handle;
  }
}

void delegate(SDL_keysym) KeyHandler=null;

import png;
import std.c.time: sleep;
import tools.threadpool;

struct _fix(T) {
  T what;
  R delegate(P) opCat_r(R, P...)(R delegate(T, P) dg) {
    struct holder {
      T what; R delegate(T, P) dg;
      R call(P p) { return dg(what, p); }
    }
    auto h=new holder; h.what=what; h.dg=dg;
    return &h.call;
  }
}
_fix!(T) fix(T)(T v) { return _fix!(T)(v); }

void main ()
{
  auto p=new ThreadPool(1);
  SDL_EnableUNICODE=true;
  SDL_Surface *screen = SDL_SetVideoMode (640, 480, 32,
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
  Cursor cursor=void;
  void GotLine(wchar[] text) {
    with (myGrid) {
      gens ~= gens[$-1]; // dup cursor on end
      gens[$-2] = WriteGridLine("> " ~ text); // and freeze previous pos
    }
    cursor.show=false;
    // actual callback goes here
    // placeholder that just waits 2s
    p.addTask((Cursor cursor) {
      auto start=getUTCtime();
      while (getUTCtime()-start<2000) { }
      cursor.show=true;
    }~fix(cursor));
  }
  cursor=new Cursor(&GotLine);
  myGrid.gens ~= [WriteGridLine("Hello World"),
                  WriteGridLine(" --Foobar-- "), &cursor.generate];

  //frame.below = new Stack(32, true,
  //                        font.new TextLine("AVL FOOBAR whEEzle".dup),
  //                        font.new TextLine("AVL FOOBAR whEEzle".dup, true),
  //                        myGrid);
  frame.below = myGrid;

  SDL_Event event;
  bool running = true;
  size_t count = 0;
  auto start = getUTCtime() / 1000;
  auto current = start;
  bool[SDLKey] handled;
  SDL_FillRect(screen, null, 0);
  frame.setRegion(Area(screen));
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
    //frame.draw(Area(screen));
    frame.update;
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
