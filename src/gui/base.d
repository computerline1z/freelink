module gui.base;
import std.stdio, SDL, std.file, std.string, std.path: sep;
public import gui.area;

class FileSource {
  string basepath;
  this(string path=".") { basepath=path; }
  static FileSource opCall(string path=".") { return new FileSource(path); }
  void[] getFile(char[] name) {
    return read(basepath~sep~name);
  }
}

class Widget {
  bool tainted=false; void taint() { tainted=true; }
  //final void taintcheck(void delegate() dg) { if (tainted) { dg(); tainted=false; } }
  abstract void draw ();
  /// check if redraws are necessary
  abstract void update ();
  /// Where we live.
  protected Area area=null;
  /// force setRegion to treat area as pristine
  void fullRedraw() { assert(area !is null, "Can't fullRedraw while area not set"); auto backup=area; area=null; setRegion(backup); }
  /// used to position/move the drawing region. Might trigger a re-draw.
  void setRegion(Area region) {
    assert(region.mine);
    if (area&&region.sameSurf(area)&&region.sameSize(area)) {
      if (!region.sameRect(area)) {
        if (!region.overlaps(area)) {
          region.blit(area);
          area=region;
        } else { area=region; draw; }
      }
    } else { area=region; draw; }
  }
}

class ContainerWidget : Widget {
  abstract void setRegion(Area region);
}

class FrameWidget : ContainerWidget {
  private Widget _below;
  void below (Widget w) { _below=w; }
  Widget below () { return _below; }
  void update() { below.update; }
}

interface Generator { SDL_Surface *opCall(size_t xs, size_t ys); }

alias bool delegate(ref wchar[], bool reset) TextGenerator;

class Nothing : Widget { void draw (Area target) { } }

int eatoi(char[] nr, int max) {
  assert(nr.length);
  if (nr[$-1]=='%') return cast(int)(max*atoi(nr[0..$-1]))/100;
  return cast(int)atoi(nr);
}

template DefaultConstructor() { this(typeof(this.tupleof) t) { foreach (id, bogus; this.tupleof) this.tupleof[id]=cast(typeof(bogus))t[id]; } }
