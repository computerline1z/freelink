import file, hardware;

enum ServerType { web, government, university, smallbusiness, corporation };

class Computer
{
  IP ip;
  ServerType type;
  char[] name;

  CPU[] cpus;
  Storage[] drives;
  Motherboard motherBoard;

  FileSystem fs;

  final class Space () {
    kquad max () {
      kquad x;
      foreach (d; drives)
        x += d.maxSpace;
      return x;
    }
    kquad used () {
      return FS.used;
    }
    kquad available () {
      return max-used;
    }
  }
  Space space; /// \todo: init in constructor

  this (IP ip, char[] name) {
    this.ip = ip;
    this.name = name;
  }

  this (IP ip, char[] name, ServerType type) {
    this (ip, name);
    this.type = type;
  }
}
