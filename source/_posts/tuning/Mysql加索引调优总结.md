
---
title: Mysql调优总结
date: 2017-06-05 22:40:56
categories:
    - tuning
tags:
    - MySQL
    - 性能优化
---

# 索引调优

## 最左前缀匹配原则
非常重要的原则，mysql会一直向右匹配直到遇到范围查询(>、<、between、like)就停止匹配，比如a = 1 and b = 2 and c > 3 and d = 4 如果建立(a,b,c,d)顺序的索引，d是用不到索引的，如果建立(a,b,d,c)的索引则都可以用到，a,b,d的顺序可以任意调整；

## =和in可以乱序
比如a = 1 and b = 2 and c = 3 建立(a,b,c)索引可以任意顺序，mysql的查询优化器会帮你优化成索引可以识别的形式；

## 尽量选择区分度高的列作为索引
区分度的公式是count(distinct col)/count(*)，表示字段不重复的比例，比例越大我们扫描的记录数越少，唯一键的区分度是1，而一些状态、性别字段可能在大数据面前区分度就是0，那可能有人会问，这个比例有什么经验值吗？使用场景不同，这个值也很难确定，一般需要join的字段我们都要求是0.1以上，即平均1条扫描10条记录；

## 索引列不能参与计算保持列“干净”
比如from_unixtime(create_time) = ’2014-05-29’就不能使用到索引，原因很简单，b+树中存的都是数据表中的字段值，但进行检索时，需要把所有元素都应用函数才能比较，显然成本太大。所以语句应该写成create_time = unix_timestamp(’2014-05-29’);

## 尽量的扩展索引，不要新建索引。
比如表中已经有a的索引，现在要加(a,b)的索引，那么只需要修改原来的索引即可。

## 索引不会包含有NULL值的列
只要列中包含有NULL值都将不会被包含在索引中，复合索引中只要有一列含有NULL值，那么这一列对于此复合索引就是无效的。所以我们在数据库设计时不要让字段的默认值为NULL。

## 不使用NOT IN
NOT IN操作都不会使用索引将进行全表扫描。NOT IN可以NOT EXISTS代替
## in要具体分析
比如in的字段是唯一键值列比如id或者区分度高的索引列就可以命中索引，如果是建立在非索引列或者区分度不高的列则不能命中索引，当然也要看查询计划具体分析。
in 一般用exists代替会有更好的效果.

<!--more-->

## 什么情况下应不建或少建索引
* 表记录太少
* 经常插入、删除、修改的表
* 数据重复且分布平均的表字段
* 经常和主字段一块查询但主字段索引值比较多的表字段

# 执行计划

## Extra列解析

### ``using index``

