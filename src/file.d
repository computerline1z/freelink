module file;
import std.string, hardware;
import tools.functional;

class File {
  IP sourceIP;
  char[] name;
  kquad size;
  ubyte encryptionLevel;
  bool runnable;
  mixin This!("sourceIP, name, size, encryptionLevel, runnable");
}

class FileSystem {
  File[] files;

  kquad used () {
    if (!files.length) return 0;
    return files /map/ expr!("$.size") /reduce(cast(kquad) 0)/ expr!("$+$2");
  }
  File[] binary () {
    return files /select/ expr!("$.runnable && !$.encryptionLevel");
  }
  File[] data () {
    return files /select/ expr!("!$.runnable");
  }
}
