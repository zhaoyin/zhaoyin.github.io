
---
title: JVM FullGC的分析调优
date: 2017-08-14 20:40:46
reward: true
categories:
    - tuning
tags: 
    - JVM
    - CMS
    - FullGC
---

## 实践
cpu 100% 通常的思路是查看runnable的线程，但如果发现是耗尽cpu的是vmthread。多半会伴随old区已满（此时垃圾回收已停止），通常这是由于在并发下短时间内创建很多对象造成。

一个例子
很抱歉，这个例子的原始样本日志已经被我删除了，而且是调优之后才想着记录下来的，所以下面的数据是根据记忆模拟的，但是能说明问题。
```angular2html
[test@mybook ~]# jstat -gcutil 13024 500 10
  S0     S1     E      O      M     CCS    YGC     YGCT    FGC    FGCT     GCT   
  0.00   4.95  93.52  12.97  82.80  69.10   4163   62.073     125  430.260  492.333
  3.81   0.00   8.03  12.97  82.81  69.10   4164   62.088     125  430.260  492.333
  3.81   0.00  15.37  12.97  82.81  69.10   4164   62.088     125  430.260  492.333
  3.81   0.00  30.35  12.97  82.81  69.10   4164   62.088     125  430.260  492.333
  3.81   0.00  40.27  12.97  82.81  69.10   4164   62.088     125  430.260  492.333
  3.81   0.00  46.95  12.97  82.81  69.10   4164   62.088     125  430.260  492.333
  3.81   0.00  51.08  12.97  82.81  69.10   4164   62.088     125  430.260  492.333
  3.81   0.00  54.42  12.97  82.81  69.10   4164   62.088     125  430.260  492.333
  3.81   0.00  56.63  12.97  82.81  69.10   4164   62.088     125  430.260  492.333
  3.81   0.00  67.56  12.97  82.81  69.10   4164   62.088     125  430.260  492.333
```

执行``jps -mlvV``可以看出有问题应用的jvm参数如下
```angular2html
-Xms2400M -Xmx2400M -Xss512K -Xmn600M -XX:MetaspaceSize=750M -XX:MaxMetaspaceSize=750M -Xloggc:/tmp/gc.log -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=700K -XX:+PrintGCDateStamps -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSParallelRemarkEnabled -XX:+CMSClassUnloadingEnabled -XX:SurvivorRatio=2 -XX:LargePageSizeInBytes=128M -XX:+UseFastAccessorMethods -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=75 -XX:SoftRefLRUPolicyMSPerMB=0 -XX:+PrintClassHistogram -XX:+PrintGCDetails -XX:CMSFullGCsBeforeCompaction=1 -XX:+UseCMSCompactAtFullCollection -Xverify:none -Dfile.encoding=utf-8 
```

这个在频繁FullGC，年老代GC用的是CMS，CMS就是以停顿时间/STW短著称的，125次FullGC花费430s意味着每次GC要3s，这是不可接受的，正常CMS的FullGC也不会超过1s。

<!--more-->

heap大小为2400M，新生代大小为600M，75%时执行CMS，比例为2

老年代为2400-600=1800，老年代达到1350M时执行回收，此时老年代还剩下450M，此时新生代的对象如果要回收到老年代很可能申请不到足够的老年代空间，因为新生代有600M，就会FullGC。

另外说一下，开了记录GC日志的开关，一定要配套打开其他几个开关``-Xloggc:/tmp/gc.log -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=700K``,这个的例子是每个GC日志大小为700K，日志文件数为最新的10个，其他的会被丢弃。没有这样的设置GC日志文件会越来越大，同时最好打开``-XX:+PrintGCDateStamps``，这样能知道发生GC的具体时间，能同步查询这段时间系统的日志来最终确定问题。