索引覆盖查询：如果查询的时候，用到了索引，并且你最终需要的数据也是这个索引的一部分，那么就出现using index.
查询时不需要回表查询，直接通过索引就可以获取查询的数据。
user表有索引``key(id), key(name) ``
```
select id from user; 
select name from user; 
select id from user where id<9;   
```
而``select id,name from user where id<9``就没有
组合索引``key(id,name) ``
``select id,name from user where id>9``也可以有 
### ``using where``
会根据查询条件过滤出结果集
表示存储引擎返回的记录并不是所有的都满足查询条件，需要在server层进行过滤。查询条件中分为限制条件和检查条件，5.6之前，存储引擎只能根据限制条件扫描数据并返回，然后server层根据检查条件进行过滤再返回真正符合查询的数据。5.6.x之后支持ICP特性，可以把检查条件也下推到存储引擎层，不符合检查条件和限制条件的数据，直接不读取，这样就大大减少了存储引擎扫描的记录数量。extra列显示using index condition
### ``using filesort``
排序时无法使用到索引时，就会出现这个。常见于order by和group by语句中。
表示排序的时候，没有用上索引，不得不采取其他的方式排序。 这里的其他方式有在内存排，在临时文件排，采用双路排序法，或者是采用整行排序等，而using file sort并没有说是其他哪些排序方法。 
这个 filesort 并不是说通过磁盘文件进行排序，而只是告诉我们进行了一个排序操作。即在MySQL Query Optimizer 所给出的执行计划(通过 EXPLAIN 命令查看)中被称为文件排序（filesort）
如果出现这个的sql不频繁没有问题，如果这个查询很频繁就要考虑优化。
优化方式是在order by 的字段建立索引
由于 Using filesort是使用算法在 内存中进行排序，MySQL对于排序的记录的大小也是有做限制：max_length_for_sort_data，默认为1024
当排序查询的数据量在默认值的范围内是，在排序的字段上
* 加上索引
* 去掉不必要的返回字段
* 增大 sort_buffer_size 参数设置
* 加大 max_length_for_sort_data 参数的设置
可以提升MySQL查询的速度。
#### order by能命中索引不出现filesort的情况
* 返回选择的字段，即只包括在有选择的此列上（select后面的字段），不一定适应*的情况)：
* 只有当ORDER BY中所有的列必须包含在相同的索引，并且索引的顺序和order by子句中的顺序完全一致，并且所有列的排序方向（升序或者降序）一样才有，（混合使用ASC模式和DESC模式则不使用索引）
* where 语句与ORDER BY语句组合满足最左前缀
* 如果查询联接了多个表，只有在order by子句的所有列引用的是第一个表的列才可以
#### order by不能命中索引出现filesort的情况
* where语句与order by语句，使用了不同的索引
* 检查的行数过多，且没有使用覆盖索引
* ORDER BY中的列不包含在相同的索引，也就是使用了不同的索引
* 对索引列同时使用了ASC和DESC
* where语句或者ORDER BY语句中索引列使用了表达式，包括函数表达式
* where 语句与ORDER BY语句组合满足最左前缀，但where语句中使用了条件查询。查见第10句,虽然where与order by构成了索引最左有缀的条件，但是where子句中使用的是条件查询。
* 当使用left join，使用右边的表字段排序
### ``using temporary``
表示使用了临时表存储中间结果。临时表可以是内存临时表和磁盘临时表，执行计划中看不出来，需要查看status变量，used_tmp_table，used_tmp_disk_table才能看出来。
### ``using_union``
表示使用or连接各个使用索引的条件时，该信息表示从处理结果获取并集
### ``using intersect``
表示使用and的各个索引的条件时，该信息表示是从处理结果获取交集
### ``using sort_union和using sort_intersection``
与前面两个对应的类似，只是他们是出现在用and和or查询信息量大时，先查询主键，然后进行排序合并后，才能读取记录并返回。
### ``firstmatch(tb_name)``
5.6.x开始引入的优化子查询的新特性之一，常见于where字句含有in()类型的子查询。如果内表的数据量比较大，就可能出现这个
### ``loosescan(m..n)``
5.6.x之后引入的优化子查询的新特性之一，在in()类型的子查询中，子查询返回的可能有重复记录时，就可能出现这个
### ``filtered``
使用explain extended时会出现这个列，5.7之后的版本默认就有这个字段，不需要使用explain extended了。这个字段表示存储引擎返回的数据在server层过滤后，剩下多少满足查询的记录数量的比例，注意是百分比，不是具体记录数。
## key_len解析

key_len 用于表示本次查询中，所选择的索引长度有多少字节，通常我们可借此判断联合索引有多少列被选择了。

在这里 key_len 大小的计算规则是：

一般地，key_len 等于索引列类型字节长度，例如int类型为4 bytes，bigint为8 bytes；
如果是字符串类型，还需要同时考虑字符集因素，例如：CHAR(30) UTF8则key_len至少是90 bytes；
若该列类型定义时允许NULL，其key_len还需要再加 1 bytes；
若该列类型为变长类型，例如 VARCHAR（TEXT\BLOB不允许整列创建索引，如果创建部分索引也被视为动态列类型），其key_len还需要再加 2 bytes;
key_len只计算where条件用到的索引长度，而排序和分组就算用到了索引，也不会计算到key_len中。
 
## type
依次从好到差：system，const，eq_ref，ref，fulltext，ref_or_null，unique_subquery，index_subquery，range，index_merge，index，ALL。
除了all之外，其他的type都可以使用到索引，除了index_merge之外，其他的type只可以用到一个索引。
* system：表中只有一行数据或者是空表，且只能用于myisam和memory表。如果是Innodb引擎表，type列在这个情况通常都是all或者index
* const：使用唯一索引或者主键，返回记录一定是1行记录的等值where条件时，通常type是const。其他数据库也叫做唯一索引扫描。
* eq_ref：出现在要连接过个表的查询计划中，驱动表只返回一行数据，且这行数据是第二个表的主键或者唯一索引，且必须为not null，唯一索引和主键是多列时，只有所有的列都用作比较时才会出现eq_ref。
* ref：不像eq_ref那样要求连接顺序，也没有主键和唯一索引的要求，只要使用相等条件检索时就可能出现，常见与辅助索引的等值查找。或者多列主键、唯一索引中，使用第一个列之外的列作为等值查找也会出现，总之，返回数据不唯一的等值查找就可能出现。
* fulltext：全文索引检索，要注意，全文索引的优先级很高，若全文索引和普通索引同时存在时，mysql不管代价，优先选择使用全文索引。
* ref_or_null：与ref方法类似，只是增加了null值的比较。实际用的不多。
* unique_subquery：用于where中的in形式子查询，子查询返回不重复值唯一值。
* index_subquery：用于in形式子查询使用到了辅助索引或者in常数列表，子查询可能返回重复值，可以使用索引将子查询去重。
* range：索引范围扫描，常见于使用>,<,is null,between ,in ,like等运算符的查询中。
* index_merge：表示查询使用了两个以上的索引，最后取交集或者并集，常见and ，or的条件使用了不同的索引，官方排序这个在ref_or_null之后，但是实际上由于要读取所个索引，性能可能都不如range。
* index：索引全表扫描，把索引从头到尾扫一遍，常见于使用索引列就可以处理不需要读取数据文件的查询、可以使用索引排序或者分组的查询。
* all：这个就是全表扫描数据文件，然后再在server层进行过滤返回符合要求的记录。
## ref
如果是使用的常数等值查询，这里会显示const，如果是连接查询，被驱动表的执行计划这里会显示驱动表的关联字段，如果是条件使用了表达式或者函数，或者条件列发生了内部隐式转换，这里可能显示为func。
## rows
这里是执行计划中估算的扫描行数，不是精确值。

