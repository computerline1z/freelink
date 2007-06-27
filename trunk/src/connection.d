import computer, nls;

class Connection {
  char[] name;
  float speed; // kquads per second

  float freeResources (Route r) {
    return float.nan;
  }
}

class Route {
  Computer[] nodes;
  invariant() {
    assert (nodes.length > 2);
  }
}

class Trace {
}
