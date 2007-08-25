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
    vars(this.tupleof) = mval(v);
  }
}

import tools.iter;
class FileSystem {
  File[] files;

  kquad used () {
    if (!files.length) return 0;
    return files ~ maps!("_.size") ~ reduces!("_ += __");
    //return fold (map (files, member!(File, "size")), sum!(kquad));
  }
  File[] binary () {
    //return filter!(File) (files, (File f) {
    //  return f.runnable && !f.encryptionLevel; });
    return files ~ filters!("_.runnable && !_.encryptionLevel") ~ toArray;
  }

  File[] data () {
    //return filter!(File) (files, (File f) {
    //  return !f.runnable; });
    return files ~ filters!("!_.runnable") ~ toArray;
  }
}
