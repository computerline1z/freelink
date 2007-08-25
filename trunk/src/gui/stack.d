module gui.stack;
import gui.base;

class Stack : ContainerWidget {
  Widget[] widgets; int height; bool fillRest;
  this(int height, bool fillRest, Widget[] widgets...) { this.height=height; this.widgets=widgets; this.fillRest=fillRest; }
  void update() { foreach (w; widgets) w.update; }
  void setRegion(Area target) {
    assert(widgets.length*height<target.h);
    if (fillRest) {
      foreach (i, w; widgets[0..$-1]) w.setRegion(target.select(0, height*i, target.w, height));
      widgets[$-1].setRegion(target.select(0, (widgets.length-1)*height));
    } else foreach (i, w; widgets) w.setRegion(target.select(0, height*i, target.w, height));
  }
  void draw () { foreach (w; widgets) w.draw; }
}
