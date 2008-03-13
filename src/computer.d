module computer;
import file, hardware, tools.functional;

class Computer
{
  IP ip;
  char[] name;

  CPU[] cpus;
  Storage[] drives;
  Motherboard motherBoard;

  FileSystem fs;

  final class Space {
    kquad max () { return drives /map/ expr!("$.space") /reduce(cast(kquad) 0)/ expr!("$+$2"); }
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
