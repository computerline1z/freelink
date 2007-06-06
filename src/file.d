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

  kquad used() {
    if (!files.length) return 0;
    return fold(map(files, &member!(File, "size")), &sum!(kquad));
  }
  File[] binary () {
    return filter!(File) (files, (File f) {
      return f.runnable && !f.encryptionLevel; });
  }

  File[] data () {
    return filter!(File) (files, (File f) {
      return !f.runnable; });
  }

  kquad used () {
    kquad x;
    foreach (f; files)
      x += f.size;
    return x;
  }
}
