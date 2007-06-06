import std.string, hardware, func;

class File {
  IP sourceIP;
  char[] name;
  kquad size;
  ubyte encryptionLevel;
  bool runnable;

  this (IP sourceIP, char[] name, kquad size,
        ubyte encryptionLevel, bool runnable) {
    this.sourceIP = sourceIP;
    this.name = name;
    this.size = size;
    this.encryptionLevel = encryptionLevel;
    this.runnable = runnable;
  }
}

class FileSystem {
  File[] files;

  File[] binary () {
    return files.filter ((File f) {
      return f.runnable && !f.encryptionLevel; });
  }

  File[] data () {
    return files.filter ((File f) {
      return !f.runnable; });
  }
}