```angular2html
2017-08-16T10:12:49.579+0800: 44723.945: [Full GC (Allocation Failure) 44723.945: [CMS2017-08-16T10:12:52.213+0800: 44726.579: [CMS-concurrent-mark: 2.638/2.640 secs] [Times: user=2.65 sys=0.00, real=2.64 secs]
 (concurrent mode failure): 2047999K->2047999K(2048000K), 8.6606867 secs] 2355199K->2354674K(2355200K), [Metaspace: 103711K->103711K(1202176K)], 8.6608144 secs] [Times: user=8.56 sys=0.00, real=8.66 secs]
2017-08-16T10:12:58.247+0800: 44732.613: [Full GC (Allocation Failure) 44732.613: [CMS: 2047999K->2047999K(2048000K), 5.8058865 secs] 2355199K->2354690K(2355200K), [Metaspace: 103711K->103711K(1202176K)], 5.8060044 secs] [Times: user=5.76 sys=0.00, real=5.81 secs]
2017-08-16T10:13:04.057+0800: 44738.423: [GC (CMS Initial Mark) [1 CMS-initial-mark: 2047999K(2048000K)] 2355177K(2355200K), 0.2686993 secs] [Times: user=0.40 sys=0.00, real=0.27 secs]
2017-08-16T10:13:04.326+0800: 44738.692: [CMS-concurrent-mark-start]
2017-08-16T10:13:04.327+0800: 44738.693: [Full GC (Allocation Failure) 44738.693: [CMS2017-08-16T10:13:07.013+0800: 44741.379: [CMS-concurrent-mark: 2.686/2.687 secs] [Times: user=2.71 sys=0.00, real=2.69 secs]
 (concurrent mode failure): 2047999K->2047999K(2048000K), 8.5444313 secs] 2355199K->2354650K(2355200K), [Metaspace: 103711K->103711K(1202176K)], 8.5445348 secs] [Times: user=8.59 sys=0.00, real=8.55 secs]
2017-08-16T10:13:12.877+0800: 44747.243: [Full GC (Allocation Failure) 44747.243: [CMS: 2047999K->2047999K(2048000K), 5.6359385 secs] 2355199K->2354677K(2355200K), [Metaspace: 103711K->103711K(1202176K)], 5.6360569 secs] [Times: user=5.67 sys=0.00, real=5.64 secs]
2017-08-16T10:13:18.517+0800: 44752.883: [GC (CMS Initial Mark) [1 CMS-initial-mark: 2047999K(2048000K)] 2354891K(2355200K), 0.2264203 secs] [Times: user=0.35 sys=0.00, real=0.23 secs]
2017-08-16T10:13:18.743+0800: 44753.109: [CMS-concurrent-mark-start]
2017-08-16T10:13:18.745+0800: 44753.112: [Full GC (Allocation Failure) 44753.112: [CMS2017-08-16T10:13:21.400+0800: 44755.767: [CMS-concurrent-mark: 2.655/2.657 secs] [Times: user=2.68 sys=0.00, real=2.66 secs]
 (concurrent mode failure): 2047999K->2047999K(2048000K), 8.4214522 secs] 2355193K->2354669K(2355200K), [Metaspace: 103715K->103715K(1202176K)], 8.4215869 secs] [Times: user=8.45 sys=0.00, real=8.42 secs]
```

因为我们设置了PrintGCDateStamps，所以我们可以看到10:13在频繁FullGC，频繁FullGC是CMS没有释放掉对象，说明此时有大对象存在。监控程序日志或者dump可以看到此时在做导入操作，说明导入操作应该优化代码。

我们也同时可以对JVM做一些优化，可以看到FullGC是CMSGC后并没有释放空间，导致还是超过75%的回收比例，继续触发FullGC。

方案是提高年老代大小，降低触发CMS的比例，比如把head的大小进一步提高，降低Xmn的大小，并将CMSInitiatingOccupancyFraction降低到70%

