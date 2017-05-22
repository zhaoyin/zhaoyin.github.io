
---
title: next主题前端资源CDN加速
date: 2017-05-22 20:40:46
categories:
    - tuning
tags: 
    - JVM
    - CPU
    - Thread
---

通过Github上的开源项目[运维脚本](https://github.com/superhj1987/awesome-scripts)

这个项目是从https://github.com/oldratlee/useful-scripts fork来的，貌似是阿里运维人员的工具总结，只是awesome-scripts维护的更频繁。

其中查询耗CPU的线程排行对于分析JVM程序调优很有用并且很方便.

```
 curl -sLk 'https://raw.githubusercontent.com/superhj1987/awesome-scripts/master/java/bin/show-busy-java-threads' | bash
 ```
<!--more-->

直接执行以上命令可以显示当前Linux环境消耗CPU的线程排行top5.

用于快速排查Java的CPU性能问题(top us值过高)，自动查出运行的Java进程中消耗CPU多的线程，并打印出其线程栈，从而确定导致性能问题的方法调用。

适用于Linux，不适用于macOS

![img](http://oqcey66z7.bkt.clouddn.com/public/images/JVM-CPU-Threads.png)