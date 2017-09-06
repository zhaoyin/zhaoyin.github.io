
---
title: 修改ssh默认端口
date: 2017-06-21 22:12:25
reward: true
categories:
    - build
tags:
    - 运维
    - ssh
---

* ``vi /etc/ssh/sshd_config``

<!--more-->

```angularjs
# If you want to change the port on a SELinux system, you have to tell
# SELinux about this change.
# semanage port -a -t ssh_port_t -p tcp #PORTNUMBER
# 去掉下面的#号并修改22为其他端口号
Port 22
#ListenAddress 0.0.0.0
#ListenAddress ::
```
* 重启sshd服务
``service sshd restart``
或者``systemctl restart sshd.service``

使用``systemctl status sshd.service``看一下服务是否正常重启

**新启动一个终端**使用``ssh xxx@xx.xx.xx.xx -pxxx``试一下是否可用，如果可用**再退出当前终端实例**。

若防火墙开启，需修改防火墙设置