修改如下:
``-Xms2600M -Xmx2600M -Xss512K -Xmn400M -XX:MetaspaceSize=750M -XX:MaxMetaspaceSize=750M -Xloggc:/tmp/gc.log -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=700K -XX:+PrintGCDateStamps -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSParallelRemarkEnabled -XX:+CMSClassUnloadingEnabled -XX:SurvivorRatio=2 -XX:LargePageSizeInBytes=128M -XX:+UseFastAccessorMethods -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=70 -XX:SoftRefLRUPolicyMSPerMB=0 -XX:+PrintClassHistogram -XX:+PrintGCDetails -XX:CMSFullGCsBeforeCompaction=1 -XX:+UseCMSCompactAtFullCollection``
效果如下:
```angular2html
[test@mybook ~]# jstat -gcutil 5821 500 10
  S0     S1     E      O      M     CCS    YGC     YGCT    FGC    FGCT     GCT   
  5.36   0.00  36.35  33.55  79.29  63.08   2194   48.136     0    0.000   48.136
  5.36   0.00  42.95  33.55  79.29  63.08   2194   48.136     0    0.000   48.136
  5.36   0.00  52.32  33.55  79.29  63.08   2194   48.136     0    0.000   48.136
  5.36   0.00  60.25  33.55  79.29  63.08   2194   48.136     0    0.000   48.136
  5.36   0.00  66.12  33.55  79.29  63.08   2194   48.136     0    0.000   48.136
  5.36   0.00  83.03  33.55  79.29  63.08   2194   48.136     0    0.000   48.136
  5.36   0.00  93.31  33.55  79.29  63.08   2194   48.136     0    0.000   48.136
  0.00   4.32  22.42  33.57  79.30  63.09   2195   48.165     0    0.000   48.165
  0.00   4.32  29.67  33.57  79.30  63.09   2195   48.165     0    0.000   48.165
  0.00   4.32  44.94  33.57  79.30  63.09   2195   48.165     0    0.000   48.165
```


另一个例子

