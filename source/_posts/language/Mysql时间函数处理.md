---
title: 值得收藏的Mysql时间处理
date: 2017-06-23 16:35:20
reward: true
categories:
    - language
tags:
    - MySQL
---

* 今天
```markdown
select * from 表名 where to_days(时间字段名) = to_days(now());
```
* 昨天
```markdown
select * from 表名 where to_days(now()) - to_days(时间字段名)<=1;
```
* 本周
```markdown
select * from  表名 where yearweek(date_format(时间字段名,'%Y-%m-%d')) = yearweek(now());
```
* 本月
```markdown
select * from  表名 where date_format(时间字段名,'%Y%m') = date_format(curdate(),'%Y%m');
```
<!--more-->
* 上一个月
```markdown
select * from  表名 where period_diff(date_format(now(),'%Y%m'),date_format(时间字段名,'%Y%m') =1;
```
* 本年
```markdown
select * from 表名 where year(时间字段名 ) = year(now()) ;
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
select * from 表名 where date_sub(curdate(), interval 7 day) <= date(时间字段名);
```
* 查询近30天的记录
```markdown
select * from 表名 where date_sub(curdate(), interval 30 day) <= date(时间字段名);
```
* 查询本季度数据
```markdown
select * from 表名 where quarter(时间字段名)=quarter(now());
```
* 查询上季度数据
```markdown
select * from 表名 where quarter(时间字段名)=quarter(date_sub(now(),interval 1 quarter));
```
* 查询本年数据
```markdown
select * from 表名  where year(时间字段名)=year(now());
```
* 查询上年数据
```markdown
select * from 表名 where year(时间字段名)=year(date_sub(now(),interval 1 year));
```
* 查询上周的数据
```markdown
select * from 表名 where yearweek(date_format(时间字段名,'%Y-%m-%d')) = yearweek(now())-1;
```
* 查询当前月份的数据
```markdown
select * from 表名   where date_format(时间字段名,'%Y-%m')=date_format(now(),'%Y-%m');
```
* 查询距离当前现在6个月的数据
```markdown
select * from 表名 where 时间字段名 between date_sub(now(),interval 6 month) and now();
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
　
