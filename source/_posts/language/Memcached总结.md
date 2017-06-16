
---
title: Memcached总结
date: 2017-06-05 22:40:56
reward: true
categories:
    - language
tags:
    - memcached
    - 缓存
---

## memcached相关命令

### 安装memcached

```markdown
yum clean all
yum -y update
yum -y install memcached
```

### 启动memcached

```
/usr/local/bin/memcached -d -m 10 -u root -l 192.168.0.200 -p 12000 -c 256 -P /tmp/memcached.pid
```
-d选项是启动一个守护进程， 
-m是分配给Memcache使用的内存数量，单位是MB，我这里是10MB， 
-u是运行Memcache的用户，我这里是root， 
-l是监听的服务器IP地址，如果有多个地址的话，我这里指定了服务器的IP地址192.168.0.200， 
-p是设置Memcache监听的端口，我这里设置了12000，最好是1024以上的端口， 
-c选项是最大运行的并发连接数，默认是1024，我这里设置了256，按照你服务器的负载量来设定， 
-P是设置保存Memcache的pid文件，我这里是保存在 /tmp/memcached.pid，

### 结束Memcached进程
```
kill `cat /tmp/memcached.pid`
```
<!--more-->
## 适用memcached的业务场景

* 如果网站包含了访问量很大的动态网页，因而数据库的负载将会很高。由于大部分数据库请求都是读操作，那么memcached可以显著地减小数据库负载。

* 如果数据库服务器的负载比较低但CPU使用率很高，这时可以缓存计算好的结果（ computed objects ）和渲染后的网页模板（enderred templates）。

* 利用memcached可以缓存session数据、临时数据以减少对他们的数据库写操作。

* 缓存一些很小但是被频繁访问的文件。

* 缓存Web 'services'（非IBM宣扬的Web Services，译者注）或RSS feeds的结果。

## 不适用memcached的业务场景

### 缓存对象的大小大于1MB

Memcached本身就不是为了处理庞大的多媒体（large media）和巨大的二进制块（streaming huge blobs）而设计的。

### 虚拟主机不让运行memcached服务

如果应用本身托管在低端的虚拟私有服务器上，像vmware, xen这类虚拟化技术并不适合运行memcached。Memcached需要接管和控制大块的内存，如果memcached管理      的内存被OS或 hypervisor交换出去，memcached的性能将大打折扣。

### 应用运行在不安全的环境中

Memcached为提供任何安全策略，仅仅通过telnet就可以访问到memcached。如果应用运行在共享的系统上，需要着重考虑安全问题。

### 业务本身需要的是持久化数据或者说需要的应该是database

### 不能能够遍历memcached中所有的item

这个操作的速度相对缓慢且阻塞其他的操作（这里的缓慢时相比memcached其他的命令）。memcached所有非调试（non-debug）命令，例如add, set, get, fulsh等无论

memcached中存储了多少数据，它们的执行都只消耗常量时间。任何遍历所有item的命令执行所消耗的时间，将随着memcached中数据量的增加而增加。当其他命令因为等待（遍历所有item的命令执行完毕）而不能得到执行，因而阻塞将发生。

### memcached能接受的key的最大长度是250个字符
memcached能接受的key的最大长度是250个字符。需要注意的是，250是memcached服务器端内部的限制。如果使用的Memcached客户端支持"key的前缀"或类似特性，那么key（前缀+原始key）的最大长度是可以超过250个字符的。推荐使用较短的key，这样可以节省内存和带宽。

### 单个item的大小被限制在1M byte之内
Memcached存储单个item最大数据是在1MB内，如果数据超过1M,存取set和get是都是返回false，而且引起性能的问题。

所以Memcahce不适合缓存大数据，超过1MB的数据，可以考虑在客户端压缩或拆分到多个key中。大的数据在进行load和uppack到内存的时候需要花很长时间，从而降低服务器的性能。

Memcached支持最大的存储对象为1M。这个值由其内存分配机制决定的。

