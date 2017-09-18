
---
title: JVM内存溢出总结
date: 2017-07-25 12:20:46
categories:
    - tuning
tags: 
    - 性能优化
    - JVM
---

## java heap space
``java.lang.OutOfMemoryError: ......java heap space.....``

当你看到heap相关的时候就肯定是堆栈溢出了，此时如果代码没有问题的情况下，适当调整-Xmx和-Xms是可以避免的，不过一定是代码没有问题的前提.
为什么会溢出呢，要么代码有问题，要么访问量太多并且每个访问的时间太长或者数据太多，导致数据释放不掉，因为垃圾回收器是要找到那些是垃圾才能回收，这里它不会认为这些东西是垃圾，自然不会去回收了；
这个溢出之前，可能系统会提前先报错关键字为：
``java.lang.OutOfMemoryError:GC over head limit exceeded``
这种情况是当系统处于高频的GC状态，而且回收的效果依然不佳的情况，就会开始报这个错误，这种情况一般是产生了很多不可以被释放的对象，有可能是引用使用不当导致，或申请大对象导致，但是java heap space的内存溢出有可能提前不会报这个错误，也就是可能内存就直接不够导致，而不是高频GC.

<!--more-->

## PermGen space

``java.lang.OutOfMemoryError: PermGen space``
原因：系统的代码非常多或引用的第三方包非常多、或代码中使用了大量的常量、或通过intern注入常量、或者通过动态代码加载等方法，导致常量池的膨胀，虽然JDK 1.5以后可以通过设置对永久带进行回收，但是我们希望的是这个地方是不做GC的，它够用就行，所以一般情况下少做类似的操作，所以在面对这种情况常用的手段是：增加-XX:PermSize和-XX:MaxPermSize的大小。

## Direct buffer memory

``java.lang.OutOfMemoryError: Direct buffer memory``

在使用ByteBuffer中的allocateDirect()的时候会用到，很多javaNIO的框架中被封装为其他的方法
如果你在直接或间接使用了ByteBuffer中的allocateDirect方法的时候，而不做clear的时候就会出现类似的问题，常规的引用程序IO输出存在一个内核态与用户态的转换过程，也就是对应直接内存与非直接内存，如果常规的应用程序你要将一个文件的内容输出到客户端需要通过OS的直接内存转换拷贝到程序的非直接内存（也就是heap中），然后再输出到直接内存由操作系统发送出去，而直接内存就是由OS和应用程序共同管理的，而非直接内存可以直接由应用程序自己控制的内存，jvm垃圾回收不会回收掉直接内存这部分的内存，所以要注意。
如果经常有类似的操作，可以考虑设置参数：-XX:MaxDirectMemorySize

## StackOverflowError

``java.lang.StackOverflowError``
这个参数直接说明一个内容，就是-Xss太小了，我们申请很多局部调用的栈针等内容是存放在用户当前所持有的线程中的，线程在jdk 1.4以前默认是256K，1.5以后是1M，如果报这个错，只能说明-Xss设置得太小，当然有些厂商的JVM不是这个参数，本文仅仅针对Hotspot VM而已；不过在有必要的情况下可以对系统做一些优化，使得-Xss的值是可用的。

## unable to create new native thread

``java.lang.OutOfMemoryError: unable to create new native thread``

上面第四种溢出错误，已经说明了线程的内存空间，其实线程基本只占用heap以外的内存区域，也就是这个错误说明除了heap以外的区域，无法为线程分配一块内存区域了，这个要么是内存本身就不够，要么heap的空间设置得太大了，导致了剩余的内存已经不多了，而由于线程本身要占用内存，所以就不够用了，说明了原因，如何去修改，不用我多说，你懂的。

## request {} byte for {}out of swap

``java.lang.OutOfMemoryError: request {} byte for {}out of swap``

这类错误一般是由于地址空间不够而导致。
