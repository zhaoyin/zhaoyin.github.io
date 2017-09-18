
---
title: JVM参数调优
date: 2017-06-25 09:20:46
categories:
    - tuning
tags: 
    - JVM
    - 性能优化
---

由于Java字节码是运行在JVM虚拟机上的，同样的字节码使用不同的JVM虚拟机参数运行，其性能表现可能各不相同。为了能使系统性能最优，就需要对JVM参数进行调整以达到应用程序运行的最佳效果。
![JVM结构](http://oqcey66z7.bkt.clouddn.com/public/resource/5e937446bd287857-af65270862aa1d4b-4217e4e9a77a4ed6808c89a303261dc9.jpg)

## 写在前面
GC调优就像分布式系统的C[Consistency(一致性)]A[ Availability(可用性)]P[Partition tolerance(分区容错性) 可靠性]一样,也有自己的原则。
就是吞吐量，响应时间，内存占用来3选2。基本的设计原理就是内存占用为有限值的条件下，我们再在响应时间和吞吐量上挑一个优化。
比如Hotspot JVM实现中，CMS算法主攻响应时间，Parallel GC 主攻吞吐量，G1 GC较关注响应时间同时兼顾一点吞吐量；
但是如果内存占用小于2G，不建议使用CMS，此时使用CMS调优效果不明显。内存占用小于6G不建议使用G1[Recommended Use Cases for G1](http://www.oracle.com/webfolder/technetwork/tutorials/obe/java/G1GettingStarted/index.html)

<!--more-->

大神的传送门：
>[Major GC和Full GC的区别是什么？触发条件呢？ - RednaxelaFX的回答 - 知乎](https://www.zhihu.com/question/41922036/answer/93079526)
> [Java的GC为什么要分代？ - RednaxelaFX 的回答 - 知乎](https://www.zhihu.com/question/53613423/answer/135743258)
> [G1 GC的讨论 - 高级语言虚拟机 - ITeye群组](http://hllvm.group.iteye.com/group/topic/44381#post-272188)

> [JVM调优的"标准参数"的各种陷阱](http://hllvm.group.iteye.com/group/topic/27945)


## 实践
因为下面的内容太枯燥了，所以将实践放到这。这里面用到的，下面都有讲到,也可以看完下面的再回过来看这一节。

首先使用``jps -mlvV``可以看当前环境有哪些JVM的应用。
```markdown
[xa@test.logic.mac ~]# jps -mlvV
9604 play.server.Server -javaagent:/usr/local/play/framework/play-1.4.4.jar -Dprecompiled=true -Xms4500M -Xmx4500M -Xss512K -Xmn1200M -XX:MetaspaceSize=1200M -XX:MaxMetaspaceSize=1200M -Xloggc:/tmp/gc.log -Xverify:none -Dfile.encoding=utf-8 -Dapplication.path=/opt/uorder/uorderapp -Dplay.id=
6484 com.aliyun.tianji.cloudmonitor.Application -Djava.compiler=none -XX:-UseGCOverheadLimit -XX:NewRatio=1 -XX:SurvivorRatio=8 -XX:+UseSerialGC -Djava.io.tmpdir=../../tmp -Xms16m -Xmx32m -Djava.library.path=../lib:../../lib -Dwrapper.key=CzZLO6-QvtTQVzs- -Dwrapper.port=32000 -Dwrapper.jvm.port.min=31000 -Dwrapper.jvm.port.max=31999 -Dwrapper.disable_console_input=TRUE -Dwrapper.pid=6482 -Dwrapper.version=3.5.27 -Dwrapper.native_library=wrapper -Dwrapper.arch=x86 -Dwrapper.service=TRUE -Dwrapper.cpu.timeout=10 -Dwrapper.jvmid=1
2310 sun.tools.jps.Jps -mlvV -Denv.class.path=.:/usr/java/latest/lib/dt.jar:/usr/java/latest/lib/tools.jar:/usr/java/latest/jre/lib -Dapplication.home=/usr/java/jdk1.8.0_45 -Xms8m
```

可以找到我们要分析的[play](https://github.com/playframework/play1)应用的pid是9604


使用``jinfo -flags 9604``可以看到该应用的jvm参数设置
```markdown
[xa@test.logic.mac ~]# jinfo -flags 9604
Attaching to process ID 9604, please wait...
Debugger attached successfully.
Server compiler detected.
JVM version is 25.45-b02
Non-default VM flags: -XX:-BytecodeVerificationLocal -XX:-BytecodeVerificationRemote -XX:CICompilerCount=3 -XX:InitialHeapSize=4718592000 -XX:MaxHeapSize=4718592000 -XX:MaxMetaspaceSize=1258291200 -XX:MaxNewSize=1258291200 -XX:MetaspaceSize=1258291200 -XX:MinHeapDeltaBytes=524288 -XX:NewSize=1258291200 -XX:OldSize=3460300800 -XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:ThreadStackSize=512 -XX:+UseCompressedClassPointers -XX:+UseCompressedOops -XX:+UseParallelGC 
Command line:  -javaagent:/usr/local/play/framework/play-1.4.4.jar -Dprecompiled=true -Xms4500M -Xmx4500M -Xss512K -Xmn1200M -XX:MetaspaceSize=1200M -XX:MaxMetaspaceSize=1200M -Xloggc:/tmp/gc.log -Xverify:none -Dfile.encoding=utf-8 -Dapplication.path=/opt/uorder/uorderapp -Dplay.id=
```
我们可以看到我们开启了``-XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCTimeStamps``，同时记录gc日志到``-Xloggc:/tmp/gc.log``。同时还有一些jvm的参数，比如``-Xms4500M -Xmx4500M -Xss512K -Xmn1200M -XX:MetaspaceSize=1200M -XX:MaxMetaspaceSize=1200M``

使用``jstat -gcutil 9604 500 10``可以看到当前时间gc的执行效果
```markdown
[xa@test.logic.mac ~]# jstat -gcutil 9604 500 10
  S0     S1     E      O      M     CCS    YGC     YGCT    FGC    FGCT     GCT   
  0.00  67.56  67.13  25.70  78.21  44.87   4495   80.965     3    3.243   84.208
  0.00  67.56  68.03  25.70  78.21  44.87   4495   80.965     3    3.243   84.208
  0.00  67.56  69.03  25.70  78.21  44.87   4495   80.965     3    3.243   84.208
  0.00  67.56  69.38  25.70  78.21  44.87   4495   80.965     3    3.243   84.208
  0.00  67.56  70.01  25.70  78.21  44.87   4495   80.965     3    3.243   84.208
  0.00  67.56  70.69  25.70  78.21  44.87   4495   80.965     3    3.243   84.208
  0.00  67.56  71.74  25.70  78.21  44.87   4495   80.965     3    3.243   84.208
  0.00  67.56  72.42  25.70  78.21  44.87   4495   80.965     3    3.243   84.208
  0.00  67.56  73.98  25.70  78.21  44.87   4495   80.965     3    3.243   84.208
  0.00  67.56  74.62  25.70  78.21  44.87   4495   80.965     3    3.243   84.208
```
可以知道程序从启动到现在执行了3次Full GC(FGC)，共耗时3.243秒(FGCT)，共执行了4495次Minor GC(YGC)，共耗时80.965秒(YGCT)。GC一共耗时84.208秒(GCT)。
平均一次Full GC耗时3.243/3=1.081秒.一次Minor GC耗时80.965/4495=0.018秒。

通过gc日志``vi /tmp/gc.log``可以看到
```markdown
248087.335: [GC (Allocation Failure) [PSYoungGen: 1218560K->6830K(1220096K)] 2246569K->1039465K(4599296K), 0.0297877 secs] [Times: user=0.12 sys=0.00, real=0.03 secs]
248129.695: [GC (Allocation Failure) [PSYoungGen: 1219246K->2688K(1220608K)] 2251881K->1041512K(4599808K), 0.0220941 secs] [Times: user=0.08 sys=0.01, real=0.02 secs]
248176.495: [GC (Allocation Failure) [PSYoungGen: 1215104K->2419K(1220608K)] 2253928K->1043301K(4599808K), 0.0162103 secs] [Times: user=0.06 sys=0.00, real=0.02 secs]
248226.655: [GC (Allocation Failure) [PSYoungGen: 1214835K->4506K(1220608K)] 2255717K->1047389K(4599808K), 0.0230516 secs] [Times: user=0.07 sys=0.00, real=0.02 secs]
248269.580: [GC (Allocation Failure) [PSYoungGen: 1216922K->4895K(1221120K)] 2259805K->1051934K(4600320K), 0.0241935 secs] [Times: user=0.08 sys=0.00, real=0.02 secs]
```
Full GC
```markdown
153372.563: [Full GC (Ergonomics) [PSYoungGen: 4185K->0K(1221120K)] [ParOldGen: 3373394K->315660K(3379200K)] 3377580K->315660K(4600320K), [Metaspace: 148545K->148504K(1193984K)], 0.9031309 secs] [Times: user=2.45 sys=0.00, real=0.90 secs]
236965.810: [Full GC (Ergonomics) [PSYoungGen: 3782K->0K(1220096K)] [ParOldGen: 3372641K->313617K(3379200K)] 3376423K->313617K(4599296K), [Metaspace: 178716K->178648K(1224704K)], 1.5024821 secs] [Times: user=4.66 sys=0.00, real=1.50 secs]
```
可以看到Minor GC频率 248176.495-248129.695=46.8秒，平均下来在40秒，延迟时间大概为0.02s(20ms).Full GC频率 236965.810-153372.563=83593.247=23小时。
年老代(ParOldGen)稳定在313617K(大约306M),永久代(MetaSpace/PSPermGen)稳定在178648K(大约174.5M)，还可以看出PSYoungGen占用1220096K(1191.5M)，ParOldGen占用3379200K(3300M)，堆占用4599296K(4491.5M)，MetaSpace/PermSize占用1224704K(1196M)
可以看出和我们设定值是一致的：``-Xms4500M -Xmx4500M -Xss512K -Xmn1200M -XX:MetaspaceSize=1200M -XX:MaxMetaspaceSize=1200M``。

按照经验值
```markdown
**Java堆大小的初始化值和最大值（通过-Xms和-Xmx选项来指定）应该是old代活动对象的大小的3到4倍。**
**permanent的初始值和最大值（-XX:PermSize和-XX:MaxPermSize）应该permanent代活动对象大小的1.2到1.5倍。**
**young代空间应该是old代活动对象大小的1到1.5倍。**
```
可以得到根据经验值的设定``-Xms1200M -Xmx1200M -Xss512K -Xmn430M -XX:MetaspaceSize=225M -XX:MaxMetaspaceSize=225M``

young代的空间大小为1200M，大概40s一次的频率。就意味着每40s就填充满1200M的young代空间
old代的空间大小为3300M(4500-1200),其中活动对象需要占用306M，old代还有大概3000M的剩余空间。填满3000M的空间需要23小时，大概每2分钟会填充4.2M。40s一次Minor GC，2分钟会进行5次。每次Minor GC会有0.8M进入old代空间.
old代的空间占用是MinorGC之后Java堆中对象大小减去young代的大小,第一次Minor GC后old代空间大小为1032635K，第二次：1038824K，第三次：1040882K，第四次：1042883K，第五次：1047039K。可以看出每次增量大概为2000K(1.95M)。每40s进行一个Minor GC，则每40s时间old代会有1.95M的增量，算下来20小时会有3500M的增量。
由于这只是截取中间一个片段做的统计，不能很准确的描述值。但是我们看到整个趋势是对的，3500M和3000M在大趋势上还是对得上的。

由于old代的延迟太长了，执行时间也在1s，我们调整jvm参数设置，增加young代空间大小，减小old代空间大小。

执行如下设定``-Xms4500M -Xmx4500M -Xss512K -Xmn2400M -XX:MetaspaceSize=1200M -XX:MaxMetaspaceSize=1200M``
```markdown
[root@iZbp1j14l08tzyjrzcqv7eZ ~]# jstat -gcutil 11355 500 10
  S0     S1     E      O      M     CCS    YGC     YGCT    FGC    FGCT     GCT   
  0.00  76.06  69.81  55.01  83.81  52.20   1049   20.752     2    1.387   22.140
  0.00  76.06  71.17  55.01  83.81  52.20   1049   20.752     2    1.387   22.140
  0.00  76.06  72.42  55.01  83.81  52.20   1049   20.752     2    1.387   22.140
  0.00  76.06  72.76  55.01  83.81  52.20   1049   20.752     2    1.387   22.140
  0.00  76.06  73.07  55.01  83.81  52.20   1049   20.752     2    1.387   22.140
  0.00  76.06  73.40  55.01  83.81  52.20   1049   20.752     2    1.387   22.140
  0.00  76.06  73.96  55.01  83.81  52.20   1049   20.752     2    1.387   22.140
  0.00  76.06  74.84  55.01  83.81  52.20   1049   20.752     2    1.387   22.140
  0.00  76.06  76.09  55.01  83.81  52.20   1049   20.752     2    1.387   22.140
  0.00  76.06  76.39  55.01  83.81  52.20   1049   20.752     2    1.387   22.140
```

```markdown
26299.005: [GC (Allocation Failure) [PSYoungGen: 2241419K->8181K(2244608K)] 4467648K->2242573K(4497408K), 0.0300744 secs] [Times: user=0.11 sys=0.00, real=0.03 secs]
26392.190: [GC (Allocation Failure) [PSYoungGen: 2244597K->4370K(2237440K)] 4478989K->2246834K(4490240K), 0.0230028 secs] [Times: user=0.08 sys=0.00, real=0.02 secs]
26478.535: [GC (Allocation Failure) [PSYoungGen: 2233618K->6539K(2241024K)] 4476082K->2252888K(4493824K), 0.0211527 secs] [Times: user=0.08 sys=0.00, real=0.02 secs]
26478.557: [Full GC (Ergonomics) [PSYoungGen: 6539K->0K(2241024K)] [ParOldGen: 2246348K->204298K(2252800K)] 2252888K->204298K(4493824K), [Metaspace: 103567K->103351K(1146880K)], 0.6931326 secs] [Times: user=2.06 sys=0.00, real=0.69 secs]
26559.819: [GC (Allocation Failure) [PSYoungGen: 2229248K->5546K(2242048K)] 2433546K->209844K(4494848K), 0.0137723 secs] [Times: user=0.05 sys=0.00, real=0.01 secs]
26635.664: [GC (Allocation Failure) [PSYoungGen: 2236330K->7348K(2241536K)] 2440628K->216605K(4494336K), 0.0146880 secs] [Times: user=0.05 sys=0.00, real=0.01 secs]

84567.977: [GC (Allocation Failure) [PSYoungGen: 2237974K->7231K(2241024K)] 4468728K->2246401K(4493824K), 0.0291482 secs] [Times: user=0.11 sys=0.00, real=0.03 secs]
84657.219: [GC (Allocation Failure) [PSYoungGen: 2236479K->4715K(2241536K)] 4475649K->2250442K(4494336K), 0.0251333 secs] [Times: user=0.09 sys=0.00, real=0.03 secs]
84657.244: [Full GC (Ergonomics) [PSYoungGen: 4715K->0K(2241536K)] [ParOldGen: 2245726K->268004K(2252800K)] 2250442K->268004K(4494336K), [Metaspace: 122575K->122537K(1167360K)], 0.6942766 secs] [Times: user=2.08 sys=0.00, real=0.69 secs]
84741.778: [GC (Allocation Failure) [PSYoungGen: 2230272K->6880K(2241536K)] 2498276K->274884K(4494336K), 0.0164910 secs] [Times: user=0.05 sys=0.00, real=0.02 secs]
84825.466: [GC (Allocation Failure) [PSYoungGen: 2237152K->5714K(2242048K)] 2505156K->279920K(4494848K), 0.0201746 secs] [Times: user=0.06 sys=0.00, real=0.02 secs]
84893.970: [GC (Allocation Failure) [PSYoungGen: 2236498K->10165K(2241024K)] 2510704K->289567K(4493824K), 0.0206604 secs] [Times: user=0.08 sys=0.00, real=0.02 secs]

```
调整后，由于young代空间增大了，young代执行频率降低了。old代空间减小了，old代执行频率提高了，执行时间降低了。

## 常用命令
* jps 虚拟机进程状况工具(Java Virtual Machine Process Status Tool)
```markdown
-q 不输出类名、Jar名和传入main方法的参数
-m 输出传入main方法的参数
-l 输出main类或Jar的全限名
-v 输出传入JVM的参数
```
* jstack 查看某个Java进程内的线程堆栈信息
```markdown
-F  to force a thread dump. Use when jstack <pid> does not respond (process is hung)
-m  不仅会输出Java堆栈信息，还会输出C/C++堆栈信息（比如Native方法）
-l  会打印出额外的锁信息，在发生死锁时可以用jstack -l pid来观察锁持有情况
-h or -help to print this help message
```
* jmap 查看堆内存使用状况
```markdown
打印进程的类加载器和类加载器加载的持久代对象信息，输出：类加载器名称、对象是否存活（不可靠）、对象地址、父类加载器、已加载的类大小等信息

使用jmap -heap pid查看进程堆内存使用情况，包括使用的GC算法、堆配置参数和各代中堆内存使用情况

jmap -heap 7481
jmap -histo:live 1432 | more;//查看堆内存中的对象数目、大小统计直方图，如果带上live则只统计活对象
jmap -permstat 7481;//如果操作系统是64位
使用jmap生成dump文件
jmap -dump:format=b,file=/tmp/dump.dat 14949;//14949进程号
```
* jstat
```markdown
jstat -gcutil pid 500 20;//每500毫秒查询进程pid垃圾收集情况 一共查询20次
jstat -gcold pid;//查看老年代gc存储量
jstat -gcnew pid;//查看年轻代gc存储量

-gcutil:监视堆内存情况，包括eden区，s1，s2,老年代和永久代的内存容量
-gcnew:监视新生代GC情况
-gcold:监视老年代GC情况

S0C、S1C、S0U、S1U：Survivor 0/1区容量（Capacity）和使用量（Used）
EC、EU：Eden区容量和使用量
OC、OU：年老代容量和使用量
PC、PU：永久代容量和使用量
YGC、YGT：年轻代GC次数和GC耗时
FGC、FGCT：Full GC次数和Full GC耗时
GCT：GC总耗时
```
* jinfo
用于查询当前运行这的JVM属性和参数的值。
```markdown
   -flag:显示未被显示指定的参数的系统默认值
   -flag [+|-]name或-flag name=value: 修改部分参数
   -sysprops:打印虚拟机进程的System.getProperties()
 命令格式:jinfo [option] pid 
```
**java -XX:+PrintFlagsFinal -version|grep manageable**命令可查看支持通过jinfo动态设置的参数
```
jinfo -flags pid;  //打印进程pid的jvm参数设置
用它来动态设置参数
jinfo -flag -PrintGC 8359
jinfo -flag -PrintGCDDetails 8359
上面的命令代表关闭Java应用进程为8359的的PrintGC参数和PrintGCDetails参数。

jinfo -flag +PrintGC 8359
jinfo -flag +PrintGCDDetails 8359

```

* 日志记录
```angular2html
-verbose:gc 
-XX:+PrintGCDetails 
-XX:+PrintGCDateStamps
-Xloggc:/path/gc.log
-XX:+UseGCLogFileRotation  启用GC日志文件的自动转储 (Since Java)
-XX:NumberOfGClogFiles=1  GC日志文件的循环数目 (Since Java)
-XX:GCLogFileSize=1M  控制GC日志文件的大小 (Since Java)
-XX:+PrintGC包含-verbose:gc
-XX:+PrintGCDetails //包含-XX:+PrintGC
只要设置-XX:+PrintGCDetails 就会自动带上-verbose:gc和-XX:+PrintGC
-XX:+PrintGCDateStamps/-XX:+PrintGCTimeStamps 输出gc的触发时间
```


* GCViewer
工欲善其事，必先利其器。
[GCViewer](https://github.com/chewiebug/GCViewer)
GCViewer is a little tool that visualizes verbose GC output generated by Sun / Oracle, IBM, HP and BEA Java Virtual Machines. It is free software released under GNU LGPL.

You can start GCViewer (gui) by simply double-clicking on gcviewer-1.3x.jar or running java -jar gcviewer-1.3x.jar (it needs a java 1.8 vm to run).

For a cmdline based report summary just type the following to generate a report (including optional chart image file): java -jar gcviewer-1.3x.jar gc.log summary.csv [chart.png] [-t PLAIN|CSV|CSV_TS|SIMPLE|SUMMARY] When logfile rotation (-XX:+UseGCLogFileRotation) is enabled, the logfiles can be read at once: java -jar gcviewer-1.3x.jar gc.log.0;gc.log.1;gc.log.2;gc.log.current summary.csv [chart.png] [-t PLAIN|CSV|CSV_TS|SIMPLE|SUMMARY]

Supported verbose:gc formats are:

preliminary support for OpenJDK 9 Shenandoah algorithm in unified logging format -Xlog:gc: -XX:+UseShenandoahGC
* Oracle JDK 1.8 -Xloggc: [-XX:+PrintGCDetails] [-XX:+PrintGCDateStamps]
* Sun / Oracle JDK 1.7 with option -Xloggc: [-XX:+PrintGCDetails] [-XX:+PrintGCDateStamps]
* Sun / Oracle JDK 1.6 with option -Xloggc: [-XX:+PrintGCDetails] [-XX:+PrintGCDateStamps]
* Sun JDK 1.4/1.5 with the option -Xloggc: [-XX:+PrintGCDetails]
* Sun JDK 1.2.2/1.3.1/1.4 with the option -verbose:gc
* IBM JDK 1.3.1/1.3.0/1.2.2 with the option -verbose:gc
* IBM iSeries Classic JVM 1.4.2 with option -verbose:gc
* HP-UX JDK 1.2/1.3/1.4.x with the option -Xverbosegc
* BEA JRockit 1.4.2/1.5/1.6 with the option -verbose:memory [-Xverbose:gcpause,gcreport] [-Xverbosetimestamp]

* 两个在线GC分析工具
http://gceasy.io
http://fastthread.io

## 评估堆大小和内存占用
### JVM内存模型
![JVM内存模型](http://oqcey66z7.bkt.clouddn.com/public/resource/jvm-gc-memory.jpg)

HotSpot VM有3个主要的空间：young代、old代以及permanent代
当Java应用分配Java对象时，这些对象被分配到young代。在经历过几次minor GC之后，如果对象还是存活的，就会被转移到old代空间。permanent代空间存储了VM和Java类的元数据比如内置的字符串和类的静态变量。

### 常用内存参数
参数说明:
![JVM主要参数](http://oqcey66z7.bkt.clouddn.com/public/resource/3948988f79c560be-d390ef13d3ebc1ed-98f2ce20f8dd5f395a695bf41bb92fc7.jpg)
Java应用程序运行时，首先会分配-Xms指定的内存大小，并尽可能尝试在这个空间段运行。最大不会超过-Xmx指定的内存大小，它是Java应用程序的堆上限，超过就会内存溢出（OutofMemoryError）。
如果-Xms的数值太小，JVM为了保证系统尽可能的运行在指定内存范围内，就会更加频繁的GC以便释放内存空间。频繁的MinorGC和FullGC次数，对系统会有性能损耗。
所以一般情况下会保持-Xms -Xmx一致，以减少系统运行初期的GC次数和耗时。
Java虚拟机中还有一种常见的异常：栈溢出（StackOverflowError），如果线程在计算过程中，请求的栈深度大于可用的最大栈深度，则会出现StackOverflowError。-Xss是用来设置栈大小的。比如-Xss1M代表每个线程拥有1MB的栈空间，当增大此参数，比如-Xss20M时每个线程可用的栈空间为20M，由于系统的内存是有限度的，势必会造成应用程序可创建的线程数的减少，而且系统所能支持的线程数量，还与堆的大小有关。

#### JVM堆大小
```markdown
-Xmx<n>[g|m|k]  
-Xms<n>[g|m|k]  
```
-Xmx和-Xms这个两个命令行选项分别指定yound代加上old代空间的总和的初始最大值和最小值，也就是Java堆的大小。当-Xms的值小于-Xmx的值的时候，Java堆的大小可以在最大值和最小值之前浮动。当Java应用强调吞吐量和延迟的时候，倾向于把-Xms和-Xmx设置成相同的值，由于调整young代或者old代的大小都需要进行Full GC，Full GC降低吞吐量以及加强延迟。
#### 年轻代
```markdown
-XX:NewSize=<n>[g|m|k]  
-XX:MaxNewSize=<n>[g|m|k]  
```
这两个参数可以指定young代的初始值和最大值，但是我们一般会用下面这个参数来直接固定young代的大小
```
-Xmn<n>[g|m|k]  
```
这个参数可以直接指定young代的初始值、最小值以及最大值。也就是说，young区的大小被固定成这个值了。这个值用来锁定young代的大小很方便。
有一点需要注意的是，如果-Xms和-Xmx没有被设定成相同的值，而且-Xmn被使用了，当调整Java堆的大小的时候，不会调整young代的空间大小，young代的空间大小会保持恒定。因此，**-Xmn应该在-Xms和-Xmx设定成相同的时候才指定**。
#### 年老代
old代的空间大小可以基于young代的大小进行计算，old代的初始值的大小是-Xms的值减去-XX:NewSize，最大值是-Xmx减去-XX:MaxNewSize，如果-Xmx和-Xms设置成了相同的值，而且使用-Xmn选项或者-XX:NewSize和-XX:MaxNewSize设置成了相同的值，那么old代的大小就是-Xmx减去-Xmn。

#### 永久代
JDK1.8之前
```markdown
-XX:PermSize=<n>[g|m|k]  
-XX:MaxPermSize=<n>[g|m|k]  
```
表示永久代的初始值和最大值
JDK1.8
```markdown
-XX:MetaspaceSize=<n>[g|m|k] 
-XX:MaxMetaspaceSize=<n>[g|m|k] 
```
![JDK8新增参数](http://oqcey66z7.bkt.clouddn.com/public/resource/5e937446bd287857-af65270862aa1d4b-2d0b9dc6f2913667ad01fe76add46404.jpg)

对于64位的服务器端JVM，-XX：MetaspaceSize的默认大小是21M。这是初始的限制值(the initial high watermark)。一旦达到这个限制值，FullGC将会被触发进行类卸载(当这些类的类加载器不再存活时)，然后这个high watermark被重置。新的high watermark的值依赖于空余Metaspace的容量。如果没有足够的空间被释放，high watermark的值将会上升；如果释放了大量的空间，那么high watermark的值将会下降。如果初始的watermark设置的太低，这个过程将会进行多次。你可以通过垃圾收集日志来显示的查看这个垃圾收集的过程。所以，一般建议在命令行设置一个较大的值给XX:MetaspaceSize来避免初始时的垃圾收集。

每次垃圾收集之后，Metaspace VM会自动的调整high watermark，推迟下一次对Metaspace的垃圾收集。

Java应用应该指定这两个值成为同一个值，由于这个值的调整会导致Full GC。

如果上面提到的Java堆大小、young代、permanent代的大小都没有指定，那么JVM会根据应用的情况自行计算。

在young代、old代以及permanent代中任何一个空间里面无法分配对象的时候就会触发垃圾回收，理解这点，对后面的优化非常重要。
当young代没有足够空间分配Java对象的时候，触发minor GC。**minor GC相对于Full GC来说会更短暂。**
一个对象在经历过一定次数的Minor GC之后，如果还存活，那么会被转移到old代。
**当old代没有足够空间放置对象的时候，HotSpot VM触发full GC。**
**实际上在进行Minor GC的时候发现没有old代足够的空间来进行对象的转移，就会触发FullGC，相对于在MinorGC的过程中发现对象的移动失败了然后触发FullGC，这样的策略会有更小的花费。**
**当permanent代的空间不够用的时候的，也会触发FullGC。**

**如果FullGC是由于old代满了而触发的，old代和permanent代的空间都会被垃圾回收，即使permanent代的空间还没有满。**
**同理，如果FullGC是由于permanent代满了而触发的，old代和permanent代的空间都会被垃圾回收，即使old代的空间还没有满。**
**另外，young代同样会被垃圾回收，除非-XX:+ScavengeBeforeFullGC选项被指定了，-XX:+ScavengeBeforeFullGC关闭FullGC的时候young代的垃圾回收。**

Minor GC 是清理年轻代（包括 Eden 和 Survivor 区域）
Major GC 是清理永久代
Full GC 是清理整个堆空间—包括年轻代和永久代

### 评估
通过``jinfo -flags pid``可以看到一个应用的jvm参数设置，比如
```markdown
[root@iZ237vwr2hyZ ~]# jinfo -flags 14909
Attaching to process ID 14909, please wait...
Debugger attached successfully.
Server compiler detected.
JVM version is 25.45-b02
Non-default VM flags: -XX:-BytecodeVerificationLocal -XX:-BytecodeVerificationRemote -XX:CICompilerCount=3 -XX:InitialHeapSize=2621440000 -XX:MaxHeapSize=2621440000 -XX:MaxMetaspaceSize=1073741824 -XX:MaxNewSize=1258291200 -XX:MetaspaceSize=838860800 -XX:MinHeapDeltaBytes=524288 -XX:NewSize=1258291200 -XX:OldSize=1363148800 -XX:+PrintGC -XX:+PrintGCDateStamps -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:ThreadStackSize=512 -XX:+UseCompressedClassPointers -XX:+UseCompressedOops -XX:+UseParallelGC
```
打开PrintGCDetails,PrintGCTimeStamps,PrintGCDateStamps的开关以方便的分析日志。
使用-Xloggc:filename记录GC日志

```markdown
2017-06-24T22:40:38.858+0800: 114249.527: [GC (Allocation Failure) [PSYoungGen: 1226215K->558K(1227264K)] 2403568K->1177949K(2558464K), 0.0113946 secs] [Times: user=0.04 sys=0.00, real=0.02 secs]
2017-06-24T22:41:14.048+0800: 114284.717: [GC (Allocation Failure) [PSYoungGen: 1226286K->614K(1227264K)] 2403677K->1178049K(2558464K), 0.0111863 secs] [Times: user=0.03 sys=0.00, real=0.02 secs]
2017-06-24T22:41:49.947+0800: 114320.616: [GC (Allocation Failure) [PSYoungGen: 1226342K->640K(1227264K)] 2403777K->1178092K(2558464K), 0.0115262 secs] [Times: user=0.04 sys=0.00, real=0.02 secs]
```
我们通过确定每个GC日志记录中的值的参数来开始分析：
R(n) = T(n): [ <GC> HB->HE(HC), D]
n 清单中记录的索引，1是第一个，m是最后一个
R(n)  GC记录
T(n) 第n个GC发生的时间
HB  GC之前堆的数量
HE  GC之后使用的堆数量
HC 堆空间的总量
D  GC周期的持续时间
#### OutOfMemoryError
```markdown
[Full GC[PSYoungGen: 279700K->267300K(358400K)]  
[ParOldGen: 685165K->685165K(685170K)]  
964865K->964865K(1043570K)  
[PSPermGen: 32390K->32390K(65536K)],0.2499342 secs]  
[Times: user=0.08 sys=0.00, real=0.05 secs]  
java.lang.OutOfMemoryError: Java heap space  
```
年老代(ParOldGen)在执行回收后所占用的空间685165K(->685165K)和年老带分配的空间685170K((685170K))相差无几,所以系统堆内存溢出了。
这时增加-Xms -Xmx以保证-Xmx和-Xmn的差值能扩大，以扩大年老代(ParOldGen)的空间
```markdown
[Full GC[PSYoungGen: 0K->0K(141632K)]  
  [ParOldGen: 132538K->132538K(350208K)]  
  32538K->32538K(491840K)  
  [PSPermGen: 65536K->65536K(65536K)],  
  0.2430136 secs]  
  [Times: user=0.37 sys=0.00, real=0.24 secs]  
java.lang.OutOfMemoryError: PermGen space  
```
永久代(PSPermGen)在执行回收后所占用的空间65536K(->65536K)和永久代分配的空间65536K((65536K))一致,所以系统永久代内存溢出了。
```markdown
-XX:PermSize=<n>[g|m|k]  
-XX:MaxPermSize=<n>[g|m|k]  
```
表示永久代的初始值和最大值
JDK1.8
```markdown
-XX:MetaspaceSize=<n>[g|m|k] 
-XX:MaxMetaspaceSize=<n>[g|m|k] 
```
这时候增大永久代的空间即可。

Java堆能够使用的容量受限于硬件以及是否使用64位的JVM。在扩大了Java堆的大小之后，再检查垃圾回收日志，直到没有OutOfMemoryError为止

做完这些，能让系统在一定程度上稳定运行，就可以通过分析GC来调整优化JVM参数了。

#### 根据活动对象评估
应用处于稳定运行状态下，在Java堆里面长期存活的对象。换一句话说，就是应用在稳定运行的状态下，Full GC之后，Java堆的所占的空间。
活动对象的大小可以通过垃圾回收日志查看，它提供了一些优化信息：
* 应用处于稳定运行状态下，old代的Java堆空间占用数量。
* 应用处于稳定运行状态下，permanent代的Java堆空间占用数量。
```markdown
[Full GC (Ergonomics) [PSYoungGen: 9600K->0K(1215488K)] [ParOldGen: 917745K->158112K(921600K)] 927345K->158112K(2137088K), [Metaspace: 78193K->78015K(1122304K)], 0.4451209 secs] [Times: user=1.25 sys=0.08, real=0.45 secs]
[Full GC (Ergonomics) [PSYoungGen: 9152K->0K(1217536K)] [ParOldGen: 917321K->168419K(921600K)] 926473K->168419K(2139136K), [Metaspace: 88598K->88574K(1132544K)], 0.4217154 secs] [Times: user=1.33 sys=0.00, real=0.42 secs]
```
方括号里面：该区域已使用的容量->GC后该内存区域已使用的容量(该内存区总容量)
方括号外面：GC前Java堆已使用的容量->GC后Java堆已使用的容量(Java堆总容量)
如果应用没有发生FullGC或者发生FullGC的次数很少，在性能测试环境，可以通过Java监控工具来触发FullGC，比如使用VisualVM和JConsole，这些工具在最新的JDK的bin目录下可以找到，VisualVM集成了JConsole，VisualVM或者JConsole上面有一个触发GC的按钮。
也可以通过jmap命令来强制执行垃圾回收
```markdown
jmap -histo:live pid  
```
上述日志说明年老代(ParOldGen)稳定在168419K(大约165M),永久代(MetaSpace/PSPermGen)稳定在88574K(大约86M)，还可以看出PSYoungGen占用1215488K，ParOldGen占用921600K，堆占用2137088K，MetaSpace/PermSize占用1132544K

通过活动对象大小的信息，可以做出关于Java堆的大小有根据的决定，以及可以估计出最坏情况下会导致的延迟。

**以下是经验值**

**Java堆大小的初始化值和最大值（通过-Xms和-Xmx选项来指定）应该是old代活动对象的大小的3到4倍。**

**permanent的初始值和最大值（-XX:PermSize和-XX:MaxPermSize）应该permanent代活动对象大小的1.2到1.5倍。**

**young代空间应该是old代活动对象大小的1到1.5倍。**


结合这个经验和前面的Full GC可以得到如下的**经验值**
```markdown
-Xms660M -Xmx660M -Xmn130M -XX:MetaspaceSize=130M -XX:MaxMetaspaceSize=130M
```

## 参数调优
特别注意的是:
* old代的空间一定不能小于活动对象的大小的1.5倍。
* young代的空间至少要有Java堆大小的10%，太小的Java空间会导致过于频繁的MinorGC。
* 当提高Java堆大小的时候，不要超过JVM可以使用的物理内存大小。如果使用过多的物理内存，会导致使用交换区，这个会严重影响性能。
如果GC执行时间满足下面所有的条件，就意味着无需进行GC优化了。
* Minor GC执行的很快（小于50ms）
* Minor GC执行的并不频繁（大于10秒一次）
* Full GC执行的很快（小于1s）
* Full GC执行的并不频繁（大于10分钟一次）
```markdown
执行Minor GC的时候，JVM会检查老年代中最大连续可用空间是否大于了当前新生代所有对象的总大小。
如果大于，则直接执行Minor GC（这个时候执行是没有风险的）。如果小于了，JVM会检查是否开启了空间分配担保机制，如果没有开启则直接改为执行Full GC。
如果开启了，则JVM会检查老年代中最大连续可用空间是否大于了历次晋升到老年代中的平均大小，如果小于则执行改为执行Full GC。如果大于则会执行Minor GC，如果Minor GC执行失败则会执行Full GC
```
### FullGC的原因

* 程序执行了System.gc() //建议jvm执行fullgc，并不一定会执行
* 执行了jmap -histo:live pid命令 //这个会立即触发fullgc
* 如上所说,在执行Minor GC时发生了Full GC
* 使用了大对象 //大对象会直接进入老年代
* 在程序中长期持有了对象的引用 //对象年龄达到指定阈值也会进入老年代

### 优化young代大小
确定young代的大小是通过评估垃圾回收的统计信息以及观察MinorGC的消耗时间和频率。
尽管MinorGC消耗的时间和young代里面的存活的对象数量有直接关系，但是一般情况下，更小young代空间，更短的MinorGC时间。如果不考虑MinorGC的时间消耗，减少young代的大小会导致MinorGC变得更加频繁，由于更小的空间，用完空间会用更少的时间。同理，提高young代的大小会降低MinorGC的频率。
所以一般情况下，减小年轻代(young)空间大小，可以减小MinorGC的时间消耗，增大年轻代(young)空间大小，能降低MinorGC的频率.
对于响应时间优先的应用，减小年轻代空间大小，直到接近系统的最低响应时间限制（根据实际情况选择）。
对于吞吐量优先的应用，尽可能增大年轻代空间大小，可能到达Gbit的程度。因为对响应时间没有要求，垃圾收集可以并行进行，一般适合8CPU以上的应用。

### 优化old代大小
#### 响应时间优先
年老代使用并发收集器，所以其大小需要小心设置，一般要考虑并发会话率和会话持续时间等一些参数。如果堆设置小了，可以会造成内存碎片、高回收频率以及应用暂停而使用传统的标记清除方式；如果堆大了，则需要较长的收集时间。
最优化的方案，一般需要参考以下数据获得：
* 并发垃圾收集信息
* 持久代并发收集次数
* 传统GC信息
* 花在年轻代和年老代回收上的时间比例
* 减少年轻代和年老代花费的时间，一般会提高应用的效率
#### 吞吐量优先
一般吞吐量优先的应用都有一个很大的年轻代和一个较小的年老代。原因是，这样可以尽可能回收掉大部分短期对象，减少中期的对象，而年老代尽存放长期存活对象。
较小堆引起的碎片问题
因为年老代的并发收集器使用标记、清除算法，所以不会对堆进行压缩。当收集器回收时，他会把相邻的空间进行合并，这样可以分配给较大的对象。但是，当堆空间较小时，运行一段时间以后，就会出现“碎片”，如果并发收集器找不到足够的空间，那么并发收集器将会停止，然后使用传统的标记、清除方式进行回收。如果出现“碎片”，可能需要进行如下配置：
-XX:+UseCMSCompactAtFullCollection：使用并发收集器时，开启对年老代的压缩。
-XX:CMSFullGCsBeforeCompaction=0：上面配置开启的情况下，这里设置多少次Full GC后，对年老代进行压缩

在官方的JVM性能调优中给出的建议也是，如果你的应用对峰值处理有要求，而对一两秒的停顿可以接受，则使用(-XX:+UseParallelGC)；如果应用对响应有更高的要求，停顿最好小于一秒，则使用(-XX:+UseConcMarkSweepGC)。

