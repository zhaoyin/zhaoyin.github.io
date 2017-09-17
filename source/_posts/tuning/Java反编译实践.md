
---
title: Java反编译实践
date: 2017-09-17 12:20:46
categories:
    - tuning
tags: 
    - 反编译
    - JAVA
---

## 反编译jar并重新打包

因为一个项目需要，需要反编译一个jar的一个类文件，但是没有源码，所以考虑使用反编译工具来反编译这个类文件，修改后编译再打包成jar文件

* 使用反编译工具反编译jar
* 修改相应的反编译后的JAVA文件
* 设置依赖，重新编译JAVA文件为class文件
    可以通过eclipse和idea等IDE建立一个java工程，设置JAVA依赖，然后执行Build或者Rebuild单个java文件或者整个反编译并修改后的java工程
    如果依赖较少或者比较简单的反编译可以直接使用``javac -cp ``命令指明.java文件里import的类的位置
```angularjs
用法: javac <options> <source files>
其中, 可能的选项包括:
  -g                         生成所有调试信息
  -g:none                    不生成任何调试信息
  -g:{lines,vars,source}     只生成某些调试信息
  -nowarn                    不生成任何警告
  -verbose                   输出有关编译器正在执行的操作的消息
  -deprecation               输出使用已过时的 API 的源位置
  -classpath <路径>            指定查找用户类文件和注释处理程序的位置
  -cp <路径>                   指定查找用户类文件和注释处理程序的位置
  -sourcepath <路径>           指定查找输入源文件的位置
  -bootclasspath <路径>        覆盖引导类文件的位置
  -extdirs <目录>              覆盖所安装扩展的位置
  -endorseddirs <目录>         覆盖签名的标准路径的位置
  -proc:{none,only}          控制是否执行注释处理和/或编译。
  -processor <class1>[,<class2>,<class3>...] 要运行的注释处理程序的名称; 绕过默认的搜索进程
  -processorpath <路径>        指定查找注释处理程序的位置
  -parameters                生成元数据以用于方法参数的反射
  -d <目录>                    指定放置生成的类文件的位置
  -s <目录>                    指定放置生成的源文件的位置
  -h <目录>                    指定放置生成的本机标头文件的位置
  -implicit:{none,class}     指定是否为隐式引用文件生成类文件
  -encoding <编码>             指定源文件使用的字符编码
  -source <发行版>              提供与指定发行版的源兼容性
  -target <发行版>              生成特定 VM 版本的类文件
  -profile <配置文件>            请确保使用的 API 在指定的配置文件中可用
  -version                   版本信息
  -help                      输出标准选项的提要
  -A关键字[=值]                  传递给注释处理程序的选项
  -X                         输出非标准选项的提要
  -J<标记>                     直接将 <标记> 传递给运行时系统
  -Werror                    出现警告时终止编译
  @<文件名>                     从文件读取选项和文件名
```
* jar打包
    WINRAR打开jar用新修改的class文件替换掉之前的class文件
　　我们可以使用jar命令进行打包（进入目录后执行jar -cvf xxxx.jar .）也可以使用winrar工具进行打包。使用winrar工具打包时，要注重选择压缩文件格式为zip，并将生成的压缩包文件的后缀名设置为jar。
```angularjs
用法: jar {ctxui}[vfmn0PMe] [jar-file] [manifest-file] [entry-point] [-C dir] files ...
选项:
    -c  创建新档案
    -t  列出档案目录
    -x  从档案中提取指定的 (或所有) 文件
    -u  更新现有档案
    -v  在标准输出中生成详细输出
    -f  指定档案文件名
    -m  包含指定清单文件中的清单信息
    -n  创建新档案后执行 Pack200 规范化
    -e  为捆绑到可执行 jar 文件的独立应用程序
        指定应用程序入口点
    -0  仅存储; 不使用任何 ZIP 压缩
    -P  保留文件名中的前导 '/' (绝对路径) 和 ".." (父目录) 组件
    -M  不创建条目的清单文件
    -i  为指定的 jar 文件生成索引信息
    -C  更改为指定的目录并包含以下文件
如果任何文件为目录, 则对其进行递归处理。
清单文件名, 档案文件名和入口点名称的指定顺序
与 'm', 'f' 和 'e' 标记的指定顺序相同。

示例 1: 将两个类文件归档到一个名为 classes.jar 的档案中: 
       jar cvf classes.jar Foo.class Bar.class 
示例 2: 使用现有的清单文件 'mymanifest' 并
           将 foo/ 目录中的所有文件归档到 'classes.jar' 中: 
       jar cvfm classes.jar mymanifest -C foo/ .
```
<!--more-->

## 反编译工具
### [JAD](https://varaneckas.com/jad/)
### [JD-GUI](http://jd.benow.ca/)

