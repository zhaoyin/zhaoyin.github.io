
---
title: Linux启用IPV6并给域名绑定IPV6地址
date: 2017-07-26 22:12:25
reward: true
categories:
    - build
tags:
    - ipv6
---

## 检查IP地址是否支持IPV6

使用``ifconfig``检查服务器是否启用了IPV6的地址

```markdown
[test@xptest tmp]# ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet xx.xx.xx.xx  netmask 255.255.252.0  broadcast x.xx.xxx.x
        ether 01:16:3e:01:15:54  txqueuelen 1000  (Ethernet)
        RX packets 21928745065  bytes 6462210197090 (5.8 TiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 15830590952  bytes 3459604394826 (3.1 TiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet xxx.xxx.xxx.xx  netmask 255.255.252.0  broadcast xx.xx.xxx.xx
        ether 01:16:3e:01:15:5d  txqueuelen 1000  (Ethernet)
        RX packets 480306085  bytes 34374102081 (32.0 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 262358739  bytes 195849334695 (182.3 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        loop  txqueuelen 0  (Local Loopback)
        RX packets 26876964  bytes 18080849599 (16.8 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 26876964  bytes 18080849599 (16.8 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```
<!--more-->
我们发现无论eth0内网网卡还是eth1公网网卡都没有inet6,即该服务器未配置IPV6地址.如下配置了IPV6地址的服务器设置如下:
```markdown
[test@xptest tmp]# ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet xxx.xxx.xxx.xx  netmask 255.255.248.0  broadcast xxx.xxx.xxx.xx
        inet6 xxx::xxx:xxx:xxxx:xxx  prefixlen 64  scopeid 0x20<link>
        ether 00:16:3e:00:0d:b3  txqueuelen 1000  (Ethernet)
        RX packets 3991268931  bytes 1721144871895 (1.5 TiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 2975649437  bytes 614388635278 (572.1 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet xxx.xxx.xxx.xx  netmask 255.255.252.0  broadcast xxx.xxx.xxx.xx
        inet6 xxx.xxx.xxx.xx  prefixlen 64  scopeid 0x20<link>
        ether 00:16:3e:00:0c:b0  txqueuelen 1000  (Ethernet)
        RX packets 614308753  bytes 69972352840 (65.1 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 336801962  bytes 288226081429 (268.4 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

he-ipv6: flags=209<UP,POINTOPOINT,RUNNING,NOARP>  mtu 1480
        inet6 xxx.xxx.xxx.xx  prefixlen 64  scopeid 0x0<global>
        inet6 xxx.xxx.xxx.xx  prefixlen 128  scopeid 0x20<link>
        sit  txqueuelen 0  (IPv6-in-IPv4)
        RX packets 7558  bytes 1036576 (1012.2 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 8416  bytes 823695 (804.3 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 0  (Local Loopback)
        RX packets 674598774  bytes 336590473545 (313.4 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 674598774  bytes 336590473545 (313.4 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

## 开启IPV6

执行``vim /etc/sysctl.conf``并设置如下内容.
```markdown
net.ipv6.conf.all.disable_ipv6=0
net.ipv6.conf.default.disable_ipv6=0
net.ipv6.conf.lo.disable_ipv6=0
```
然后执行 ``/sbin/sysctl -p`` 让参数生效。

执行``vim /etc/modprobe.d/disable_ipv6.conf``

```markdown
alias net-pf-10 off
alias ipv6 on
options ipv6 disable=0
```

执行``vim /etc/sysconfig/network``开启网络设置.


## 添加IPV6隧道

添加ipv6隧道：

### 注册Tunnel broker

https://www.tunnelbroker.net/
注册很容易，就不讲了，注册需要邮箱验证，，gmail、163能收得到认证邮件，qq还是一样收不到

$.创建通道“Create Regular Tunnel”

填写服务器ip以及选择默认的隧道节点，点击Create Tunnel创建。填写ip都，如果出现“IP is a potential tunnel endpoint.”则证明可以添加ipv6隧道，一般隧道节点系统已经默认分配，可以手动选择，大家可以在自己的云服务器上分别ping一下这些ip，选时延低的。

[ipv6配置](http://images2015.cnblogs.com/blog/854365/201703/854365-20170324175157315-1784684826.png)

### 测试IPV6

添加ipv6的dns服务器，在最后添加nameserver 2001:4860:4860::8888,nameserver 2001:4860:4860::8844谷歌的ipv6 dns服务器

### 域名设置

在域名解析中执行``ifconfig 网卡名称``
找到he-ipv6虚拟网卡，找到scope为Global 的ipv6地址，在域名解析服务中配置AAAA记录为上面提到的ipv6地址

