
---
title: TCP命令及故障排查
date: 2017-06-05 21:40:46
categories:
    - tuning
tags: 
    - TCP
---

## linux查看tcp的状态命令
* netstat -nat  查看TCP各个状态的数量
* lsof  -i:port  可以检测到打开套接字的状况
* sar -n SOCK 查看tcp创建的连接数
* tcpdump -iany tcp port 9000 对tcp端口为9000的进行抓包
<!--more-->
## 网络测试常用命令
### ping
检测网络连接的正常与否,主要是测试延时、抖动、丢包率。
但是很多服务器为了防止攻击，一般会关闭对ping的响应。所以ping一般作为测试连通性使用。
ping命令后，会接收到对方发送的回馈信息，其中记录着对方的IP地址和TTL。
TTL是该字段指定IP包被路由器丢弃之前允许通过的最大网段数量。
TTL是IPv4包头的一个8 bit字段。例如IP包在服务器中发送前设置的TTL是64，你使用ping命令后，得到服务器反馈的信息，其中的TTL为56，说明途中一共经过了8道路由器的转发，每经过一个路由，TTL减1。
### traceroute
跟踪数据包到达网络主机所经过的路由工具
traceroute hostname
### pathping
是一个路由跟踪工具，它将 ping 和 tracert 命令的功能与这两个工具所不提供的其他信息结合起来，综合了二者的功能
pathping www.baidu.com
### nslookup
用于解析域名，一般用来检测本机的DNS设置是否配置正确。
### mtr
以结合ping nslookup tracert 来判断网络的相关特性
### tcpdump
tcpdump -iany tcp port 9502
[Linux tcpdump命令详解](http://www.cnblogs.com/ggjucheng/archive/2012/01/14/2322659.html)

## 系统大量TIME_WAIT状态连接的处理
发现系统存在大量TIME_WAIT状态的连接，可以通过调整内核参数解决：``vi /etc/sysctl.conf`` 加入以下内容：
```
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 30
```
然后执行 ``/sbin/sysctl -p`` 让参数生效。
```
net.ipv4.tcp_syncookies = 1 表示开启SYN Cookies。当出现SYN等待队列溢出时，启用cookies来处理，可防范少量SYN攻击，默认为0，表示关闭；
net.ipv4.tcp_tw_reuse = 1 表示开启重用。允许将TIME-WAIT sockets重新用于新的TCP连接，默认为0，表示关闭；
net.ipv4.tcp_tw_recycle = 1 表示开启TCP连接中TIME-WAIT sockets的快速回收，默认为0，表示关闭。
net.ipv4.tcp_fin_timeout 修改系統默认的 TIMEOUT 时间
```
## 以下相关内容值得学习

[TCP连接的状态详解以及故障排查](http://blog.csdn.net/hguisu/article/details/38700899)
[TIME_WAIT引起Cannot assign requested address报错](http://blog.csdn.net/hguisu/article/details/10241519)



