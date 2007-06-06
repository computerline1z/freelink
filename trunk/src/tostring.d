import computer, file, hardware;
import std.string;

char[] toString (Computer c)
{
  return std.string.toString (c.ip) ~ " - " ~ c.name;
}

char[] toString (File f)
{
  return format ("%s - %s (%5d)", f.sourceIP, f.name, f.size);
}