前面两个工具反编译后你可能得到下面的结果
```angularjs
/*     */   /* Error */
/*     */   public static int getColumnWidth(String accountId, String year, int cCNum, String org_accountId)
/*     */   {
/*     */     // Byte code:
/*     */     //   0: aconst_null
/*     */     //   1: astore 4
/*     */     //   3: aconst_null
/*     */     //   4: astore 5
/*     */     //   6: new 631	com/seeyon/apps/eipas/common/UFConnectionPool
/*     */     //   9: dup
/*     */     //   10: invokespecial 633	com/seeyon/apps/eipas/common/UFConnectionPool:<init>	()V
/*     */     //   13: aload_3
/*     */     //   14: invokevirtual 634	com/seeyon/apps/eipas/common/UFConnectionPool:getConnectionUF	(Ljava/lang/String;)Ljava/sql/Connection;
..............
```
[为什么Java反编译后带有汇编代码?](https://www.zhihu.com/question/50140866)
### [CRF](http://www.benf.org/other/cfr/index.html)
``java -jar cfr_0_122.jar xxxx.class``
``java -jar cfr_0_122.jar xxx.jar --outputDir /tmp/xxxx``
```angularjs
➜  Downloads git:(master) ✗ java -jar cfr_0_122.jar --help
CFR 0_122

   --aexagg                         (boolean) 
   --aggressivesizethreshold        (int >= 0)  default: 15000
   --allowcorrecting                (boolean)  default: true
   --analyseas                      (One of [JAR, WAR, CLASS]) 
   --arrayiter                      (boolean)  default: true if class file from version 49.0 (Java 5) or greater
   --caseinsensitivefs              (boolean)  default: false
   --clobber                        (boolean) 
   --collectioniter                 (boolean)  default: true if class file from version 49.0 (Java 5) or greater
   --commentmonitors                (boolean)  default: false
   --comments                       (boolean)  default: true
   --decodeenumswitch               (boolean)  default: true if class file from version 49.0 (Java 5) or greater
   --decodefinally                  (boolean)  default: true
   --decodelambdas                  (boolean)  default: true if class file from version 52.0 (Java 8) or greater
   --decodestringswitch             (boolean)  default: true if class file from version 51.0 (Java 7) or greater
   --dumpclasspath                  (boolean)  default: false
   --eclipse                        (boolean)  default: true
   --elidescala                     (boolean)  default: false
   --extraclasspath                 (string) 
   --forcecondpropagate             (boolean) 
   --forceexceptionprune            (boolean) 
   --forcereturningifs              (boolean) 
   --forcetopsort                   (boolean) 
   --forcetopsortaggress            (boolean) 
   --forloopaggcapture              (boolean) 
   --hidebridgemethods              (boolean)  default: true
   --hidelangimports                (boolean)  default: true
   --hidelongstrings                (boolean)  default: false
   --hideutf                        (boolean)  default: true
   --innerclasses                   (boolean)  default: true
   --j14classobj                    (boolean)  default: false if class file from version 49.0 (Java 5) or greater
   --jarfilter                      (string) 
   --labelledblocks                 (boolean)  default: true
   --lenient                        (boolean)  default: false
   --liftconstructorinit            (boolean)  default: true
   --outputdir                      (string) 
   --outputpath                     (string) 
   --override                       (boolean)  default: true if class file from version 50.0 (Java 6) or greater
   --pullcodecase                   (boolean)  default: false
   --recover                        (boolean)  default: true
   --recovertypeclash               (boolean) 
   --recovertypehints               (boolean) 
   --removebadgenerics              (boolean)  default: true
   --removeboilerplate              (boolean)  default: true
   --removedeadmethods              (boolean)  default: true
   --removeinnerclasssynthetics     (boolean)  default: true
   --rename                         (boolean)  default: false
   --renamedupmembers              
   --renameenumidents              
   --renameillegalidents           
   --renamesmallmembers             (int >= 0)  default: 0
   --showinferrable                 (boolean)  default: false if class file from version 51.0 (Java 7) or greater
   --showops                        (int >= 0)  default: 0
   --showversion                    (boolean)  default: true
   --silent                         (boolean)  default: false
   --stringbuffer                   (boolean)  default: false if class file from version 49.0 (Java 5) or greater
   --stringbuilder                  (boolean)  default: true if class file from version 49.0 (Java 5) or greater
   --sugarasserts                   (boolean)  default: true
   --sugarboxing                    (boolean)  default: true
   --sugarenums                     (boolean)  default: true if class file from version 49.0 (Java 5) or greater
   --tidymonitors                   (boolean)  default: true
   --help                           (string) 

Please specify '--help optionname' for specifics, eg
   --help pullcodecase

```
### [Procyon](https://bitbucket.org/mstrobel/procyon)

[How to User](https://bitbucket.org/mstrobel/procyon/wiki/Java%20Decompiler)

## 扩展阅读
[Java反编译器剖析（上）](http://www.importnew.com/9155.html)
[Java反编译器剖析（中）](http://www.importnew.com/9206.html)
[Java反编译器剖析（下）](http://www.importnew.com/9248.html)
[如何理解ByteCode、IL、汇编等底层语言与上层语言的对应关系？ - RednaxelaFX 的回答](https://www.zhihu.com/question/27831730/answer/38266643)
