import file, hardware;

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
      kquad x;
      foreach (d; drives)
        x += d.space;
      return x;
    }
    kquad used () {
      return fs.used;
    }
    kquad available () {
      return max - used;
    }
  }
  Space space;

  this (IP ip, char[] name) {
    this.ip = ip;
    this.name = name;
    space=new Space;
    fs=new FileSystem;
  }
}
