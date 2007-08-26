module freelink;
import computer, file, nls;
import std.stdio, std.file;
version(Windows) import std.c.windows.windows: Sleep;
import std.thread: Thread;
import contrib.SDL, gui.base, gui.frame, gui.text, xml;

import tools.iter;
bool writeOn(ref wchar[] target, ref size_t offset, wchar[][] text...) {
  if (offset==size_t.max) {
    offset=0;
    return false; /// Ensure the final newline
  }
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

TextGenerator WriteGrid(wchar[] text) {
  struct holder {
    wchar[] text;
    size_t offset=0;
    bool call(ref wchar[] target, bool reset) { return writeOn(target, offset, text); }
  }
  auto foo=new holder; foo.text=text; return &foo.call;
}

bool between(T)(T v, T lower, T upper) { return (v>=lower)&&(v<upper); }

import std.date:getUTCtime;
class Prompt {
  long ms;
  wchar[] inbuffer; wchar[] line; size_t offset; void delegate(wchar[]) lineCB;
  bool show=false;
  /// Process the input buffer
  void push() {
    // only clear the buffer if show is set
    if(show) {
      while (inbuffer.length) {
        switch (inbuffer[0]) {
          case 8: if (line.length) line=line[0..$-1]; break; /// backspace
          case 13: lineCB(line); line=""; break; /// CR
          default: line~=inbuffer[0];
        }
        inbuffer=inbuffer[1..$];
        if (!show) break;
      }
    }
  }
  bool generate(ref wchar[] target, bool reset) {
    assert(target.length>2, "Text field width too small to be usable any more; must be >2");
    bool blink=((getUTCtime/ms)%2)?true:false;
    if (reset) offset=0;
    if (show) return writeOn(target, offset, "> "w, line, blink?"_"w:" "w);
    else return writeOn(target, offset, blink?"_"w:" "w);
  }
  TextGenerator toStatic() { return WriteGrid("> "~line); }
  void handle(SDL_keysym sym) {
    if (between(cast(int)sym.sym, 32, 128)) {
      inbuffer~=sym.unicode;
      writefln("Added character ", cast(ubyte[])[sym.unicode], " == ", sym.unicode);
    } else switch (cast(int)sym.sym) {
      case 8, 13: inbuffer~=cast(char)sym.sym;
      default: writefln("Strange sym: ", sym.sym, " which is '", sym.unicode, "'");
    }
  }
  this(void delegate(wchar[]) lineCB, long ms=500) {
    this.ms=ms; this.lineCB=lineCB;
    KeyHandler=&handle;
  }
}

void delegate(SDL_keysym) KeyHandler=null;

import tools.threads, tools.ext, std.utf, std.string, std.stdio: format;
class TTY {
  Prompt p;
  Font.GridTextField field;
  DifferentThreadsBlock!(2) dtb;
  MessageChannel!(wchar[]) InputText;
  this(Font.GridTextField f) {
    field=f;
    New(p, &GotLine);
    New(dtb, "TTY DTB");
    New(InputText);
    f.gens~=&p.generate;
  }
  const int MainThread=0; const int OSThread=1;
  private void GotLine(wchar[] what) {
    dtb in MainThread; /// called from main thread
    if (!p.show) throw new AxiomaticException("Received input line but not in input mode");
    p.show=false;
    InputText.put(what);
  }
  wchar[] readln() {
    scope(failure) writefln("!readln");
    dtb in OSThread;
    if (p.show) throw new AxiomaticException("Tried to read line while already reading line; confused now.");
    p.show=true;
    auto res=InputText.get;
    with (field) {
      gens ~= gens[$-1];
      gens[$-2] = p.toStatic;
    }
    return res;
    
  }
  void write(wchar[] t) {
    scope(failure) writefln("!write");
    dtb in OSThread;
    if (p.show) throw new Exception("Trying to print to console while waiting for input: your threads are messed up");
    with (field) {
      gens ~= gens[$-1];
      gens[$-2] = WriteGrid(t);
    }
  }
  void writefln(T...)(T t) { write(format("", replace(t, "%", "%%")).toUTF16()); }
  void push() { p.push; }
}

import png;
import std.c.time: sleep;
import tools.threadpool, tools.ext;
import std.process;
static import std.stream;
void main ()
{
  auto pool=new ThreadPool(1);
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
  auto t=new TTY(myGrid);
  pool.addTask({
    while (true) {
      auto inp=t.readln;
      system((inp~" 2>>tmp >> tmp").toUTF8()); // "
      foreach (result; (cast(char[])read("tmp")).split("\n")) t.writefln(result);
      system("rm tmp"); 
    }
  });
  
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
    t.push;
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
