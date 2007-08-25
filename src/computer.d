module computer;
import file, hardware, tools.iter;

class Computer
{
  IP ip;
  char[] name;

  CPU[] cpus;
  Storage[] drives;
  Motherboard motherBoard;

  FileSystem fs;

  final class Space {
    kquad max () {
      return drives ~ maps!("_.space") ~ reduces!("_ += __"); }
    /*kquad x; foreach (d; drives) x += d.space; return x;
    }*/
    kquad used () { return fs.used; }
    kquad available () { return max - used; }
  }
  Space space;

  this (IP ip, char[] name) {
    space = new Space;
    this.ip = ip;
    this.name = name;
    space=new Space;
    fs=new FileSystem;
  }
}
