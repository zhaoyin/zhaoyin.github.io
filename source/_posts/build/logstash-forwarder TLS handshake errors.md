
---
title: logstash-forwarder TLS handshake errors
date: 2017-08-16 00:12:25
reward: true
categories:
    - build
tags:
    - 运维
    - logstash-forwarder
---

```angular2html
2017/08/16 20:23:34.436888 Connecting to [x.x.x.x]:x (x.x.x.x)
2017/08/16 20:23:34.512886 Failed to tls handshake with x.x.x.x x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "serial:13678988782561134340")
```
这个错误说明证书不匹配,签发这个证书的和当前的证书不是一套，更换为正确的证书即可
<!--more-->
``openssl x509 -in logstash-forwarder.crt -noout -text``这个命令在crt文件所在目录下查看可以知道当前这个证书的序列号为13678988782561134340，和正确证书的序列号不一致.

```angular2html
logstash-forwarder[4367]: 2017/08/01 23:24:08.559691 Failed to tls handshake with x.x.x.x x509: certificate has expired or is not yet valid
```
这个错误说明证书已经过期了。通过``openssl x509 -in logstash-forwarder.crt -noout -text``可以看到证书的到期日。需要重新生成新证书.




