module hardware;
import nls;

typedef uint kquad;  // KiloQuad, used in Star Trek and Uplink
typedef uint gflops; // GigaFlops, deliciously ambiguous
alias uint IP;     // Internet address

class Hardware
{
  char[] name;
  ubyte level;
}

class CPU : Hardware
{
  gflops speed;
  // Quantum-enhanced CPU (Part of the story line). Might suck at
  // everyday tasks, but excel at decoding encryption.
  bool quantum;
}

class Storage : Hardware
{
  kquad space;
}

class Motherboard : Hardware
{
  ubyte maxCores; // Maximum number of CPUs
  ubyte maxDrives;
}
