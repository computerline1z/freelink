module tools.tests;
import tools.base;
import std.stdio: writefln, format;

char[] logResult(char[] name, bool succeed, char[] reason) {
  char[] spacing; if (name.length<30) spacing=" ".times(30-name.length);
  return " -"~name~"- "~spacing~"["~(succeed?"good":"fail")~"] - "~reason;
}

void mustFail(char[] name, void delegate()[] dgs...) {
  Exception ge=null;
  try foreach (dg; dgs) dg(); catch (Exception e) { ge=e; goto good; }
  // I <3 this line
  throw new Exception(name~": fail, Expected Exception not caught");
good:
  writefln=logResult(name, true, "Expected exception ("~ge.toString~") caught");
  return;
}

void mustEqual(T...)(char[] name, T stuffs) {
  foreach (thing; stuffs[0..$-1]) if (thing!=stuffs[$-1])
    throw new Exception(name~": failed; "~format(thing)~" is not "~format(stuffs[$-1])~".");
  writefln(logResult(name, true, "Result equals "~format(stuffs[$-1])));
}

void Assert(char[] name, bool delegate()[] dgs...) {
  class AssertInternalPseudoException : Exception { this() { super(""); } }
  try foreach (dg; dgs) if (!dg()) throw new AssertInternalPseudoException;
  catch (AssertInternalPseudoException aipe) throw new Exception(name~": fail, eval to false");
  catch (Exception e) throw new Exception(name~": fail, ("~e.toString~")");
  writefln(logResult(name, true, "No exceptions, all conditions true"));
}

unittest {
  mustFail("UnitTestFailure", mustFail("EvidentFailure", {}));
  mustFail("UnitTestAssertFailure", Assert("EvidentFailure", 1==0));
  mustFail("UnitTestmustBeFailure", mustEqual("Fail", true, false));
}
