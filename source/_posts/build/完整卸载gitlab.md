
---
title: 完整卸载GitLab
date: 2017-09-30 16:40:56
reward: true
categories:
    - build
tags:
    - GitLab
---

## 停止gitlab

``gitlab-ctl stop``

<!--more-->

## 卸载gitlab（注意这里写的是gitlab-ce）

``rpm -e gitlab-ce``

## 查看gitlab进程

``ps aux | grep gitlab``

## 杀掉gitlab进程

如果是默认安装启动目录应该是/opt/gitlab/service(带很多......的进程)

kill -9 18777

杀掉后，再``ps aux | grep gitlab``确认一遍，还有没有gitlab的进程

## 删除所有包含gitlab文件

``find / -name gitlab | xargs rm -rf``