# 索引命中规则
![索引命中流程图](http://oqcey66z7.bkt.clouddn.com/public/resource/MySQL-where%E6%9D%A1%E4%BB%B6%E5%89%96%E6%9E%90.jpg)

* Index Key
MySQL是用来确定扫描的数据范围，实际就是可以利用到的MySQL索引部分，体现在Key Length。
* Index Filter
MySQL用来确定哪些数据是可以用索引去过滤，在启用ICP后，可以用上索引的部分。
* Table Filter
MySQL无法用索引过滤，回表取回行数据后，到server层进行数据过滤。

## Index Key

Index Key是用来确定MySQL的一个扫描范围，分为上边界和下边界。

MySQL利用=、>=、> 来确定下边界（first key），利用最左原则，首先判断第一个索引键值在where条件中是否存在，如果存在，则判断比较符号，如果为(=,>=)中的一种，加入下边界的界定，然后继续判断下一个索引键，如果存在且是(>)，则将该键值加入到下边界的界定，停止匹配下一个索引键；如果不存在，直接停止下边界匹配。

exp:
idx_c1_c2_c3(c1,c2,c3)
where c1>=1 and c2>2 and c3=1
-->  first key (c1,c2)
--> c1为 '>=' ，加入下边界界定，继续匹配下一个
-->c2 为 '>'，加入下边界界定，停止匹配

上边界（last key）和下边界（first key）类似，首先判断是否是否是(=,<=)中的一种，如果是，加入界定，继续下一个索引键值匹配，如果是(<)，加入界定，停止匹配

exp:
idx_c1_c2_c3(c1,c2,c3)
where c1<=1 and c2=2 and c3<3
--> first key (c1,c2,c3)
--> c1为 '<='，加入上边界界定，继续匹配下一个
--> c2为 '='加入上边界界定，继续匹配下一个
--> c3 为 '<'，加入上边界界定，停止匹配

注：这里简单的记忆是，如果比较符号中包含'='号，'>='也是包含'='，那么该索引键是可以被利用的，可以继续匹配后面的索引键值；如果不存在'='，也就是'>','<'，这两个，后面的索引键值就无法匹配了。同时，上下边界是不可以混用的，哪个边界能利用索引的的键值多，就是最终能够利用索引键值的个数。
## Index Filter

字面理解就是可以用索引去过滤。也就是字段在索引键值中，但是无法用去确定Index Key的部分。

exp:
idex_c1_c2_c3
where c1>=1 and c2<=2 and c3 =1
index key --> c1
index filter--> c2 c3

这里为什么index key 只是c1呢？因为c2 是用来确定上边界的，但是上边界的c1没有出现(<=,=)，而下边界中，c1是>=,c2没有出现，因此index key 只有c1字段。c2,c3 都出现在索引中，被当做index filter.

## Table Filter

无法利用索引完成过滤，就只能用table filter。此时引擎层会将行数据返回到server层，然后server层进行table filter。

## Between 和Like 的处理
* ``Between``

where c1 between  'a' and 'b' 等价于 where c1>='a' and c1 <='b'，所以进行相应的替换，然后带入上层模型，确定上下边界即可

* ``Like``

首先需要确认的是%不能是最在最左侧，where c1 like '%a' 这样的查询是无法利用索引的，因为索引的匹配需要符合最左前缀原则

where c1 like 'a%'  其实等价于 where c1>='a' and c1<'b' 大家可以仔细思考下。


[SQL优化大全](http://blog.csdn.net/hguisu/article/details/5731629)
[MySQL优化大全](http://blog.csdn.net/hguisu/article/details/5713180)
[explain 执行计划详解](http://www.cnblogs.com/liujingyuan789/p/6061188.html)
[10分钟让你明白MySQL是如何利用索引的](http://fordba.com/spend-10-min-to-understand-how-mysql-use-index.html)
