
---
title: centos7上firewalld防火墙配置
date: 2017-06-08 09:40:56
categories:
    - build
tags:
    - centos7
    - firewalld
    - 防火墙
---
## firewalld介绍
firewalld 提供了支持网络/防火墙区域(zone)定义网络链接以及接口安全等级的动态防火墙管理工具。

```markdown
我们首先需要弄明白的第一个问题是到底什么是动态防火墙。为了解答这个问题，我们先来回忆一下 iptables service 管理防火墙规则的模式：用户将新的防火墙规则添加进 /etc/sysconfig/iptables 配置文件当中，再执行命令 service iptables reload 使变更的规则生效。在这整个过程的背后，iptables service 首先对旧的防火墙规则进行了清空，然后重新完整地加载所有新的防火墙规则，而如果配置了需要 reload 内核模块的话，过程背后还会包含卸载和重新加载内核模块的动作，而不幸的是，这个动作很可能对运行中的系统产生额外的不良影响，特别是在网络非常繁忙的系统中。

如果我们把这种哪怕只修改一条规则也要进行所有规则的重新载入的模式称为静态防火墙的话，那么 firewalld 所提供的模式就可以叫做动态防火墙，它的出现就是为了解决这一问题，任何规则的变更都不需要对整个防火墙规则列表进行重新加载，只需要将变更部分保存并更新到运行中的 iptables 即可。

这里有必要说明一下 firewalld 和 iptables 之间的关系， firewalld 提供了一个 daemon 和 service，还有命令行和图形界面配置工具，它仅仅是替代了 iptables service 部分，其底层还是使用 iptables 作为防火墙规则管理入口。firewalld 使用 python 语言开发，在新版本中已经计划使用 c++ 重写 daemon 部分。
```
<!--more-->
## firewalld区域
firewalld将网卡对应到不同的区域（zone），zone 默认共有9个，block dmz drop external home internal public trusted work.
```markdown
* drop（丢弃）
任何接收的网络数据包都被丢弃，没有任何回复。仅能有发送出去的网络连接。
* block（限制）
任何接收的网络连接都被 IPv4 的 icmp-host-prohibited 信息和 IPv6 的 icmp6-adm-prohibited 信息所拒绝。
* public（公共）
在公共区域内使用，不能相信网络内的其他计算机不会对您的计算机造成危害，只能接收经过选取的连接。
* external（外部）
特别是为路由器启用了伪装功能的外部网。您不能信任来自网络的其他计算，不能相信它们不会对您的计算机造成危害，只能接收经过选择的连接。
* dmz（非军事区）
用于您的非军事区内的电脑，此区域内可公开访问，可以有限地进入您的内部网络，仅仅接收经过选择的连接。
* work（工作）
用于工作区。您可以基本相信网络内的其他电脑不会危害您的电脑。仅仅接收经过选择的连接。
* home（家庭）
用于家庭网络。您可以基本信任网络内的其他计算机不会危害您的计算机。仅仅接收经过选择的连接。
* internal（内部）
用于内部网络。您可以基本上信任网络内的其他计算机不会威胁您的计算机。仅仅接受经过选择的连接。
* trusted（信任）
可接受所有的网络连接。
指定其中一个区域为默认区域是可行的。当接口连接加入了 NetworkManager，它们就被分配为默认区域。安装时，firewalld 里的默认区域被设定为公共区域。
```
## firewalld服务
```markdown
在 /usr/lib/firewalld/services/ 目录中，还保存了另外一类配置文件，每个文件对应一项具体的网络服务，如 ssh 服务等.
与之对应的配置文件中记录了各项服务所使用的 tcp/udp 端口，在最新版本的 firewalld 中默认已经定义了 70+ 种服务供我们使用.
当默认提供的服务不够用或者需要自定义某项服务的端口时，我们需要将 service 配置文件放置在 /etc/firewalld/services/ 目录中.
service 配置的好处显而易见:
第一，通过服务名字来管理规则更加人性化，
第二，通过服务来组织端口分组的模式更加高效，如果一个服务使用了若干个网络端口，则服务的配置文件就相当于提供了到这些端口的规则管理的批量操作快捷方式。
```
## firewalld配置方式
firewalld的配置文件以xml格式为主（主配置文件firewalld.conf例外），他们有两个存储位置

``/etc/firewalld/``

``/usr/lib/firewalld/``

使用时的规则是这样的：当需要一个文件时firewalld会首先到第一个目录中去查找，如果可以找到，那么就直接使用，否则会继续到第二个目录中查找。

firewalld的这种配置文件结构的主要作用是这样的：在第二个目录中存放的是firewalld给提供的通用配置文件，如果我们想修改配置， 那么可以copy一份到第一个目录中，然后再进行修改。这么做有两个好处：首先我们日后可以非常清晰地看到都有哪些文件是我们自己创建或者修改过的，其 次，如果想恢复firewalld给提供的默认配置，只需要将自己在第一个目录中的配置文件删除即可

## firewalld配置
查看firewalld服务状态
``systemctl status firewalld.service``
启动firewalld服务
``systemctl start firewalld.service``
停止firewalld服务
``systemctl stop firewalld.service``
禁用firewalld服务
``systemctl disable firewalld.service``
启用firewalld服务
``systemctl enable firewalld.service``
如果是running/active可以通过下面的命令查看运行的服务
``firewall-cmd --get-services``
查看当前zone启动的服务
``firewall-cmd --list-services``
添加配置
``firewall-cmd --add-port=11200/tcp --permanent``
也可以``cat /etc/firewalld/zones/public.xml``
