module png;

import std.stdio, std.string, std.traits, std.zlib, SDL, tools.iter, std.math: abs;

template ArrayElemType(T: T[]) { alias T ArrayElemType; }

template unstatic(T) {
  static if (isStaticArray!(T)) alias ArrayElemType!(T)[] unstatic;
  else alias T unstatic;
}

unstatic!(T) chip(T, bool reverse=false)(ref ubyte[] data) {
  static if (reverse) (data.ptr)[0..T.sizeof].reverse;
  T res=*(cast(T*)data.ptr);
  data=data[T.sizeof..$];
  static if (isStaticArray!(T)) return res.dup;
  else return res;
}

SDL_Surface *MakeSurf(size_t width, size_t height, size_t bpp) {
  //writefln("Create Surface: ", width, "/", height, "-", bpp);
  assert(width!=size_t.max); assert(height!=size_t.max);
  assert(width>0); assert(height>0);
  auto res=SDL_CreateRGBSurface(SDL_SWSURFACE, cast(ushort)width, cast(ushort)height, bpp, 0, 0, 0, 0);
  return res;
}

void putpixel(X, Y)(SDL_Surface *surf, X x, Y y, ubyte[] data) {
  assert((x>=0)&&(x<surf.w));
  assert((y>=0)&&(y<surf.h));
  //static assert(is(T == ubyte[4]) || is(T == ubyte[3]), "Faulty T being "~T.stringof);
  auto bpp=surf.format.BytesPerPixel;
  assert(data.length!>bpp, format("Wrong data length: length(", data.length, ") > bpp(", bpp, ")  !"));
  uint pix=void;
  if (data.length==4) pix=SDL_MapRGBA(surf.format, data[0], data[1], data[2], data[3]);
  else if (data.length==3) pix=SDL_MapRGB(surf.format, data[0], data[1], data[2]);
  else assert(false, "Error: BPP is "~toString(bpp));
  *cast(uint*)(cast(ubyte*)surf.pixels + y*surf.pitch + x*bpp)=pix;
}

ubyte[] getpixel(X, Y)(SDL_Surface *surf, X x, Y y) {
  assert((x>=0)&&(x<surf.w));
  assert((y>=0)&&(y<surf.h), "error: "~toString(y)~" out of bounds");
  auto bpp=surf.format.BytesPerPixel;
  uint pix=void;
  uint pixel=*(cast(uint*)(cast(ubyte*)surf.pixels + y*surf.pitch + x*bpp));
  auto array=new ubyte[4]; SDL_GetRGBA(pixel, surf.format, &array[0], &array[1], &array[2], &array[3]);
  return array;
}

SDL_Surface *decode(void[] _data) {
  ubyte[] data=cast(ubyte[])_data;
  assert(data[0..8]==[cast(ubyte)137, 80, 78, 71, 13, 10, 26, 10], "Not a PNG file!");
  data=data[8..$];
  ubyte[] compressed;
  uint width, height, depth, color;
  while (data.length) {
    auto len=chip!(uint, true)(data);
    auto type=chip!(char[4])(data); auto upper=type~maps!("(_&(1<<5))?false:true")~toArray;
    auto chunk=data[0..len];
    data=data[len..$];
    auto crc=chip!(uint)(data);
    switch (type) {
      case "tEXt": writefln("Text data: ", split(cast(char[])chunk, "\0")[0], "==", split(cast(char[])chunk, "\0")[1]); break;
      case "IDAT": compressed~=chunk; break;
      case "IHDR":
        width=chip!(uint, true)(chunk); height=chip!(uint, true)(chunk); depth=chip!(ubyte)(chunk);
        color=chip!(ubyte)(chunk);
        assert((color==2)||(color==6), "Invalid color mode: only RGB(A) supported");
        auto compm=chip!(ubyte)(chunk);
        assert(compm==0, "Unsupported compression method "~.toString(compm));
        auto filterm=chip!(ubyte)(chunk);
        assert(!filterm, "Unsupported filter method: "~.toString(filterm));
        auto interlace=chip!(ubyte)(chunk);
        assert(!interlace, "Interlacing not yet supported");
        //writefln("Width: ", width, " Height: ", height, " Depth: ", depth);
      break;
      default:
        /*writefln("Chunk type ", type, ": ",
          upper[0]?"Critical":"Ancilliary", ", ",
          upper[1]?"Public":"Private", ", ",
          upper[3]?"Unsafe2c":"Safe2c"
        );*/
      break;
    }
  }
  auto decomp=cast(ubyte[])uncompress(cast(char[])compressed);
  assert((depth==8)||(depth==16)||(depth==24)||(depth==32));
  int bpp; bpp=[0, 0, 3, 0, 0, 0, 4][color]*(depth/8);
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
  ubyte[][] lines; lines.length=height;
  for (int y=0; y<height; ++y) {
    ubyte filter=chip!(ubyte)(decomp);
    auto scanline=decomp[0..width*bpp]; decomp=decomp[width*bpp..$];
    switch (filter) {
      case 0: break;
      /// sub: add previous pixel
      case 1: foreach (i, ref entry; scanline) {
        ubyte left=0; if (i!<bpp) left=scanline[i-bpp];
        entry=limit(entry+left);
      }
      break;
      /// up: add previous line
      case 2: foreach (i, ref entry; scanline) {
        ubyte up=0; if (lines.length) up=lines[y-1][i];
        entry=limit(entry+up);
      }
      break;
      /// average: (sub+up)/2
      case 3: foreach (i, ref entry; scanline) {
        ubyte left=0; if (i!<bpp) left=scanline[i-bpp];
        ubyte up=0; if (lines.length) up=lines[y-1][i];
        entry=limit(entry+(left+up)/2);
      }
      break;
      /// paeth
      case 4: foreach (i, ref entry; scanline) {
        ubyte left=0;
        if (i!<bpp) left=scanline[i-bpp];
        ubyte up=0; ubyte upleft=0;
        if (lines.length) {
          up=lines[y-1][i];
          if (i!<bpp) upleft=lines[y-1][i-bpp];
        }
        entry=limit(entry+PaethPredictor(left, up, upleft));
      }
      break;
      default: assert(false);
    }
    lines[y]=scanline;
  }
  assert(!decomp.length, "Decompression failed: data left over");
  auto result=MakeSurf(width, height, bpp*8);
  foreach (y, ref line; lines) {
    if (depth==8) {
      if (color==2)
        for (int x=0; x<width; ++x) putpixel(result, x, y, chip!(ubyte[3])(line));
      else if (color==6)
        for (int x=0; x<width; ++x) putpixel(result, x, y, chip!(ubyte[4])(line));
      else assert(false);
    } else assert(false, "Unsupported bit depth: "~.toString(depth));
  }
  return result;
}
