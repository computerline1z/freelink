struct text {
}

struct drive {
  text typename;
  int space;
}

struct cpu {
  text typename;
  float speed;
  /// This might be used in the story. Quantum CPUs are not _that_ useful for everyday tasks,
  /// but give you a huge bonus to decryption speed.
  bool quant=false;
}

struct isp {
  text name;
  int speed; /// given in B/s
  float qos; /// packet prioritization .. makes for longer chains
}

struct hardware {
  /// The available storage in a hardware configuration must _never_ go down. Downgrades not allowed. :p
  drive[] drives;
  cpu[] cores;
  isp ISP;
}

class computer {
  hardware hw;
  // only the player computer has software. Only non-player computers have meta software.
}

class connection {
  computer start, end;
  float getLinkQuality();
  float getTraceProgress();
}

class route {
  computer[] components;
  class connectionArray { }
  connectionArray connections;
  invariant {
    assert(components.length>2);
    foreach (c; connections) assert(c.start.canReach(c.end));
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
