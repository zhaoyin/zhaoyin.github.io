
---
title: POI高效操作Excel
date: 2017-05-20 16:40:56
tags:
    - POI
    - Excel
    - 高效
---

POI是apache下一个进行office相关格式文件的读写开源工具。
POI提供两种读写API模型：事件模型（eventmodel）和用户模型（usermodel）。

## 事件模型

基于流（stream）的方式实现，使用sax(simple api for XML)模型进行xml内容解析，对CPU和内存的消耗小，但使用复杂，且无法进行写操作。

## 用户模型

基于内存树（memory tree）的方式实现，使用DOM进行excel的解析，对CPU和内存的消耗大，但能够以面向对象的方式进行操作，使用简便，可读可写。

对于2007版excel，POI还提供了可缓存流的用户模型API，使用滑动窗口（sliding window）的方法控制缓存区的大小，实现对海量数据的读写。

![POI操作性能对比](http://poi.apache.org/resources/images/ss-features.png)

很明显，2007版excel在读写方面POI做的更好，2003版在海量数据写入方面支持不够，所以在设计系统的导入、导出功能时，应该优先考虑2007版。

同时，导出功能需要最终写文档到Excel中，使用2007及以上版本的SXSSF对象来操作写Excel性能比HSSF高很多。


## 读取XLSX例子

[读取XLSX例子](https://myjeeva.com/read-excel-through-java-using-xssf-and-sax-apache-poi.html)

[读取xlsx例子](https://github.com/jeevatkm/excelReader)

