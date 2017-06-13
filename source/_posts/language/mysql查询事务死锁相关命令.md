
---
title: mysql查询事务/死锁相关命令
date: 2017-06-04 12:40:56
reward: true
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

```markdown
+----------------------------+---------------------+------+-----+---------------------+-------+
| Field | Type | Null | Key | Default | Extra |
+----------------------------+---------------------+------+-----+---------------------+-------+
| trx_id | varchar(18) | NO | | | |#事务ID
| trx_state | varchar(13) | NO | | | |#事务状态：
| trx_started | datetime | NO | | 0000-00-00 00:00:00 | |#事务开始时间；
| trx_requested_lock_id | varchar(81) | YES | | NULL | |#innodb_locks.lock_id
| trx_wait_started | datetime | YES | | NULL | |#事务开始等待的时间
| trx_weight | bigint(21) unsigned | NO | | 0 | |#
| trx_mysql_thread_id | bigint(21) unsigned | NO | | 0 | |#事务线程ID
| trx_query | varchar(1024) | YES | | NULL | |#具体SQL语句
| trx_operation_state | varchar(64) | YES | | NULL | |#事务当前操作状态
| trx_tables_in_use | bigint(21) unsigned | NO | | 0 | |#事务中有多少个表被使用
| trx_tables_locked | bigint(21) unsigned | NO | | 0 | |#事务拥有多少个锁
| trx_lock_structs | bigint(21) unsigned | NO | | 0 | |#
| trx_lock_memory_bytes | bigint(21) unsigned | NO | | 0 | |#事务锁住的内存大小（B）
| trx_rows_locked | bigint(21) unsigned | NO | | 0 | |#事务锁住的行数
| trx_rows_modified | bigint(21) unsigned | NO | | 0 | |#事务更改的行数
| trx_concurrency_tickets | bigint(21) unsigned | NO | | 0 | |#事务并发票数
| trx_isolation_level | varchar(16) | NO | | | |#事务隔离级别
| trx_unique_checks | int(1) | NO | | 0 | |#是否唯一性检查
| trx_foreign_key_checks | int(1) | NO | | 0 | |#是否外键检查
| trx_last_foreign_key_error | varchar(256) | YES | | NULL | |#最后的外键错误
| trx_adaptive_hash_latched | int(1) | NO | | 0 | |#
| trx_adaptive_hash_timeout | bigint(21) unsigned | NO | | 0 | |#
+----------------------------+---------------------+------+-----+---------------------+-------+
```

* 查询当前锁定事务

``SELECT * FROM INFORMATION_SCHEMA.INNODB_LOCKS;``

这个表的trx_id即为innodb_trx表的主键,trx_mysql_thread_id即为processlist表的id

```markdown
+-------------+---------------------+------+-----+---------+-------+
| Field | Type | Null | Key | Default | Extra |
+-------------+---------------------+------+-----+---------+-------+
| lock_id | varchar(81) | NO | | | |#锁ID
| lock_trx_id | varchar(18) | NO | | | |#拥有锁的事务ID
| lock_mode | varchar(32) | NO | | | |#锁模式
| lock_type | varchar(32) | NO | | | |#锁类型
| lock_table | varchar(1024) | NO | | | |#被锁的表
| lock_index | varchar(1024) | YES | | NULL | |#被锁的索引
| lock_space | bigint(21) unsigned | YES | | NULL | |#被锁的表空间号
| lock_page | bigint(21) unsigned | YES | | NULL | |#被锁的页号
| lock_rec | bigint(21) unsigned | YES | | NULL | |#被锁的记录号
| lock_data | varchar(8192) | YES | | NULL | |#被锁的数据
+-------------+---------------------+------+-----+---------+-------+
```


* 查询当前等待的事务

``SELECT * FROM INFORMATION_SCHEMA.INNODB_LOCK_WAITS;``
这个表的trx_id即为innodb_trx表的主键,trx_mysql_thread_id即为processlist表的id
```markdown
+-------------------+-------------+------+-----+---------+-------+
| Field | Type | Null | Key | Default | Extra |
+-------------------+-------------+------+-----+---------+-------+
| requesting_trx_id | varchar(18) | NO | | | |#请求锁的事务ID
| requested_lock_id | varchar(81) | NO | | | |#请求锁的锁ID
| blocking_trx_id | varchar(18) | NO | | | |#当前拥有锁的事务ID
| blocking_lock_id | varchar(81) | NO | | | |#当前拥有锁的锁ID
+-------------------+-------------+------+-----+---------+-------+
```

### "Lock wait timeout exceeded; try restarting transaction"

select @@autocommit;

如果为0会导致原来的update语句如果没有commit的话，你再重新执行update语句，就会等待锁定，当等待时间过长的时候，就会报ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction的错误。

commit刚才执行的update语句，之后 set global autocommit=1;

