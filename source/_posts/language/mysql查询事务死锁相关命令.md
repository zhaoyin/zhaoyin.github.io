
---
title: mysql查询事务/死锁相关命令
date: 2017-06-04 12:40:56
categories:
    - language
tags:
    - mysql
    - 死锁
    - 事务
---
* 查询innodb 死锁
```
show engine innodeb status;
```
拷贝status里面的内容到文本编辑器，查看LATEST DETECTED DEADLOCK块即为之前死锁的记录

```
SEMAPHORES
主要显示系统的当前的信号等待信息及各种等待信号的统计信息，这部分对调整innodb_thread_concurrency参数有非常大的帮助。当等待信号量非常大的时候，可能就需要禁用并发线程检测设置innodb_thread_concurrency=0;

TRANSACTIONS
主要展示系统的锁等待信息和当前活动事务信息，通过这部分，可以追踪到死锁的详细信息。

FILE I/O
文件I/O相关信息，主要是IO等待信息。

INSERTBUFFER AND ADAPTIVE HASH INDEX
显示插入缓存当前状态信息及自适应hash index的状态

LOG
Innodb 事务日志相关信息，包括当前的日志序列号（Log sequence number），已经刷新同步到那个序列号，最近的check point到那个序列号了。除此之外，还显示了系统从启动到现在已经做了多少次check point，多少次日志刷新。

BUFFER POOLAND MEMORY
主要显示innodbbuffer pool相关的各种统计信息，以及其他一些内存使用情况。

ROWOPERATIONS
主要显示的是与客户端的请求query和query所影响的记录统计信息
```
<!--more-->
* 查询是否锁表
``show OPEN TABLES where In_use > 0;``

* 查询当前进程

``show processlist;``

``select * from `information_schema`.processlist;``

有super权限可以看到所有线程，否则只能看到当前用户线程

select的语句可以方便排序搜索

* kill阻塞进程

从查询的进程列表中``kill id``即可

* 查询当前事务

``SELECT * FROM `information_schema`.innodb_trx;``

* 查询当前锁定事务

``SELECT * FROM INFORMATION_SCHEMA.INNODB_LOCKS;``

这个表的trx_id即为innodb_trx表的主键,trx_mysql_thread_id即为processlist表的id

* 查询当前等待的事务

``SELECT * FROM INFORMATION_SCHEMA.INNODB_LOCK_WAITS;``
这个表的trx_id即为innodb_trx表的主键,trx_mysql_thread_id即为processlist表的id

