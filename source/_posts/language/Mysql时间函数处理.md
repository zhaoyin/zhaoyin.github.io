---
title: Mysql时间函数处理总结
date: 2017-06-23 16:35:20
reward: true
categories:
    - language
tags:
    - mysql
    - date
---

* 今天
```
select * from 表名 where to_days(时间字段名) = to_days(now());
```
* 昨天
```markdown
SELECT * FROM 表名 WHERE TO_DAYS( NOW( ) ) - TO_DAYS( 时间字段名) <= 1;
```
* 本周
```markdown
SELECT * FROM  表名 WHERE YEARWEEK( date_format(时间字段名,'%Y-%m-%d' ) ) = YEARWEEK( now( ) ) ;
```
* 本月
```markdown
SELECT * FROM  表名 WHERE DATE_FORMAT( 时间字段名, '%Y%m' ) = DATE_FORMAT( CURDATE( ) , '%Y%m' ) ;
```
* 上一个月
```markdown
SELECT * FROM  表名 WHERE PERIOD_DIFF(date_format(now(),'%Y%m'),date_format(时间字段名,'%Y%m') =1;
```
* 本年
```markdown
SELECT * FROM 表名 WHERE YEAR(时间字段名 ) = YEAR( NOW( ) ) ;
```
* 查看当天日期
```markdown
select current_date();
```
* 查看当天时间
```markdown
select current_time();
```
* 查看当天时间日期
```markdown
select current_timestamp();
```
* 查询7天的记录
```markdown
SELECT * FROM 表名 where DATE_SUB(CURDATE(), INTERVAL 7 DAY) <= date(时间字段名);
```
* 查询近30天的记录
```markdown
SELECT * FROM 表名 where DATE_SUB(CURDATE(), INTERVAL 30 DAY) <= date(时间字段名);
```
* 查询本季度数据
```markdown
select * from 表名 where QUARTER(时间字段名)=QUARTER(now());
```
* 查询上季度数据
```markdown
select * from 表名 where QUARTER(时间字段名)=QUARTER(DATE_SUB(now(),interval 1 QUARTER));
```
* 查询本年数据
```markdown
select * from 表名  where YEAR(时间字段名)=YEAR(NOW());
```
* 查询上年数据
```markdown
select * from 表名 where year(时间字段名)=year(date_sub(now(),interval 1 year));
```
* 查询上周的数据
```markdown
SELECT * FROM 表名 WHERE YEARWEEK(date_format(时间字段名,'%Y-%m-%d')) = YEARWEEK(now())-1;
```
* 查询当前月份的数据
```markdown
select * from 表名   where date_format(时间字段名,'%Y-%m')=date_format(now(),'%Y-%m');
```
* 查询距离当前现在6个月的数据
```markdown
select * from 表明 where 时间字段名 between date_sub(now(),interval 6 month) and now();
```

* date_format函数可用的标志符
```markdown
%M 月名字(January……December) 
%W 星期名字(Sunday……Saturday) 
%D 有英语前缀的月份的日期(1st, 2nd, 3rd, 等等。） 
%Y 年, 数字, 4 位 
%y 年, 数字, 2 位 
%a 缩写的星期名字(Sun……Sat) 
%d 月份中的天数, 数字(00……31) 
%e 月份中的天数, 数字(0……31) 
%m 月, 数字(01……12) 
%c 月, 数字(1……12) 
%b 缩写的月份名字(Jan……Dec) 
%j 一年中的天数(001……366) 
%H 小时(00……23) 
%k 小时(0……23) 
%h 小时(01……12) 
%I 小时(01……12) 
%l 小时(1……12) 
%i 分钟, 数字(00……59) 
%r 时间,12 小时(hh:mm:ss [AP]M) 
%T 时间,24 小时(hh:mm:ss) 
%S 秒(00……59) 
%s 秒(00……59) 
%p AM或PM 
%w 一个星期中的天数(0=Sunday ……6=Saturday ） 
%U 星期(0……52), 这里星期天是星期的第一天 
%u 星期(0……52), 这里星期一是星期的第一天 
%% 字符%
```
　
