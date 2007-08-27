module file;
import std.string, hardware;
import tools.base, tools.mrv;

class File {
  IP sourceIP;
  char[] name;
  kquad size;
  ubyte encryptionLevel;
  bool runnable;
  this (Tuple!(IP, char[], kquad, ubyte, bool) v) {
    vars(this.tupleof) = list(v);
  }
}

import tools.iter;
class FileSystem {
  File[] files;

  kquad used () {
    if (!files.length) return 0;
    return files ~ maps!("_.size") ~ reduces!("_ += __");
  }
  File[] binary () {
    return files ~ filters!("_.runnable && !_.encryptionLevel") ~ toArray;
  }
  File[] data () {
    return files ~ filters!("!_.runnable") ~ toArray;
  }
}
