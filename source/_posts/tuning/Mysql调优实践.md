
---
title: Mysql调优实践
date: 2017-09-21 21:40:46
reward: true
categories:
    - tuning
tags: 
    - MySQL
---

不是一定要有索引，也不是索引越多越好，当然也不是组合索引一定比单索引好。

<!--more-->

## 优化实践

* 单独分别建索引引发的问题

```
SELECT COUNT(ub.id) AS size 
FROM userbusientity ub, Product a 
WHERE ub.iBusiObjectId= a.id  AND ub.iUserId=?1  AND ub.iBusiEntityId=?2  AND a.ideleted= 0  AND ub.ideleted= 0
```
这个原来对userbusientity表是单独建索引的，即iUserId和iBusiEntityId分别建索引
所以原来的执行计划如下：
![MySQL单独建立索引执行计划](http://oqcey66z7.bkt.clouddn.com/public/resource/mysql/mysql-tuning-1-explain-original.png)

可以看到EXTRA里面有using intersect，它的意思简单的说就是and，就是说mysql会分别按照两个索引来扫描，然后取并集。所以预计会扫描1808行。

查看UserBusientity这个类的dao发现，sql中iUserID一般都是和iBusiEntityID联合使用的。所以删除索引iUserID和iBusiEntityId。建立联合索引(iUserId,iBusiEntityId),优化后效果如下，变成扫描135行了

![MySQL单独建立索引优化后执行计划](http://oqcey66z7.bkt.clouddn.com/public/resource/mysql/mysql-tuning-1-explain-result.png)

* 索引区分度不高引发的问题
```
SELECT bulletin0_.id AS id1_47_,
       bulletin0_.iDeleted AS iDeleted2_47_,
       bulletin0_.pubuts AS pubuts3_47_,
       bulletin0_.cCreator AS cCreator4_47_,
       bulletin0_.cModifier AS cModifie5_47_,
       bulletin0_.dCreatedTime AS dCreated6_47_,
       bulletin0_.dModifyTime AS dModifyT7_47_,
       bulletin0_.iCorpId AS iCorpId8_47_,
       bulletin0_.iOrgId AS iOrgId9_47_,
       bulletin0_.bEnable AS bEnable10_47_,
       bulletin0_.cBulletinTypeCode AS cBullet11_47_,
       bulletin0_.cBulletinUserTypeCode AS cBullet12_47_,
       bulletin0_.cTitle AS cTitle13_47_,
       bulletin0_.cType AS cType14_47_,
       bulletin0_.cVoucherNo AS cVouche15_47_,
       bulletin0_.cVoucherType AS cVouche16_47_,
       bulletin0_.dCreated AS dCreate17_47_,
       bulletin0_.dRescinded AS dRescin18_47_,
       bulletin0_.iAgentId AS iAgentI19_47_,
       bulletin0_.iOrder AS iOrder20_47_
  FROM Bulletin bulletin0_
 WHERE bulletin0_.iDeleted= 0
   AND bulletin0_.iCorpId= ?1
   AND bulletin0_.cType= ?2
   AND bulletin0_.id IN(
SELECT bulletinus1_.iBulletinId
  FROM BulletinUser bulletinus1_
 WHERE bulletinus1_.bReaded= 0
   AND bulletinus1_.iUserId= ?3
   AND bulletinus1_.iCorpId= ?4
   AND bulletinus1_.iDeleted= 0)
   AND bulletin0_.cBulletinUserTypeCode= ?5
   AND(1= 1
    OR bulletin0_.iAgentId= 0)
 ORDER BY bulletin0_.dCreated DESC
 LIMIT 3
```
执行计划
![MySQL索引区分度不高执行计划](http://oqcey66z7.bkt.clouddn.com/public/resource/mysql/mysql-tuning-2-explain-original.png)

很多时候用 exists 代替 in 是一个好的选择：``select num from a where num in(select num from b)``

用下面的语句替换：

``select num from a where exists(select 1 from b where num=a.num)``

替换后的执行计划

![MySQL索引区分度不高用exist替代in后的执行计划](http://oqcey66z7.bkt.clouddn.com/public/resource/mysql/mysql-tuning-2-explain-exist.png)

可以从执行计划上看出用exist替代in是有效果的，但是仍然要扫描16万行。所以我们需要从业务实际出发分析，表面上看这个是在查Bulletin表的数据，其实分析这个sql的本质会发现，它的数据主要依赖于BulletinUser，其实BulletinUser表才是真正意义上的主表，虽然两边索引都命中了，但是由于BulletinUser表数据量巨大，虽然查某一个人的，也需要扫描18万数据。所以这个需要在业务上优化，把外层查询Bulletin表的cType和cBulletinUserTypeCode放到BulletinUser表，这样进一步减少查询的数据，逻辑上也更合理

* 所建索引价值不大的问题

我们来看看这个sql
```
SELECT orderpayme0_.id AS id1_134_,
       orderpayme0_.iDeleted AS iDeleted2_134_,
       orderpayme0_.pubuts AS pubuts3_134_,
       orderpayme0_.cCreator AS cCreator4_134_,
       orderpayme0_.cModifier AS cModifie5_134_,
       orderpayme0_.dCreatedTime AS dCreated6_134_,
       orderpayme0_.dModifyTime AS dModifyT7_134_,
       orderpayme0_.iCorpId AS iCorpId8_134_,
       orderpayme0_.iOrgId AS iOrgId9_134_,
       orderpayme0_.bEnable AS bEnable10_134_,
       orderpayme0_.bIsCurrent AS bIsCurr11_134_,
       orderpayme0_.cCode AS cCode12_134_,
       orderpayme0_.cMemo AS cMemo13_134_,
       orderpayme0_.cName AS cName14_134_,
       orderpayme0_.dCreated AS dCreate15_134_,
       orderpayme0_.iCreaterId AS iCreate16_134_,
       orderpayme0_.iExpenseOrderId AS iExpens17_134_,
       orderpayme0_.iOrder AS iOrder18_134_,
       orderpayme0_.iOrderId AS iOrderI19_134_
  FROM OrderPaymentStatus orderpayme0_
 WHERE orderpayme0_.iDeleted= 0
   AND orderpayme0_.iCorpId= ?1
   AND orderpayme0_.iExpenseOrderId= ?2
   AND orderpayme0_.iDeleted= 0
```
这个sql原来在iCorpId上建了索引。这个查询会扫描这个租户的所有支付状态，数据量也不会小

要分析一个索引合理不合理，先要分析业务，OrderPaymentStatus表是一个字表，它永远也不会以一个主表的身份存在，要从它上面查数据，要么带上iOrderID（订单id），要么带上iExpenseOrderId（费用单id）。再想一下如果有iOrderId或者iExpenseOrderId就意味着一定有iCorpId的索引（从我们的表结构逻辑上说，我们的订单表，费用单表都有iCorpId），就是说iOrderId其实是相当于iOrderId+iCorpId的组合索引的。

所以这个的方案是去掉iCorpId索引，分别建立iOrderId和iExpenseOrderId的索引。执行计划的结果一定是我们期望的，扫描行数从几千行变成了3行。

相似的场景还有iUserId或者iAgentId这种类似的情况。

* Order by索引问题导致的using filesort问题

```
select productvie0_.id as id1_175_,
       productvie0_.iDeleted as iDeleted2_175_,
       productvie0_.pubuts as pubuts3_175_,
       productvie0_.cCreator as cCreator4_175_,
       productvie0_.cModifier as cModifie5_175_,
       productvie0_.dCreatedTime as dCreated6_175_,
       productvie0_.dModifyTime as dModifyT7_175_,
       productvie0_.iCorpId as iCorpId8_175_,
       productvie0_.iOrgId as iOrgId9_175_,
       productvie0_.dViewDate as dViewDa10_175_,
       productvie0_.iProductId as iProduc11_175_,
       productvie0_.iUserId as iUserId12_175_
  from ProductViewHistory productvie0_
 where(productvie0_.iDeleted= 0)
   and productvie0_.iUserId= ?1
   and productvie0_.iCorpId= ?2
 order by productvie0_.dViewDate desc
 limit 10,10
```

上面这个sql原来是在iUserId和iCorpId上分别建索引。索引区分度不高，其实可以只建iUserId的索引

但是我们还同时发现执行计划里面Extra是``Using where; Using filesort``.我们知道``Using filesort``对于频繁执行的SQL也需要优化。

我们在iUserId和dViewDate上做组合索引。优化后执行计划

![优化filesort后的效果](http://oqcey66z7.bkt.clouddn.com/public/resource/mysql/mysql-tuning-4-explain-filesort.png)

就想我们要根据业务具体问题具体分析``using filesort``是否需要优化一样，这个sql其实也应该再根据业务场景具体分析。

这个sql想查用户浏览商品的历史记录，可以看到每次都只查10条就行。这样一个需求为什么这个用户从执行计划看会有3万多行数据呢？
很显然，从业务上我们应该控制当用户浏览商品时向这个表加数据的同时还需要删除之前加的数据，让这个用户在这个表的数据留存尽量的少，这样也不会存在``using filesort``的问题。


## 如何根据执行计划进行索引优化
我认为主要看三个指标

一个是Extra里面using的情况，比如using filesort，using intersect，using temporary这种就需要关注

一个是扫描行Rows，一个查询扫描十几万行，几十万行肯定值得优化

一个是看type，命中了什么类型的索引

当然这些指标的背后一定**不能脱离业务凭空分析优化**，要结合业务分析优化。

具体用到的基础知识可以查看我之前的文档[Mysql调优总结](http://xcoder.me/2017-06/tuning/Mysql%E5%8A%A0%E7%B4%A2%E5%BC%95%E8%B0%83%E4%BC%98%E6%80%BB%E7%BB%93/)

## SQL查询优化经验总结

* 应尽量避免在where 子句中对字段进行null 值判断，否则将导致引擎放弃使用索引而进行全表扫描
    如：``select id from t where num is null``可以在num上设置默认值0，确保表中num列没有null值，然后这样查询：``select id from t where num=0``
* 应尽量避免在 where 子句中使用!=或<>操作符，否则引擎将放弃使用索引而进行全表扫描。

* 应尽量避免在 where 子句中使用or来连接条件，否则将导致引擎放弃使用索引而进行全表扫描
    如：``select id from t where num=10 or num=20``可以这样查询：``select id from t where num=10 union all select id from t where num=20``
* in 和 not in 也要慎用，否则会导致全表扫描.
    如：``select id from t where num in(1,2,3)`` 对于连续的数值，能用between就不要用 in 了：``select id from t where num between 1 and 3``.
    考虑用exist和not exist替代in 和not in
* MySQL在5.6.24中支持了InnoDB的全文检索（之前已经支持MyISAM的全文检索），对于频繁的like请求考虑使用全文检索来提高效率。

* 如果在where子句中使用参数，也会导致全表扫描。
   因为SQL只有在运行时才会解析局部变量，但优化程序不能将访问计划的选择推迟到运行时；它必须在编译时进行选择。然 而，如果在编译时建立访问计划，变量的值还是未知的，因而无法作为索引选择的输入项。如下面语句将进行全表扫描：``select id from t where num=@num``可以改为强制查询使用索引：``select id from t with(index(索引名)) where num=@num``

* 应尽量避免在 where 子句中对字段进行表达式/函数等操作，这将导致引擎放弃使用索引而进行全表扫描
  如：select id from t where num/2=100应改为:select id from t where num=100*2。
      select id from t where date_format(时间字段名,'%Y-%m-%d')='2017-01-01' 应改为 select id from t where 时间字段名=date(2017-01-01)
      select id from t where substring(name,1,3)='abc' ，name以abc开头的id应改为:select id from t where name like 'abc%'
      
* 在使用索引字段作为条件时，如果该索引是复合索引，那么必须使用到该索引中的第一个字段作为条件时才能保证系统使用该索引，否则该索引将不会被使用，并且应尽可能的让字段顺序与索引顺序相一致。

* 尽量使用数字型字段，若只含数值信息的字段尽量不要设计为字符型，这会降低查询和连接的性能，并会增加存储开销。这是因为引擎在处理查询和连接时会逐个比较字符串中每一个字符，而对于数字型而言只需要比较一次就够了。

* 临时表/游标问题
    尽量使用表变量来代替临时表。如果表变量包含大量数据，请注意索引非常有限（只有主键索引）。
    避免频繁创建和删除临时表，以减少系统表资源的消耗。临时表并不是不可使用，适当地使用它们可以使某些例程更有效，例如，当需要重复引用大型表或常用表中的某个数据集时。但是，对于一次性事件，最好使用导出表。
    在新建临时表时，如果一次性插入数据量很大，那么可以使用 select into 代替 create table，避免造成大量 log ，以提高速度；如果数据量不大，为了缓和系统表的资源，应先create table，然后insert。
    如果使用到了临时表，在存储过程的最后务必将所有的临时表显式删除，先 truncate table ，然后 drop table ，这样可以避免系统表的较长时间锁定。
    尽量避免使用游标，因为游标的效率较差，如果游标操作的数据超过1万行，那么就应该考虑改写。
    使用基于游标的方法或临时表方法之前，应先寻找基于集的解决方案来解决问题，基于集的方法通常更有效。
    与临时表一样，游标并不是不可使 用。对小型数据集使用 FAST_FORWARD 游标通常要优于其他逐行处理方法，尤其是在必须引用几个表才能获得所需的数据时。在结果集中包括“合计”的例程通常要比使用游标执行的速度快。如果开发时 间允许，基于游标的方法和基于集的方法都可以尝试一下，看哪一种方法的效果更好。

