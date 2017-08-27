
---
title: Java应用内存为什么和堆内存差那么多?
date: 2017-08-25 12:20:46
categories:
    - tuning
tags: 
    - 性能优化
    - JAVA
---

事情从这张图开始
![应用内存报警](http://oqcey66z7.bkt.clouddn.com/public/resource/%E5%B1%8F%E5%B9%95%E5%BF%AB%E7%85%A7%202017-08-25%2013.09.52.png)

<!--more-->

登录服务器查看:

查看JVM heap空间

```angularjs
[test@testx1 ~]# jmap -heap 18657
Attaching to process ID 18657, please wait...
Debugger attached successfully.
Server compiler detected.
JVM version is 25.45-b02

using parallel threads in the new generation.
using thread-local object allocation.
Concurrent Mark-Sweep GC

Heap Configuration:
   MinHeapFreeRatio         = 40
   MaxHeapFreeRatio         = 70
   MaxHeapSize              = 2726297600 (2600.0MB)
   NewSize                  = 419430400 (400.0MB)
   MaxNewSize               = 419430400 (400.0MB)
   OldSize                  = 2306867200 (2200.0MB)
   NewRatio                 = 2
   SurvivorRatio            = 2
   MetaspaceSize            = 786432000 (750.0MB)
   CompressedClassSpaceSize = 1073741824 (1024.0MB)
   MaxMetaspaceSize         = 786432000 (750.0MB)
   G1HeapRegionSize         = 0 (0.0MB)

Heap Usage:
New Generation (Eden + 1 Survivor Space):
   capacity = 314572800 (300.0MB)
   used     = 68754128 (65.56904602050781MB)
   free     = 245818672 (234.4309539794922MB)
   21.856348673502605% used
Eden Space:
   capacity = 209715200 (200.0MB)
   used     = 57866416 (55.18571472167969MB)
   free     = 151848784 (144.8142852783203MB)
   27.592857360839844% used
From Space:
   capacity = 104857600 (100.0MB)
   used     = 10887712 (10.383331298828125MB)
   free     = 93969888 (89.61666870117188MB)
   10.383331298828125% used
To Space:
   capacity = 104857600 (100.0MB)
   used     = 0 (0.0MB)
   free     = 104857600 (100.0MB)
   0.0% used
concurrent mark-sweep generation:
   capacity = 2306867200 (2200.0MB)
   used     = 1198515728 (1142.993667602539MB)
   free     = 1108351472 (1057.006332397461MB)
   51.95425761829723% used

73803 interned Strings occupying 10463600 bytes.
```

查看进程的内存使用

```angularjs
[test@testx1 ~]# ps -p 18657 -o vsz,rss
   VSZ   RSS
7680036 3442924
```

RSS是3442924/1024/1024=3.28G,JVM Heap堆大小为2600/1024=2.5G,这中间为什么差了将近一个G呢？

VSZ是指已分配的线性空间大小，这个大小通常并不等于程序实际用到的内存大小，产生这个的可能性很多，比如内存映射，共享的动态库，或者向系统申请了更多的堆，都会扩展线性空间大小

看一个进程有哪些内存映射，可以使用 pmap 命令来查看``pmap -x pid``得出的值是和进程内存使用中得到的值相同的

RSZ是Resident Set Size，常驻内存大小，即进程实际占用的物理内存大小， 在现在这个例子当中，RSZ和实际堆内存占用差了1G，这1G的内存组成分别为：

* JVM本身需要的内存，包括其加载的第三方库以及这些库分配的内存
* NIO的DirectBuffer是分配的native memory
* 内存映射文件，包括JVM加载的一些JAR和第三方库，以及程序内部用到的。上面 pmap 输出的内容里，有一些静态文件所占用的大小不在Java的heap里，因此作为一个Web服务器，赶紧把静态文件从这个Web服务器中人移开吧，放到nginx或者CDN里去吧。
* JIT， JVM会将Class编译成native代码，这些内存也不会少，如果使用了Spring的AOP，CGLIB会生成更多的类，JIT的内存开销也会随之变大，而且Class本身JVM的GC会将其放到Perm Generation里去，很难被回收掉，面对这种情况，应该让JVM使用ConcurrentMarkSweep GC，并启用这个GC的相关参数允许将不使用的class从Perm Generation中移除， 参数配置： -XX:+UseConcMarkSweepGC -X:+CMSPermGenSweepingEnabled -X:+CMSClassUnloadingEnabled，如果不需要移除而Perm Generation空间不够，可以加大一点： -X:PermSize=256M -X:MaxPermSize=512M
* JNI，一些JNI接口调用的native库也会分配一些内存，如果遇到JNI库的内存泄露，可以使用valgrind等内存泄露工具来检测
* 线程栈，每个线程都会有自己的栈空间，如果线程一多，这个的开销就很明显了
* jmap/jstack 采样，频繁的采样也会增加内存占用，如果你有服务器健康监控，记得这个频率别太高，否则健康监控变成致病监控了。