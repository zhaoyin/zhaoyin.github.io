
---
title: JProfile的使用
date: 2017-08-23 20:50:56
reward: true
categories:
    - tools
tags:
    - JProfile
    - 性能分析
---

## JProfiler介绍
JProfiler是由ej-technologies GmbH公司开发的一款性能瓶颈分析工具。
其特点:
使用方便,界面操作友好(是VisualVM，MAT合起来的增强版)
对被分析的应用影响小
CPU,Thread,Memory分析功能尤其强大
支持对JDBC,JPA,NoSQL(MongoDB,HBase)servlet,Sockets等进行分析
支持多种模式(快照,附加,本地/远程)的分析
跨平台(支持多种操作系统:windows,Mac,Linux等)

## 数据采集

### 来源

* 一部分来自于jvm的分析接口**JVMTI**(JVM Tool Interface) ,JDK必须>=1.6

JVMTI is an event-based system. The profiling agent library can register handler functions for different events. It can then enable or disable selected events
例如: 对象的生命周期，thread的生命周期等信息
* 一部分来自于instruments classes(可理解为class的重写,增加JProfiler相关统计功能)
例如：方法执行时间，次数，方法栈等信息

### 原理

![数据采集原理](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofile-%E5%8E%9F%E7%90%86.png)

1. 用户在JProfiler GUI中下达监控的指令(一般就是点击某个按钮)
2. JProfiler GUI JVM 通过socket(默认端口8849)，发送指令给被分析的jvm中的JProfile Agent。
3. JProfiler Agent(如果不清楚Agent请看文章第三部分"启动模式") 收到指令后，将该指令转换成相关需要监听的事件或者指令,来注册到JVMTI上或者直接让JVMTI去执行某功能(例如dump jvm内存)
4. JVMTI 根据注册的事件，来收集当前jvm的相关信息。 例如: 线程的生命周期; jvm的生命周期;classes的生命周期;对象实例的生命周期;堆内存的实时信息等等
5. JProfiler Agent将采集好的信息保存到**内存**中，按照一定规则统计好(如果发送所有数据JProfiler GUI，会对被分析的应用网络产生比较大的影响)
6. 返回给JProfiler GUI Socket.
7. JProfiler GUI Socket 将收到的信息返回 JProfiler GUI Render
8. JProfiler GUI Render 渲染成最终的展示效果