```angular2html
[test@mybook ~]# jstat -gcutil 14054 500 10
  S0     S1     E      O      M     CCS    YGC     YGCT    FGC    FGCT     GCT   
  0.00  57.60  89.27  17.26  81.04  52.05   1707   19.806   157  448.888  468.694
  0.00  57.60  90.92  17.26  81.04  52.05   1707   19.806   157  448.888  468.694
  0.00  57.60  92.88  17.26  81.04  52.05   1707   19.806   157  448.888  468.694
  0.00  57.60  94.00  17.26  81.04  52.05   1707   19.806   157  448.888  468.694
  0.00  57.60  95.78  17.26  81.04  52.05   1707   19.806   157  448.888  468.694
  0.00  57.60  97.37  17.26  81.04  52.05   1707   19.806   157  448.888  468.694
  0.00  57.60  98.98  17.26  81.04  52.05   1707   19.806   157  448.888  468.694
 53.92   0.00   0.36  17.71  81.08  51.94   1708   19.835   157  448.888  468.723
 53.92   0.00   2.28  17.71  81.08  51.94   1708   19.835   157  448.888  468.723
 53.92   0.00   3.67  17.71  81.08  51.94   1708   19.835   157  448.888  468.723
```
```angular2html
2017-08-16T08:20:56.859+0800: 68169.646: [GC (Allocation Failure) [PSYoungGen: 1045176K->36643K(1070080K)] 2091161K->1120579K(2196480K), 0.0599351 secs] [Times: user=0.23 sys=0.00, real=0.06 secs]
2017-08-16T08:20:56.919+0800: 68169.706: [Full GC (Ergonomics) [PSYoungGen: 36643K->0K(1070080K)] [ParOldGen: 1083936K->1115405K(1126400K)] 1120579K->1115405K(2196480K), [Metaspace: 150009K->149972K(1200128K)], 2.2663258 secs] [Times: user=7.93 sys=0.00, real=2.27 secs]
2017-08-16T08:20:59.975+0800: 68172.762: [Full GC (Ergonomics) [PSYoungGen: 1012224K->23530K(1070080K)] [ParOldGen: 1115405K->1126390K(1126400K)] 2127629K->1149920K(2196480K), [Metaspace: 149991K->149927K(1200128K)], 2.1220851 secs] [Times: user=7.38 sys=0.05, real=2.12 secs]
2017-08-16T08:21:02.899+0800: 68175.686: [Full GC (Ergonomics) [PSYoungGen: 1012224K->59419K(1070080K)] [ParOldGen: 1126390K->1125954K(1126400K)] 2138614K->1185374K(2196480K), [Metaspace: 149927K->149922K(1200128K)], 2.5345709 secs] [Times: user=8.72 sys=0.03, real=2.54 secs]
2017-08-16T08:21:06.094+0800: 68178.881: [Full GC (Ergonomics) [PSYoungGen: 1012224K->93211K(1070080K)] [ParOldGen: 1125954K->1125937K(1126400K)] 2138178K->1219148K(2196480K), [Metaspace: 149922K->149922K(1200128K)], 1.7138433 secs] [Times: user=6.15 sys=0.00, real=1.71 secs]
2017-08-16T08:21:08.446+0800: 68181.233: [Full GC (Ergonomics) [PSYoungGen: 1012224K->125952K(1070080K)] [ParOldGen: 1125937K->1125909K(1126400K)] 2138161K->1251862K(2196480K), [Metaspace: 149922K->149922K(1200128K)], 2.3235504 secs] [Times: user=8.30 sys=0.00, real=2.32 secs]
2017-08-16T08:21:11.386+0800: 68184.173: [Full GC (Ergonomics) [PSYoungGen: 1012224K->157529K(1070080K)] [ParOldGen: 1125909K->1125923K(1126400K)] 2138133K->1283453K(2196480K), [Metaspace: 149922K->149921K(1200128K)], 2.8770989 secs] [Times: user=10.37 sys=0.00, real=2.87 secs]
2017-08-16T08:21:14.939+0800: 68187.726: [Full GC (Ergonomics) [PSYoungGen: 1012224K->187325K(1070080K)] [ParOldGen: 1125923K->1126346K(1126400K)] 2138147K->1313672K(2196480K), [Metaspace: 149921K->149921K(1200128K)], 2.6005103 secs] [Times: user=9.39 sys=0.00, real=2.60 secs]
2017-08-16T08:21:18.116+0800: 68190.903: [Full GC (Ergonomics) [PSYoungGen: 1012224K->217103K(1070080K)] [ParOldGen: 1126346K->1126344K(1126400K)] 2138570K->1343448K(2196480K), [Metaspace: 149921K->149921K(1200128K)], 2.4098660 secs] [Times: user=8.58 sys=0.00, real=2.41 secs]
2017-08-16T08:21:21.074+0800: 68193.861: [Full GC (Ergonomics) [PSYoungGen: 1012224K->244632K(1070080K)] [ParOldGen: 1126344K->1126342K(1126400K)] 2138568K->1370974K(2196480K), [Metaspace: 149921K->149921K(1200128K)], 2.3926853 secs] [Times: user=8.67 sys=0.00, real=2.39 secs]
2017-08-16T08:21:24.015+0800: 68196.803: [Full GC (Ergonomics) [PSYoungGen: 1012224K->271948K(1070080K)] [ParOldGen: 1126342K->1126144K(1126400K)] 2138566K->1398092K(2196480K), [Metaspace: 149921K->149905K(1200128K)], 2.6729877 secs] [Times: user=9.52 sys=0.00, real=2.67 secs]
2017-08-16T08:21:27.304+0800: 68200.091: [Full GC (Ergonomics) [PSYoungGen: 1012224K->296511K(1070080K)] [ParOldGen: 1126144K->1126335K(1126400K)] 2138368K->1422846K(2196480K), [Metaspace: 149905K->149905K(1200128K)], 3.4714176 secs] [Times: user=12.47 sys=0.00, real=3.47 secs]
2017-08-16T08:21:31.255+0800: 68204.042: [Full GC (Ergonomics) [PSYoungGen: 1012224K->321001K(1070080K)] [ParOldGen: 1126335K->1126335K(1126400K)] 2138559K->1447337K(2196480K), [Metaspace: 149905K->149905K(1200128K)], 2.3689971 secs] [Times: user=8.54 sys=0.00, real=2.37 secs]
2017-08-16T08:21:34.127+0800: 68206.915: [Full GC (Ergonomics) [PSYoungGen: 1012224K->346486K(1070080K)] [ParOldGen: 1126335K->1126335K(1126400K)] 2138559K->1472821K(2196480K), [Metaspace: 149905K->149905K(1200128K)], 1.4811130 secs] [Times: user=5.35 sys=0.00, real=1.48 secs]
2017-08-16T08:21:36.104+0800: 68208.891: [Full GC (Ergonomics) [PSYoungGen: 1012224K->368640K(1070080K)] [ParOldGen: 1126335K->1126294K(1126400K)] 2138559K->1494934K(2196480K), [Metaspace: 149905K->149903K(1200128K)], 2.6448415 secs] [Times: user=9.32 sys=0.00, real=2.64 secs]
2017-08-16T08:21:39.207+0800: 68211.994: [Full GC (Ergonomics) [PSYoungGen: 1012224K->392472K(1070080K)] [ParOldGen: 1126294K->1126217K(1126400K)] 2138518K->1518689K(2196480K), [Metaspace: 149903K->149877K(1200128K)], 2.5999380 secs] [Times: user=9.10 sys=0.00, real=2.60 secs]
2017-08-16T08:21:42.232+0800: 68215.019: [Full GC (Ergonomics) [PSYoungGen: 1012224K->413216K(1070080K)] [ParOldGen: 1126217K->1126216K(1126400K)] 2138441K->1539433K(2196480K), [Metaspace: 149877K->149877K(1200128K)], 2.2401472 secs] [Times: user=7.97 sys=0.00, real=2.24 secs]
2017-08-16T08:21:44.902+0800: 68217.689: [Full GC (Ergonomics) [PSYoungGen: 1012224K->434974K(1070080K)] [ParOldGen: 1126216K->1126216K(1126400K)] 2138440K->1561190K(2196480K), [Metaspace: 149877K->149877K(1200128K)], 1.6083593 secs] [Times: user=5.76 sys=0.00, real=1.61 secs]
2017-08-16T08:21:46.945+0800: 68219.732: [Full GC (Ergonomics) [PSYoungGen: 1012224K->454029K(1070080K)] [ParOldGen: 1126216K->1126137K(1126400K)] 2138440K->1580167K(2196480K), [Metaspace: 149877K->149877K(1200128K)], 2.3399985 secs] [Times: user=8.36 sys=0.00, real=2.34 secs]
2017-08-16T08:21:49.688+0800: 68222.475: [Full GC (Ergonomics) [PSYoungGen: 1012224K->474437K(1070080K)] [ParOldGen: 1126137K->1126137K(1126400K)] 2138361K->1600574K(2196480K), [Metaspace: 149877K->149877K(1200128K)], 2.2670294 secs] [Times: user=7.97 sys=0.00, real=2.27 secs]
```
2017-08-16T08:20:56.919+0800: 68169.706: [Full GC (Ergonomics) [PSYoungGen: 36643K->0K(1070080K)] [ParOldGen: 1083936K->1115405K(1126400K)] 1120579K->1115405K(2196480K), [Metaspace: 150009K->149972K(1200128K)], 2.2663258 secs] [Times: user=7.93 sys=0.00, real=2.27 secs]

