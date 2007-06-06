import computer, file, tostring;
import std.stdio;
import contrib.SDL;

void main ()
{
  writefln ("FreeLink Command Line");
  File f = new File (1, "Test.txt", 3, 0, false);
  Computer x = new Computer (0, "Localhost", ServerType.web);
  writefln (toString (x));
  writefln (toString (f));
  writefln ("Available space: ", x.availableSpace);
}