``以上来自[深入浅出JProfiler](https://yq.aliyun.com/articles/276)``
## 采集方式

JProfier采集方式分为两种：Sampling(样本采集)和Instrumentation

### Sampling
类似于样本统计, 每隔一定时间(5ms)将每个线程栈中方法栈中的信息统计出来。优点是对应用影响小(即使你不配置任何Filter, Filter可参考文章第四部分)，缺点是一些数据/特性不能提供(例如:方法的调用次数)

### Instrumentation
在class加载之前，JProfier把相关功能代码写入到需要分析的class中，对正在运行的jvm有一定影响。优点: 功能强大，但如果需要分析的class多，那么对应用影响较大，一般配合Filter一起使用。所以一般JRE class和framework的class是在Filter中通常会过滤掉。

注: JProfiler本身没有指出数据的采集类型，这里的采集类型是针对方法调用的采集类型 。因为JProfiler的绝大多数核心功能都依赖方法调用采集的数据, 所以可以直接认为是JProfiler的数据采集类型。

## 启动模式

![Jprofiler 启动](http://oqcey66z7.bkt.clouddn.com/public/resourceJprofile%E5%90%AF%E5%8A%A8.png)

### Attach mode
可直接将本机正在运行的jvm加载JProfiler Agent. 优点是很方便，缺点是一些特性不能支持。如果选择Instrumentation数据采集方式，那么需要花一些额外时间来重写需要分析的class。

![三种模式选择](http://oqcey66z7.bkt.clouddn.com/public/resource/%E4%B8%89%E7%A7%8D%E5%90%AF%E5%8A%A8%E6%A8%A1%E5%BC%8F.png)

### Profile at startup
在被分析的jvm启动时，将指定的JProfiler Agent手动加载到该jvm。JProfiler GUI 将收集信息类型和策略等配置信息通过socket发送给JProfiler Agent，收到这些信息后该jvm才会启动。
在被分析的jvm 的启动参数增加下面内容：
语法: -agentpath:[path to jprofilerti library]

```angularjs
Integration type: [Generic application]
Selected JVM:  1.8.0 (hotspot)
Startup mode: Wait for a connection from the JProfiler GUI

Please insert

-agentpath:/opt/jprofiler10/bin/linux-x64/libjprofilerti.so=port=12536 

into the start command of your remote application right after the java command.

A remote session named Remote application on xx.xx.xx.xx will be created that connects to a running instance of the remote application that is started with the modified start command.
```

### Prepare for profiling

和Profile at startup的主要区别：被分析的jvm不需要收到JProfiler GUI 的相关配置信息就可以启动。

```angularjs
Integration type: [Generic application]
Selected JVM:  1.8.0 (hotspot)
Startup mode: Startup immediately, connect later with the JProfiler GUI

Important: The local config file /Users/UOrder/.jprofiler10/config.xml must be copied manually to  on the remote computer when the profiling settings are changed.


Please insert

-agentpath:/opt/jprofiler10/bin/linux-x64/libjprofilerti.so=port=12536,nowait 

into the start command of your remote application right after the java command.

A remote session named Remote application on xx.xx.xx.xx will be created that connects to a running instance of the remote application that is started with the modified start command.
```

### Offline profiling

一般用于适用于不能直接调试线上的场景。Offline profiling需要将信息采集内容和策略(一些Trigger)打包成一个配置文件(config.xml)，在线上启动该jvm 加载 JProfiler Agent时，加载该xml。那么JProfiler Agent会根据Trigger的类型会生成不同的信息。例如: heap dump; thread dump; method call record等
语法:
-agentpath:[path to jprofilerti library]

```angularjs
Integration type: [Generic application server]
Selected JVM:  1.8.0 (hotspot)
Startup mode: Profile offline, JProfiler GUI cannot connect

Important: The local config file /Users/xtest/.jprofiler10/config.xml must be copied manually to  on the remote computer when the profiling settings are changed.


Please insert

-agentpath:/opt/jprofiler10/bin/linux-x64/libjprofilerti.so=offline,id=114,config=/config.xml 

into the start command of your application server right after the java command.

A remote session named Application server on xx.xx.xx.xx will be created that is used for loading the profiling settings and triggers. Please add triggers to this session or use the profiling API to record data and save snapshots to disk that can later be analyzed in the JProfiler GUI.
```

### Snapshots

快照模式和VisualVm/MemoryAnalyzer(Eclipse)他们的快照分析类似，但是比他们功能强大。将做好的快照导入就可以分析，支持jps，hprof等格式的快照。

## 应用分析

### 远程启动

由于是线上环境，为了保证应用尽量少受JProfiler的影响（JProfiler启动要注入agent，必然会造成应用CPU，内存等的变化），找一个线上服务器，打5%流量（保证分析的样本充分同时又少影响线上服务的运行）。

#### Linux服务器安装

下载安装Linux版，这里安装的是RPM格式
```angularjs
wget http://download-keycdn.ej-technologies.com/jprofiler/jprofiler_linux_10_0_3.rpm
rpm -ivh jprofiler_linux_10_0_3.rpm
```

#### 服务端配置Attach模式

安装成功后，进到jprofiler的目录/opt/jprofiler10/bin，运行jpenable

![启动jpenable](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler%E5%90%AF%E5%8A%A8jpenable.png)

为安全考虑，启动传输端口请自定义。本例启动在12536

这样服务端启动并建立了连接通道

本地客户端连接后即可分析

![配置SSH](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler%E9%85%8D%E7%BD%AESSH.png)

![启动JProfier分析remote server](http://oqcey66z7.bkt.clouddn.com/public/resource/JProfiler%E9%85%8D%E7%BD%AEremote.png)


#### 其他启动模式分析

如上文启动模式一节所讲，``Profile at startup``,``Prepare for profiling``,``Offline profiling``三种模式都提供了相应的agent，在启动java应用时附加相应的``-agentpath``参数即可

快照分析则和VisualVM／MemoryAnalyzer(Eclipse)分析快照文件方式相同，即服务端通过``jmap -dump:file={file path},format=b pid``的方式dump快照文件分析。


### 本地启动

![本地通过JProfiler启动应用并分析](http://oqcey66z7.bkt.clouddn.com/public/resource/%E6%9C%AC%E5%9C%B0%E9%80%9A%E8%BF%87Jprofiler%E5%90%AF%E5%8A%A8%E5%B9%B6%E5%88%86%E6%9E%90%E5%BA%94%E7%94%A8.png)

本地分析和远程分析同样，也支持各种模式，配置上的区别只是没有远程SSH连接的过程，原理是一样的。

### 应用分析

#### 定义过滤器

![定义过滤器](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler-%E5%AE%9A%E4%B9%89%E8%BF%87%E6%BB%A4%E5%99%A8.png)

很容易理解，可以设置要分析哪些包／类，不分析哪些，功能强大。

#### Telemetries

![应用指标](http://oqcey66z7.bkt.clouddn.com/public/resource/%E5%BA%94%E7%94%A8%E6%8C%87%E6%A0%87.png)

可以图形化查看应用的各项性能指标，一目了然

#### 内存泄漏分析

##### 准备要分析的对象

如果分析内存泄漏问题，可以在分析前，执行一下工具栏的``Run GC``按钮，然后执行``Mark Current``按钮标记为初始内存状态。后面就可以分析内存泄漏问题了
![Run GC](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler-RunGC.png)

![Mark Current](http://oqcey66z7.bkt.clouddn.com/public/resource/JProfiler-MarkCurrent.png)

![对象分析](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler%E5%AF%B9%E8%B1%A1%E5%88%86%E6%9E%90.png)

##### 记录对象

![记录对象](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler-RecordedObjects.png)

![记录后可以查看Live Objects](http://oqcey66z7.bkt.clouddn.com/public/resource/%E8%AE%B0%E5%BD%95%E5%90%8E%E6%9F%A5%E7%9C%8BLiveObjects.png)

##### 制作快照

![制作快照](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler%E5%88%B6%E4%BD%9C%E5%BF%AB%E7%85%A7.png)

![缩小范围分析选择的对象](http://oqcey66z7.bkt.clouddn.com/public/resource/%E7%BC%A9%E5%B0%8F%E8%8C%83%E5%9B%B4-%E9%80%89%E6%8B%A9%E8%AE%B0%E5%BD%95%E7%9A%84%E5%AF%B9%E8%B1%A1%E5%88%86%E6%9E%90.png)

![Heap Walker](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler-HeapWalker.png)

可以在应用中对执行了``Mark Current``后异常的内存溢出对象做分析

##### 分析内存

以下可以直接根据Jprofiler的提示做分析

![执行Show in Heap Walker](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler-%E6%89%A7%E8%A1%8CShowInHeapWalker.png)

![分析泄漏对象](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler%E5%88%86%E6%9E%90%E5%B7%AE%E5%BC%82%E5%AF%B9%E8%B1%A1.png)

![执行Show In Heap Walker后的效果](http://oqcey66z7.bkt.clouddn.com/public/resource/%E6%89%A7%E8%A1%8CShowInHeapWalker%E5%90%8E%E7%9A%84%E6%95%88%E6%9E%9C.png)

![查看Allocations](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler-Allocations.png)

![Show in Graph](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler-ShowInGraph.png)

在References引用页签中，可以看到该对象的的引用关系，可以切换incoming/outcoming，显示引用的类型：
incoming  表示显示这个对象被谁引用；
outcoming 表示显示这个对象引用的其他对象；

![References](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler-References.png)

#### CPU分析

CPU分析和VisualVM执行CPU抽样功能类似，但是比它强大
![VisalVM CPU抽样](http://oqcey66z7.bkt.clouddn.com/public/resource/%E5%B1%8F%E5%B9%95%E5%BF%AB%E7%85%A7%202017-08-21%2006.31.23.png)

![CPU录像](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler-CPU%E5%88%86%E6%9E%90.png)

![CPU分析](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler-CPU%E5%88%86%E6%9E%90%E5%8D%A0%E7%94%A8.png)

![CPU Call Graph](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler-CPU-CallGraph.png)

还有其他更强大的功能在左树菜单，等你发现

#### Thread

![Threads](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler-Threads.png)

![Threads Dump](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler-ThreadsDump.png)

#### 数据库分析

![DataBases Settings](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler-DataBasesSettings.png)

![DataBases Record](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler-Databases%20record.png)

![DataBases 分析](http://oqcey66z7.bkt.clouddn.com/public/resource/Jprofiler-DataBases%E5%88%86%E6%9E%90.png)