同样的年老代空间不足导致FullGC频繁。

## 跟踪计数器的三种算法

* 复制
    从根集合搜扫描出存活的对象，然后将存活的对象复制到一块新的未使用的空间中，当要回收的空间中存活的对象较少时，比较高效；

* 标记清除
    从根集合开始扫描，对存活的对象进行标记，比较完毕后，再扫描整个空间中未标记的对象，然后进行回收，不需要对对象进行移动；

* 标记压缩
    标记形式和“标记清除”一样，但是回收不存活的对象后，会把所有存活的对象在内存空间中进行移动，好处是减少了内存碎片，缺点是成本比较高；

## 新生代可以使用的GC
新生代中对象存活的时间比较短，因此通过复制算法实现，Eden区域存放新创建的对象，S0和S1区其中一块用于存放在Minor GC的时候作为复制存活对象的目标空间，另外一块清空。

串行GC（Serial GC）比较适合单CPU的情况，可以通过-XX:UseSerialGC来强行制定；

并行回收GC（Parallel Scavenge），启动的时候按照设置的参数来划定Eden/S0/S1区域的大小，但是在运行时，会根据Minor GC的频率、消耗时间来动态调整三个区域的大小，可以用过-XX:UseAdaptiveSizePolicy来固定大小，不进行动态调整；

