version(DigitalMars) extern (Windows): else extern(C):

struct gdIOCtx {
  int function(gdIOCtx *) getC;
  int function(gdIOCtx *, void*, int) getBuf;
  void function(gdIOCtx*, int) putC;
  int function(gdIOCtx *, void*, int) putBuf;
  int function(gdIOCtx *, int) seek;
  int function(gdIOCtx *) tell;
  void function(gdIOCtx *) free;
}

const gdMaxColors=256;
const gdAlphaMax=127;
const gdAlphaOpaque=0;
const gdAlphaTransparent=127;
const gdRedMax=255;
const gdGreenMax=255;
const gdBlueMax=255;
uint gdTrueColorGetAlpha(uint c) { return (c & 0x7F000000) >> 24; }
uint gdTrueColorGetRed(uint c) { return (c & 0xFF0000) >> 16; }
uint gdTrueColorGetGreen(uint c) { return (c & 0x00FF00) >> 8; }
uint gdTrueColorGetBlue(uint c) { return c & 0x0000FF; }

int gdAlphaBlend (int dest, int src);

struct gdImage
{
  ubyte **pixels;
  int sx, sy;
  int colorsTotal;
  int[gdMaxColors] red, green, blue, open;
  int transparent;
  int *polyInts;
  int polyAllocated;
  gdImage *brush;
  gdImage *tile;
  int[gdMaxColors] brushColorMap, tileColorMap;
  int styleLength, stylePos;
  int *style;
  int interlace;
  int thick;
  int[gdMaxColors] alpha;
  int trueColor;
  int **tpixels;
  int alphaBlendingFlag;
  int saveAlphaFlag;
  int AA;
  int AA_color;
  int AA_dont_blend;
  int cx1;
  int cy1;
  int cx2;
  int cy2;
}

alias gdImage *gdImagePtr;

struct gdFont { int nchars, offset, w, h; char *data; }
alias gdFont *gdFontPtr;

const gdDashSize=4;

const gdStyled=-2;
const gdBrushed=-3;
const gdStyleBrushed=-4;
const gdTiled=-5;
const gdTransparent=-6;
const gdAntiAliased=-7;
gdImagePtr gdImageCreate (int sx, int sy);
alias gdImageCreate gdImageCreatePalette;
gdImagePtr gdImageCreateTrueColor (int sx, int sy);
gdImagePtr gdImageCreateFromPngPtr (int size, void *data);
gdImagePtr gdImageCreateFromGifPtr (int size, void *data);
gdImagePtr gdImageCreateFromJpegPtr (int size, void *data);

void gdImageDestroy (gdImagePtr im);

void gdImageSetPixel (gdImagePtr im, int x, int y, int color);
int gdImageGetPixel (gdImagePtr im, int x, int y);
int gdImageGetTrueColorPixel (gdImagePtr im, int x, int y);
void gdImageLine (gdImagePtr im, int x1, int y1, int x2, int y2, int color);
void gdImageDashedLine (gdImagePtr im, int x1, int y1, int x2, int y2, int color);
void gdImageRectangle (gdImagePtr im, int x1, int y1, int x2, int y2, int color);
void gdImageFilledRectangle (gdImagePtr im, int x1, int y1, int x2, int y2, int color);
gdImagePtr gdImageCreatePaletteFromTrueColor (gdImagePtr im, int ditherFlag, int colorsWanted);
void gdImageTrueColorToPalette (gdImagePtr im, int ditherFlag, int colorsWanted);


void *gdImageJpegPtr (gdImagePtr im, int *size, int quality);
void *gdImageGifPtr (gdImagePtr im, int *size);
void *gdImagePngPtr (gdImagePtr im, int *size);

void gdImageFill (gdImagePtr im, int x, int y, int color);
void gdImageCopy (gdImagePtr dst, gdImagePtr src, int dstX, int dstY, int srcX, int srcY, int w, int h);
void gdImageCopyResized (gdImagePtr dst, gdImagePtr src, int dstX, int dstY,
			   int srcX, int srcY, int dstW, int dstH, int srcW,
			   int srcH);

void gdImageCopyResampled (gdImagePtr dst, gdImagePtr src, int dstX,
			     int dstY, int srcX, int srcY, int dstW, int dstH,
			     int srcW, int srcH);
void gdImageCopyRotated (gdImagePtr dst,
			   gdImagePtr src,
			   double dstX, double dstY,
			   int srcX, int srcY,
			   int srcWidth, int srcHeight, int angle);
void gdFree (void *m);
