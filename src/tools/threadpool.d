module tools.threadpool;
import tools.base;
public import tools.iter;

import std.thread;
import std.c.time: csleep=sleep;
class ThreadPool {
  class CountTo {
    size_t target;
    size_t[] counts; // one entry for each Thread in myThreads
    this(size_t to) { target=to; counts.length=myThreads.length; }
    void inc() {
      auto thr=Thread.getThis;
      foreach (id, t; myThreads) if (t is thr) { counts[id]++; return; }
      throw new Exception("CountTo used from thread that's not in pool!");
    }
    size_t remaining() { return target-(counts~reduces!("_+=__")); }
  }
  private Thread[] myThreads;
  Thread mainThread=null;
  void delegate()[] tasks;
  int runThread() {
    while (mainThread.getState==Thread.TS.RUNNING) {
     void delegate() task=null;
     synchronized(this) { if (tasks.length) { task=tasks[0]; tasks=tasks[1..$]; } }
     if (task) task(); else Thread.getThis.pause;
    }
    return 0;
  }
  this(int threads) {
    myThreads=new Thread[threads];
    mainThread=Thread.getThis;
    foreach (ref thr; myThreads) {
      thr=new Thread(&runThread);
      thr.start;
    }
  }
  private static void delegate() DefaultSleep;
  static this() { DefaultSleep=delegate void() { csleep(0); }; }
  void addTask(void delegate() t) {
    synchronized(this) tasks~=t;
    foreach (thr; myThreads) { thr.resume; if (!tasks.length) break; }
  }
  void addTasks(void delegate()[] ts) {
    synchronized(this) tasks~=ts;
    foreach (thr; myThreads) { thr.resume; if (!tasks.length) break; }
  }
  void distribute(T)(Iterator!(T) i, void delegate(T) dg, void delegate() sleep=DefaultSleep) {
    size_t left=0;
    class pair {
      T t;
      void delegate(T) dg;
      void call() { dg(t); synchronized(i) left--; }
    }
    foreach (entry; i) {
      auto p=new pair;
      p.t=entry; p.dg=dg;
      synchronized(i) left++;
      addTask(&p.call);
    }
    while (left) sleep();
  }
}