并行GC（ParNew）划分Eden、S1、S0的区域上和串行GC一样。并行GC需要配合旧生代使用CMS GC（这是他和并行回收GC的不同）（如果配置了CMS GC的方式，那么新生代默认采取的就是并行GC的方式）；

## 何时会触发Minor GC？

当Eden区域分配内存时，发现空间不足，JVM就会触发Minor GC，程序中System.gc()也可以来触发。

## 老生代可以使用的GC

串行GC（Serial MSC）、并行GC（Parallel MSC）、并发GC（CMS）;

采用CMS时候，新生代必须使用Serial GC或者ParNew GC两种。CMS共有七个步骤，只有Initial Marking和Final Marking两个阶段是stop-the-world的，其他步骤均和应用并行进行。持久代的GC也采用CMS，通过-XX：CMSPermGenSweepingEnabled -XX：CMSClassUnloadingEnabled来制定。在采用cms gc的情况下，ygc变慢的原因通常是由于old gen出现了大量的碎片。

### 为啥CMS会有内存碎片，如何避免？

由于在CMS的回收步骤中，没有对内存进行压缩，所以会有内存碎片出现，CMS提供了一个整理碎片的功能，通过-XX：UseCompactAtFullCollection来启动此功能，启动这个功能后，默认每次执行Full GC的时候会进行整理（也可以通过-XX：CMSFullGCsBeforeCompaction=n来制定多少次Full GC之后来执行整理），整理碎片会stop-the-world.

### 啥时候会触发CMS GC？

1、旧生代或者持久代已经使用的空间达到设定的百分比时（CMSInitiatingOccupancyFraction这个设置old区，perm区也可以设置）；

2、JVM自动触发(JVM的动态策略，也就是悲观策略)（基于之前GC的频率以及旧生代的增长趋势来评估决定什么时候开始执行），如果不希望JVM自行决定，可以通过-XX:UseCMSInitiatingOccupancyOnly=true来制定；

3、设置-XX:CMSClassUnloading为Enabled时 这个则考虑Perm区；
 

## 啥时候会触发Full GC？

### 旧生代空间不足
java.lang.outOfMemoryError：java heap space；

### Perm空间满
java.lang.outOfMemoryError：PermGen space；

### CMS GC时出现promotion failed  和concurrent  mode failure

promotion failed是在进行Minor GC时，survivor space放不下、对象只能放入老年代，而此时老年代也放不下造成的；
concurrent mode failure是在执行CMS GC的过程中同时有对象要放入老年代，而此时老年代空间不足造成的（有时候“空间不足”是CMS GC时当前的浮动垃圾过多导致暂时性的空间不足触发Full GC）。
应对措施为：增大survivor space、老年代空间或调低触发并发GC的比率，但在JDK 5.0+、6.0+的版本中有可能会由于JDK的bug29导致CMS在remark完毕后很久才触发sweeping动作。对于这种状况，可通过设置-XX: CMSMaxAbortablePrecleanTime=5（单位为ms）来避免。

### 统计得到的minor GC晋升到旧生代的平均大小大于旧生代的剩余空间

### 主动触发Full GC（执行jmap -histo:live [pid]）来避免碎片问题

### 堆中分配很大的对象
 
所谓大对象，是指需要大量连续内存空间的java对象，例如很长的数组，此种对象会直接进入老年代，而老年代虽然有很大的剩余空间，但是无法找到足够大的连续空间来分配给当前对象，此种情况就会触发JVM进行Full GC。
为了解决这个问题，CMS垃圾收集器提供了一个可配置的参数，即-XX:+UseCMSCompactAtFullCollection开关参数，用于在“享受”完Full GC服务之后额外免费赠送一个碎片整理的过程，内存整理的过程无法并发的，空间碎片问题没有了，但提顿时间不得不变长了，JVM设计者们还提供了另外一个参数 -XX:CMSFullGCsBeforeCompaction,这个参数用于设置在执行多少次不压缩的Full GC后,跟着来一次带压缩的。


[为什么heap size<=3G的情况下完全不要考虑CMS GC](http://hellojava.info/?p=142)