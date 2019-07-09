
---
title: IntelliJ IDEA使用总结
date: 2017-05-26 20:50:56
reward: true
categories:
    - tools
tags:
    - IntelliJ Idea
    - IDE
---

今天中午收到一公众号推送说Eclipse 4.7 M7里程碑版发布,Oxygen，氧气啊，作为一个遇到新版本就闲的蛋疼的二逼程序员，我果断下载安装并替换了本机的Eclipse Mars，很快下载完后安装升级原有设置，导入项目。好了，撸起袖子开始干活，哪不对啊？右键怎么没有maven菜单了？项目启动的Jetty设置呢？我要启动项目啊。也许是升级了版本，这些东西都需要重新适配吧，没事，谁让咱二逼呢，咱再来一遍就是了，嗯，咱打开熟悉的Eclipse MarkerPlace去搜索一下这两个玩意弄上不就完了。
  然后，没有然后了，一个小时过去了我依然没有找到应用市场，终于我在熟悉的stackoverflow上找到了这货:
  <!--more-->
  ![stackoverflow-eclipse-4.7-M7](http://static.xcoder.ren/public/images/eclipse-Oxygen-m7.png)

```
Eclipse Oxygen is still under development and won't be finally released until June 2017. Many additions may not have been tested with Oxygen at this point. Eclipse Neon.3 is the current stable release. 
```
我原来安装的版本就是最新的。

索性就不用了，直接换最近很火的JetBrains那货的IDE吧。

说多了都是泪，言归正传，学习一下IntelliJ IDEA的使用。

装上之后我就激动了，谁用谁知道。

Eclipse有的咱就不说了，说点实用的

## 查找
* Alt+F12打开终端（不用切换窗口谁用谁知道）
* 双击shift 
    在项目的所有目录查找，就是你想看到你不想看到的和你没想过你能看到的都给你找出来
* command+f 
    当前文件查找特定内容
* command+shift+f
    当前项目查找包含特定内容的文件
* command+n 
    java类上是查找，其他文件或者包上是新建菜单
* command+shift+n
    查找文件
* command+e 
    最近的文件
* alt+F7
    非常非常频繁使用的一个快捷键，可以帮你找到你的函数或者变量或者类的所有引用到的地方
## 显示
* command+M
    最小化

## 编辑
* shift+enter
    另起一行
* command+r
    当前文件替换特定内容
* command+shift+r
    当前项目替换特定内容
* shift+F6
    非常非常省心省力的一个快捷键，可以重命名你的类、方法、变量等等，而且这个重命名甚至可以选择替换掉注释中的内容，当然也可以重命名文件
* command+d
    复制当前行到下一行
* command+x
    剪切当前行
* command+c \ command+v 
    不讲都知道
* command+z
    撤销
* command+shift+z
    取消撤销
* alt+enter
    等同于Eclipse中用鼠标点到红色波浪线上出现的浮窗效果
    如果有引用的类没导入也使用此快捷键
    各种checkstyle
* command+alt+L
    自动格式化代码
* command+shift+U
  大小写转化--命令static常量很有用 
* ctrl+alt+O
    去除没有用到的import
* command+F1
    各种建议
    ![优化建议](http://static.xcoder.ren/public/images/%E4%BC%98%E5%8C%96%E5%BB%BA%E8%AE%AE.png)
* command+F12
    在Eclipse中使用很频繁的ctrl+o对应的快捷键就是command+F12
参考了这位小哥[码农往事](http://www.blogjava.net/rockblue1988/archive/2014/10/24/418994.html)的文章，在此谢过！

