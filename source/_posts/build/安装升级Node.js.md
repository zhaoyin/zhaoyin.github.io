
---
title: 安装升级Node.js
date: 2017-05-20 16:40:56
tags:
---

推荐使用[nodesource-nodejs-and-iojs-binary-distributions](https://github.com/nodesource/distributions)提供的方式安装
对于**CentOS**系统，可以用下面的命令来快速安装最新的Node.js

```
curl -sL https://deb.nodesource.com/setup_7.x | bash -
yum -y install nodejs
```

## 升级Node

### 全局安装n模块

[n模块](https://github.com/tj/n)是tj大神维护的一个node模块，用来做node多版本管理用的.
用它来升级node很方便，一行代码搞定全局安装n模块

```
npm install -g n
停止node进程
n stable
n latest
n 7.8.0
```

n stable是安装最新Node稳定版，n latest是安装最新版，n 版本号，安装指定Node版本

**如果更新安装过程中失败，提示类似以下信息**

```
cp: cannot stat ‘/usr/local/n/versions/node/7.10.0/lib’: No such file or directory
cp: cannot stat ‘/usr/local/n/versions/node/7.10.0/include’: No such file or directory
cp: cannot stat ‘/usr/local/n/versions/node/7.10.0/share’: No such file or directory
```

此时请输入
```
n
```
会列出刚刚试图安装并且失败的版本号，这里是7.10.0，然后执行

```
n - 7.10.0
```
删除此失败版本

再重复上面的动作

## 升级PM2和NPM

因为会用到PM2，之前PM2是全局安装的

```
npm install pm2 -g
所以升级PM2和NPM很简单，只需要
npm update -g
```

```
npm -v          #显示版本，检查npm 是否正确安装。
npm install express   #安装express模块
npm install -g express  #全局安装express模块 
npm list         #列出已安装模块 
npm show express     #显示模块详情
npm update        #升级当前目录下的项目的所有模块
npm update express    #升级当前目录下的项目的指定模块
npm update -g express  #升级全局安装的express模块
npm uninstall express  #删除指定的模块
```

其他相关命令