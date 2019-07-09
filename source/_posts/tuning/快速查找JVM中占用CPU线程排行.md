
---
title: 快速查找JVM中占用CPU线程排行
date: 2017-05-22 20:40:46
reward: true
categories:
    - tuning
tags: 
    - JVM
    - CPU
    - Thread
---

## 实践

通过Github上的开源项目[awesome-scripts](https://github.com/superhj1987/awesome-scripts)

这个项目是从https://github.com/oldratlee/useful-scripts fork来的，貌似是阿里运维人员的工具总结，只是awesome-scripts维护的更频繁。

其中查询耗CPU的线程排行对于分析JVM程序调优很有用并且很方便.

```
 curl -sLk 'https://raw.githubusercontent.com/superhj1987/awesome-scripts/master/java/bin/show-busy-java-threads' | bash
 ```
<!--more-->

直接执行以上命令可以显示当前Linux环境消耗CPU的线程排行top5.

用于快速排查Java的CPU性能问题(top us值过高)，自动查出运行的Java进程中消耗CPU多的线程，并打印出其线程栈，从而确定导致性能问题的方法调用。

## 原理

1、top后按c查看最耗cpu的进程，得到pid
2、top -Hp pid 查看该进程里的线程资源使用情况，找到最耗资源的线程的pid
3、jstack pid来查看进程的各个线程栈，注意这里的pid是第一步中进程的pid，不是第二步得到的线程id
4、将第二步得到的pid转成16进制之后在线程栈信息里查找nid等于pid16进制的，就找到最耗资源的线程的栈信息

适用于Linux，不适用于macOS

![img](http://static.xcoder.ren/public/images/JVM-CPU-Threads.png)

