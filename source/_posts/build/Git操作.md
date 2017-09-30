
---
title: 开发场景中的一些Git操作
date: 2017-08-16 21:40:56
categories:
    - build
tags: 
    - GIT
---

## Git pull 强制覆盖本地文件
<!--more-->
```angular2html
git fetch --all  
git reset --hard origin/master 
git pull
```

## Git 强制回退版本

1.``git log``找到想回退的版本

```angularjs
commit a672a60813caafbf8a62d47ec581f391c22e58c1
Author: xxxxxx
Date:   Fri Sep 29 23:05:48 2017 +0800

    * fix bugs

commit 5815d0bd4112e103fa7f0c2d316f872ec5d53800
Author: xxxxxx
Date:   Fri Sep 29 22:57:33 2017 +0800

    * update

commit 13e63dad99f776650a324994642fb6a078176d42
Author: xxxxxx
Date:   Fri Sep 29 19:20:31 2017 +0800

    * update

```
2.回退到希望回退的版本
```angularjs
git checkout master
git fetch
git pull origin master
git reset --hard 13e63dad99f776650a324994642fb6a078176d42
git push origin master --force
```
