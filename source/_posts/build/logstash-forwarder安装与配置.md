
---
title: logstash-forwarder安装与配置
date: 2017-06-16 00:12:25
reward: true
categories:
    - build
tags:
    - 运维
    - logstash-forwarder
---

## logstash-forwarder 安装
首先，我们需要安装 logstash-forwarder 软件。官方都已经提供了软件仓库可用。在 Redhat 机器上只需要添加一个 /etc/yum.repos.d/logstash-forwarder.repo，内容如下：
```markdown
[logstash-forwarder]
name=logstash-forwarder
baseurl=http://packages.elasticsearch.org/logstash-forwarder/centos
gpgcheck=1
gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch
enabled=1
```
然后运行安装命令即可：
```markdown
sudo yum install -y logstash-forwarder
```

## logstash-forwarder 配置
   
logstash-forwarder 的配置文件是纯 JSON 格式。因为其轻量级的设计目的，所以可配置项很少。下面是一个 /etc/logstash-forwarder 配置示例：
```markdown
{
  "network": {
    "servers": [ "10.18.10.2:5000" ],
      "timeout": 15,
      "ssl ca" : "/etc/pki/tls/certs/logstash-forwarder.crt"
      "ssl key": "/etc/pki/tls/private/logstash-forwarder.key"
  },
  "files": [
    {
      "paths": [
        "/var/log/message",
      "/var/log/secure"
        ],
      "fields": { "type": "syslog" }
    },{
          "paths": [
            "/var/log/nginx/error.log"
          ],
          "fields": { "type": "nginxerror" },
          "fields": { "app": "test" },
          "fields": { "ip": "172.16.0.1"}
        }, {
          "paths":  [ "/var/log/secure" ],
          "fields": {"type": "secure"},
          "fields": {"app": "test"},
          "fields": {"ip":"10.1.2.3"}
         }
  ]
}
```

我们已完成了配置，当 sudo service logstash-forwarder start 之后，你就可以在 kibana 上看到你的日志了

## logstash-forwarder 配置说明

主要包括下面几个可用配置项：
* network.servers: 用来指定远端(即 logstash indexer 角色)服务器的 IP 地址和端口。这里可以写数组，但是 logstash-forwarder 只会随机选一台作为对端发送数据，一直到对端故障，才会重选其他服务器。
* network.ssl*: 网络交互中使用的 SSL 证书路径。
* files.*.paths: 读取的文件路径。 logstash-forwarder 只支持两种输入，一种就是示例中用的文件方式，和 logstash 一样也支持 glob 路径，即 "/var/log/*.log" 这样的写法；一种是标准输入，写法为 "paths": [ "-" ]
* files.*.fields: 给每条日志添加的固定字段，相当于 logstash 里的 add_field 参数。 注意示例中添加的是 type 字段。在 logstash-forwarder 里添加的字段是优先于 LogStash::Inputs::Lumberjack 配置里定义的字段的。所以，在本例中，即便你在 indexer 上定义 type 为 "anything"。事件的实际 type 依然是这里添加的 "syslog"。这也意味着，你在 indexer 上如果做后续判断，应该是这样：

```markdown
filter {
  if [type] == "syslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
    }
  }
}
```
