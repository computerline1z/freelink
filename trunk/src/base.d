module base;
import func;

typedef uint kquad; // kiloquad. Originally star-trek unit, also used in Uplink.
typedef uint gflops; // gigaflops. Deliciously ambiguous.
typedef uint ip; // internet address.

struct text {
  // This will later be changed to loading at run-time, for NLS stuff
  // what's the validate(data) do? (UTF-8 validation from std.utf -downs)
  char[] data;
  invariant { validate(data); }
}

enum relation : ubyte { offensive, wary, neutral, friendly, trusted }
interface networked { relation getRelation(networked peer); }

class Computer {
  Motherboard board;
  CPU[] cpus;
  Storage[] drives;
  Connection conn;
  
  ip IP;
  
  fileSystem FS;
  final class Space() {
    kquad max() { kquad x; foreach (d; drives) x+=d.maxSpace; return x; }
    kquad used() { return FS.used; }
    kquad available() { return max-used; }
  }
  Space space; /// \todo: init in constructor
}

class Hardware {
  text name;
  ubyte level;
}

class CPU : Hardware {
  gflops speed;
  bool quant; /// quantum enhanced cpu. Might suck at everyday tasks, but excel at decoding encryption.
}

class Storage : Hardware {
  kquad space;
}

class Connection {
  text name;
  float speed; // seconds/kquad
  /// how many percent of route length are still available? 1f means r length is 0, <0f means you can't add anything to the route. We should provide a default implementation of this, based on distance.
  // ubyte quality; // Wait... do we need this? I can't remember :S
  // probably not, already covered under freeResources
  float freeResources(route r) {
    return float.nan; // ahem.
  }
}

class Motherboard : Hardware {
  ubyte maxCores; // Max. number of CPUs
  ubyte maxDrives;
}

class File {
  ip source;
  text name;
  kquad size;
  ubyte encryptionLevel;
  bool runnable;
}

class FileSystem {
  File[] files;
  File[] binary () {
    return files.filter((File f) { return f.runnable&&!f.encryptionLevel; });
  }
  File[] data () {
    return files.filter((File f) { return !f.runnable; });
  }
}

class route {
  computer[] components;
  invariant {
    assert(components.length>2);
  }
}

class session {
  route r;
  shell sh;
}

class trace {
  session sess;
  int tracePosition; 
  float connTracePos; 
  invariant {
    assert(tracePosition!<0);
    assert(tracePosition<sess.components.length);
    assert((connTracePos!<0f)&&(connTracePos!>1f));
  }
}
