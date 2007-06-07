module png;

import std.stdio, std.string, std.traits, std.zlib, func, SDL, std.math: abs;

template ArrayElemType(T: T[]) { alias T ArrayElemType; }

template unstatic(T) {
  static if (isStaticArray!(T)) alias ArrayElemType!(T)[] unstatic;
  else alias T unstatic;
}

unstatic!(T) chip(T, bool reverse=false)(inout ubyte[] data) {
  static if (reverse) (data.ptr)[0..T.sizeof].reverse;
  T res=*(cast(T*)data.ptr);
  data=data[T.sizeof..$];
  static if (isStaticArray!(T)) return res.dup;
  else return res;
}

void putpixel(SDL_Surface *surf, int x, int y, ubyte[] data) {
  assert((data.length==3)||(data.length==4));
  assert(surf.format.BytesPerPixel==4);
  assert((x>=0)&&(x<surf.w));
  assert((y>=0)&&(y<surf.h));
  (cast(ubyte*)surf.pixels + y*surf.pitch + x*4)[0..4]=[data[2], data[1], data[0], 0];
}

SDL_Surface *decode(void[] _data) {
  ubyte[] data=cast(ubyte[])_data;
  writefln("PNG decoding ", data.length);
  assert(data[0..8]==[cast(ubyte)137, 80, 78, 71, 13, 10, 26, 10], "Not a PNG file!");
  data=data[8..$];
  ubyte[] compressed;
  uint width, height, depth, color;
  while (data.length) {
    auto len=chip!(uint, true)(data);
    auto type=chip!(char[4])(data); auto upper=map(type, (char c) { return (c&(1<<5))?false:true; });
    auto chunk=data[0..len];
    data=data[len..$];
    auto crc=chip!(uint)(data);
    switch (type) {
      case "tEXt": writefln("Text data: ", split(cast(char[])chunk, "\0")[0], "==", split(cast(char[])chunk, "\0")[1]); break;
      case "IDAT": compressed~=chunk; break;
      case "IHDR":
        writefln("Header");
        width=chip!(uint, true)(chunk); height=chip!(uint, true)(chunk); depth=chip!(ubyte)(chunk);
        color=chip!(ubyte)(chunk);
        writefln("Color mode: ", ["Grayscale", "Invalid", "RGB", "Palette", "Grayscale/Alpha", "Invalid", "RGBA"][color]);
        assert((color==2)||(color==6), "Invalid color mode: only RGB(A) supported");
        auto compm=chip!(ubyte)(chunk);
        assert(compm==0, "Unsupported compression method "~.toString(compm));
        auto filterm=chip!(ubyte)(chunk);
        assert(!filterm, "Unsupported filter method: "~.toString(filterm));
        auto interlace=chip!(ubyte)(chunk);
        assert(!interlace, "Interlacing not yet supported");
        writefln("Width: ", width, " Height: ", height, " Depth: ", depth);
        writefln("Undecoded: ", chunk.length);
      break;
      default:
        writefln("Chunk type ", type, ": ",
          upper[0]?"Critical":"Ancilliary", ", ",
          upper[1]?"Public":"Private", ", ",
          upper[3]?"Unsafe2c":"Safe2c"
        );
      break;
    }
  }
  writefln(compressed.length, " compressed bytes");
  writefln("Decompressing");
  auto decomp=cast(ubyte[])uncompress(cast(char[])compressed);
  writefln("Decompressed ", decomp.length, " bytes");
  int bpp; bpp=[0, 0, 3, 0, 0, 0, 4][color]*[8: 1, 16: 2, 24: 3, 32: 4][depth];
  writefln("Pixel size: ", bpp);
  static ubyte limit(int v) { while (v<0) v+=256; return cast(ubyte)v; }
  // taken from the RFC literally
  static ubyte PaethPredictor(ubyte a, ubyte b, ubyte c) {
    //a = left, b = above, c = upper left
    auto p = a + b - c; // initial estimate
    auto pa = abs(p - a); // distances to a, b, c
    auto pb = abs(p - b);
    auto pc = abs(p - c);
    //return nearest of a,b,c,
    //breaking ties in order a,b,c.
    if ((pa <= pb)&&(pa <= pc)) return a;
      else if (pb <= pc) return b;
      else return c;
  }
  ubyte[][] lines;
  for (int y=0; y<height; ++y) {
    ubyte filter=chip!(ubyte)(decomp);
    auto scanline=decomp[0..width*bpp]; decomp=decomp[width*bpp..$];
    switch (filter) {
      case 0: break;
      /// sub: add previous pixel
      case 1: foreach (i, inout entry; scanline) {
        ubyte left=0; if (i!<bpp) left=scanline[i-bpp];
        entry=limit(entry+left);
      }
      break;
      /// up: add previous line
      case 2: foreach (i, inout entry; scanline) {
        ubyte up=0; if (lines.length) up=lines[$-1][i];
        entry=limit(entry+up);
      }
      break;
      /// average: (sub+up)/2
      case 3: foreach (i, inout entry; scanline) {
        ubyte left=0; if (i!<bpp) left=scanline[i-bpp];
        ubyte up=0; if (lines.length) up=lines[$-1][i];
        entry=limit(entry+(left+up)/2);
      }
      break;
      /// paeth
      case 4: foreach (i, inout entry; scanline) {
        ubyte left=0;
        if (i!<bpp) left=scanline[i-bpp];
        ubyte up=0; ubyte upleft=0;
        if (lines.length) {
          up=lines[$-1][i];
          if (i!<bpp) upleft=lines[$-1][i-bpp];
        }
        entry=limit(entry+PaethPredictor(left, up, upleft));
      }
      break;
      default: assert(false);
    }
    lines~=scanline;
  }
  assert(!decomp.length, "Decompression failed: data left over");

  auto result=SDL_CreateRGBSurface(0, width, height, depth, 0, 0, 0, 0);
  foreach (y, line; lines) {
    if (depth==8) {
      for (int x=0; x<width; ++x) {
        putpixel(result, x, y, [chip!(ubyte)(line), chip!(ubyte)(line), chip!(ubyte)(line), (color==2)?cast(ubyte)0:chip!(ubyte)(line)]);
      }
    } else assert(false, "Unsupported bit depth: "~.toString(depth));
  }
  return result;
}

//import std.file;
//static this() { decode(cast(ubyte[])read("test.png")); }