memcached默认情况下采用了名为Slab Allocator的机制分配、管理内存。在该机制出现以前，内存的分配是通过对所有记录简单地进行malloc和free来进行的。但是，这种方式会导致内存碎片，加重操作系统内存管理器的负担，最坏的情况下，会导致操作系统比memcached进程本身还慢。Slab Allocator就是为解决该问题而诞生的。Slab Allocator的基本原理是按照预先规定的大小，将分配的内存分割成特定长度的块，以完全解决内存碎片问题.

Memcached的内存存储引擎，使用slabs来管理内存。内存被分成大小不等的slabs chunks（先分成大小相等的slabs，然后每个slab被分成大小相等chunks，不同slab的chunk大小是不相等的）。chunk的大小依次从一个最小数开始，按某个因子增长，直到达到最大的可能值。如果最小值为400B，最大值是1MB，因子是1.20，各个slab的chunk的大小依次是：

slab1 - 400B；slab2 - 480B；slab3 - 576B ...slab中chunk越大，它和前面的slab之间的间隙就越大。因此，最大值越大，内存利用率越低。Memcached必须为每个slab预先分配内存，因此如果设置了较小的因子和较大的最大值，会需要为Memcached提供更多的内存。

不要尝试向memcached中存取很大的数据，例如把巨大的网页放到mencached中。因为将大数据load和unpack到内存中需要花费很长的时间，从而导致系统的性能反而不好。如果确实需要存储大于1MB的数据，可以修改slabs.c：POWER_BLOCK的值，然后重新编译memcached；或者使用低效的malloc/free。另外，可以使用数据库、MogileFS等方案代替Memcached系统。

## memcached的内存分配器是如何工作的？为什么不适用malloc/free！？为何要使用slabs？
实际上，这是一个编译时选项。默认会使用内部的slab分配器，而且确实应该使用内建的slab分配器。最早的时候，memcached只使用malloc/free来管理内存。然而，这种方式不能与OS的内存管理以前很好地工作。反复地malloc/free造成了内存碎片，OS最终花费大量的时间去查找连续的内存块来满足malloc的请求，而不是运行memcached进程。slab分配器就是为了解决这个问题而生的。内存被分配并划分成chunks，一直被重复使用。因为内存被划分成大小不等的slabs，如果item的大小与被选择存放它的slab不是很合适的话，就会浪费一些内存。

## memcached对item的过期时间有什么限制？

item对象的过期时间最长可以达到30天。memcached把传入的过期时间（时间段）解释成时间点后，一旦到了这个时间点，memcached就把item置为失效状态，这是一个简单但obscure的机制。

## 什么是二进制协议，是否需要关注？

二进制协议尝试为端提供一个更有效的、可靠的协议，减少客户端/服务器端因处理协议而产生的CPU时间。根据Facebook的测试，解析ASCII协议是memcached中消耗CPU时间最多的环节。

## memcached是原子的吗？

所有的被发送到memcached的单个命令是完全原子的。如果您针对同一份数据同时发送了一个set命令和一个get命令，它们不会影响对方。它们将被串行化、先后执行。即使在多线程模式，所有的命令都是原子的。然是，命令序列不是原子的。如果首先通过get命令获取了一个item，修改了它，然后再把它set回memcached，系统不保证这个item没有被其他进程（process，未必是操作系统中的进程）操作过。memcached 1.2.5以及更高版本，提供了gets和cas命令，它们可以解决上面的问题。如果使用gets命令查询某个key的item，memcached会返回该item当前值的唯一标识。如果客户端程序覆写了这个item并想把它写回到memcached中，可以通过cas命令把那个唯一标识一起发送给memcached。如果该item存放在memcached中的唯一标识与您提供的一致，写操作将会成功。如果另一个进程在这期间也修改了这个item，那么该item存放在memcached中的唯一标识将会改变，写操作就会

失败。


详细了解Memcached的内存分配机制：

http://cjjwzs.javaeye.com/blog/762453

[Memcache存储大数据的问题](http://blog.csdn.net/hguisu/article/details/6163621)