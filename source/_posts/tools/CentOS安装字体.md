
---
title: CentOs字体安装
date: 2017-10-26 20:50:56
reward: true
categories:
    - tools
tags:
    - 字体
---

CentOS的字体保存在/usr/share/fonts目录下

可以从Windows机器``C:\Windows\Fonts``拷贝或者网络上下载你想要安装的字体文件（*.ttf文件），然后在``/usr/share/fonts/``目录下新建一个目录用来保存要存放的字体以便管理

也可以从另外的CentOS机器相应的目录下拷贝已有的字体。

修改字体文件的权限，使root用户以外的用户也可以使用
```
cd /usr/share/fonts/xxxx
chmod 755 *.ttf
```

建立字体缓存
```
mkfontscale （如果提示 mkfontscale: command not found，需自行安装 # yum install mkfontscale ）
mkfontdir 
fc-cache -fv （如果提示 fc-cache: command not found，则需要安装# yum install fontconfig ）
```

重启计算机
```
reboot
```