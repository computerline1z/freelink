module freelink;
import std.file, std.stdio, std.thread, std.c.time: sleep;
import SDL, gui.all, nls, file, computer, xml;

bool writeOn(wchar[] target, ref size_t offset, wchar[][] text...) {
  if (offset==size_t.max) {
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
    size_t offset;
    bool call(wchar[] target, bool reset) { if (reset) offset=0; return writeOn(target, offset, text); }
  }
  auto foo=new holder; foo.text=text; return &foo.call;
}

bool between(T)(T v, T lower, T upper) { return (v>=lower)&&(v<upper); }

import std.date:getUTCtime;
class Prompt {
  long ms;
  wchar[] inbuffer; /// typing buffer
  wchar[] line; /// current line
  size_t line_offset;
  size_t curpos; /// cursor position
  void delegate(wchar[]) lineCB;
  bool show=false;
  /// Process the input buffer
  void push() {
    // only clear the buffer if show is set
    if(show) {
      while (inbuffer.length) {
        switch (inbuffer[0]) {
          case 8: if (line.length) line=(curpos?line[0..curpos-1]:"")~line[curpos..$]; if (curpos) --curpos; break; /// backspace
          case 13: lineCB(line); line=""; curpos=0; break; /// CR
          case 275: if (curpos<line.length) ++curpos; break; /// arrow right
          case 276: if (curpos) --curpos; break; /// arrow left
          default: line=line[0..curpos]~inbuffer[0]~line[curpos..$]; ++curpos; break;
        }
        inbuffer=inbuffer[1..$];
        if (!show) break;
      }
    }
  }
  bool generate(wchar[] target, bool reset) {
    assert(target.length>2, "Text field width too small to be usable any more; must be >2");
    bool blink=((getUTCtime/ms)%2)?true:false;
    if (reset) line_offset=0;
    auto line2=line.dup~" "w;
    if (blink) line2[curpos]='_';
    if (show) return writeOn(target, line_offset, "> "w, line2);
    else return writeOn(target, line_offset, line2);
  }
  TextGenerator toStatic() { return WriteGrid("> "~line); }
  void handle(SDL_keysym sym) {
    if (between(cast(int)sym.sym, 32, 128)) {
      inbuffer~=sym.unicode;
      writefln("Added character ", cast(ubyte[])[sym.unicode], " == ", sym.unicode);
    } else switch (cast(int)sym.sym) {
      case 8, 13, 275, 276: inbuffer~=cast(wchar)sym.sym; break;
      default: writefln("Strange sym: ", sym.sym, " which is '", sym.unicode, "'");
    }
  }
  this(void delegate(wchar[]) lineCB, long ms=500) {
    this.ms=ms; this.lineCB=lineCB;
    KeyHandler=&handle;
  }
}

void delegate(SDL_keysym) KeyHandler=null;

import std.utf, std.traits: isStaticArray;
wchar[] mysformat(T)(T t) {
  static if(is(T: wchar[])) return t; else
  static if(isStaticArray!(T)) return mysformat(t[]); else
  static if(is(T: char[])) return t.toUTF16(); else
  static assert(false, T.stringof~" not supported (yet)!");
}

wchar[] myformat(T...)(T t) {
  wchar[] res;
  foreach (v; t) res~=mysformat(v);
  return res;
}

import tools.threads, tools.ext, std.string, std.stdio: format;
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
    p.line="";
    return res;
  }
  void writef(wchar[] t) {
    scope(failure) writefln("!write");
    dtb in OSThread;
    p.line~=t;
  }
  void writegen(TextGenerator tg) {
    dtb in OSThread;
    if (p.line.length) throw new Exception("Trying to write generator on used line ("~p.line.toUTF8()~") - text would be overwritten!");
    with (field) {
      gens ~= gens[$-1];
      gens[$-2] = tg;
    }
    p.line="";
  }
  void newline() {
    dtb in OSThread;
    with (field) {
      gens ~= gens[$-1];
      gens[$-2] = WriteGrid(p.line);
    }
    p.line="";
  }
  void writefln(T...)(T t) { writef(myformat(t).toUTF16()); newline; }
  void push() { p.push; }
}

import tools.threadpool, tools.ext;
import std.process;
static import std.date, std.stream;
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
      if (inp=="cycle") {
        foreach (x; Integers[0..10]) {
          t.writef(".");
          system("sleep 1");
        }
        t.writefln();
        continue;
      }
      if (inp=="date") {
        t.writegen((wchar[] target, bool reset, ref size_t offset, ref wchar[] datestr) {
          if (reset) { offset=0; datestr=std.date.toString(std.date.getUTCtime()).toUTF16(); }
          return writeOn(target, offset, datestr);
        } ~ rfix(0, ""w));
        continue;
      }
      system((inp~" 2>>tmp >> tmp").toUTF8());
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
