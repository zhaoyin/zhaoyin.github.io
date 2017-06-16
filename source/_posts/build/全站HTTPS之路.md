
---
title: 全站HTTPS之路
date: 2017-06-15 22:12:25
reward: true
categories:
    - build
tags:
    - 运维
    - HTTPS
---

## 什么是HTTPS？
HTTPS（全称：Hyper Text Transfer Protocol over Secure Socket Layer），是以安全为目标的HTTP通道。即HTTP下加入SSL层，HTTPS的安全基础是SSL，因此加密的详细内容就需要SSL。现在它被广泛用于互联网上安全敏感的通讯，例如交易支付等。

采用HTTPS的服务器必须从CA （Certificate Authority）申请一个用于证明服务器用途类型的证书。该证书只有用于对应的服务器的时候，客户端才信任此主机。所以所有的银行系统网站，关键部分应用都是HTTPS的。客户通过信任该证书，从而信任了该主机。其实这样做效率很低，但是银行更侧重安全。这一点对局域网对内提供服务处的服务器没有任何意义。局域网中的服务器，采用的证书不管是自己发布的还是从公众的地方发布的，其客户端都是自己人，所以该局域网中的客户端也就肯定信任该服务器。

## 启用HTTPS
有不少网站只通过HTTPS对外提供服务，但用户在访问某个网站的时候，在浏览器里却往往直接输入网站域名（例如www.example.com），而不是输入完整的URL（例如https://www.example.com），不过浏览器依然能正确的使用HTTPS发起请求。这背后多亏了服务器和浏览器的协作
![强制全站https](http://oqcey66z7.bkt.clouddn.com/public/resource/http-https.png)

以nginx为例配置
```markdown
server{
    listen 80;
    server_name www.example.com;
    rewrite ^(.*)$  https://$host$1 permanent;
}

或者
server{
    listen 80;
    server_name www.example.com;
    return 301 https://www.example.com;
}

```
<!--more-->
nginx的HTTPS配置
```markdown
server {
        #开启 SPDY 和 HTTP2 支持，借助多路复用提升传输性能。
        listen   443  ssl http2 default_server;
        server_name  www.example.com;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;
        ssl on;
        ##crt后缀或者pem后缀为证书公钥文件,key为证书私钥文件，一般证书服务商提供
        ssl_certificate  /usr/nginx/ssl/example.com.crt;
        ssl_certificate_key  /usr/nginx/ssl/example.com.key;
        ssl_session_timeout 5m;
        #不使用SSLv2,SSLv3等不安全协议
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers AESGCM:ALL:!DH:!EXPORT:!RC4:+HIGH:!MEDIUM:!LOW:!aNULL:!eNULL;
        ssl_prefer_server_ciphers on;

        location / {
            proxy_pass http://127.0.0.1:8080;
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
}
```
通常情况下，我们将用户的 HTTP 请求 301或302 跳转到 HTTPS，这会存在两个问题：
* 不够安全，302 跳转会暴露用户访问站点，也容易被劫持
![http跳转中被劫持](http://oqcey66z7.bkt.clouddn.com/public/resource/http-unsafe.png)
* 拖慢访问速度，302 跳转需要一个 RTT（The role of packet loss and round-trip time），浏览器执行跳转也需要时间

## HSTS解决跳转不安全的问题
HSTS的全称是HTTP Strict-Transport-Security，它是一个Web安全策略机制（web security policy mechanism）。
302跳转是由浏览器触发的，服务器无法完全控制，这个需求导致了 HSTS(HTTP Strict Transport Security)的诞生。
HSTS就是添加 header 头（add_header Strict-Transport-Security max-age=15768000;includeSubDomains），告诉浏览器网站使用 HTTPS 访问，支持HSTS的浏览器（Chrome, firefox, ie 都支持了 HSTS（http://caniuse.com/#feat=stricttransportsecurity））就会在后面的请求中直接切换到 HTTPS。在 Chrome 中会看到浏览器自己会有个 307 Internal Redirect 的内部重定向。在一段时间内也就是max-age定义的时间，不管用户输入www.example.com还是http://www.example.com，都会默认将请求内部跳转到https://www.example.com。
HSTS最早于2015年被纳入到ThoughtWorks技术雷达，并且目前在“采用（Adopt）“阶段，这意味着ThoughtWorks强烈主张业界积极采用这项安全防御措施，并且ThoughtWorks已经将其应用于自己的项目。
HSTS Header的语法如下：

```
Strict-Transport-Security: <max-age=>[; includeSubDomains][; preload]
```
其中：

* max-age是必选参数，是一个以秒为单位的数值，它代表着HSTS Header的过期时间，通常设置为1年，即31536000秒。
* includeSubDomains是可选参数，如果包含它，则意味着当前域名及其子域名均开启HSTS保护。
* preload是可选参数，只有当你申请将自己的域名加入到浏览器内置列表的时候才需要使用到它。关于浏览器内置列表，下文有详细介绍。

Apache上启用HSTS
```markdown
# Optionally load the headers module:
LoadModule headers_module modules/mod_headers.so
 
<VirtualHost 0.0.0.0:443>
    Header always set Strict-Transport-Security "max-age=63072000; includeSubdomains; preload"
</VirtualHost>
```

Nginx上启用HSTS
```markdown
add_header Strict-Transport-Security "max-age=300; includeSubdomains; preload";
add_header X-Frame-Options "DENY";
```
Lighttpd上启用HSTS
```markdown
server.modules += ( "mod_setenv" )
$HTTP["scheme"] == "https" {
    setenv.add-response-header  = ( "Strict-Transport-Security" => "max-age=63072000; includeSubdomains; preload")
}
```

在生产环境下使用HSTS应当特别谨慎，因为一旦浏览器接收到HSTS Header（假如有效期是1年），但是网站的证书又恰好出了问题，那么用户将在接下来的1年时间内都无法访问到你的网站，直到证书错误被修复，或者用户主动清除浏览器缓存。因此，建议在生产环境开启HSTS的时候，先将max-age的值设置小一些，例如5分钟，然后检查HSTS是否能正常工作，网站能否正常访问，之后再逐步将时间延长，例如1周、1个月，并在这个时间范围内继续检查HSTS是否正常工作，最后才改到1年。

## 全站HTTPS必须解决的问题

然而，HTTPS并非“想上就上”，正式启用之前，必须解决至少三个方面的大问题。

首先是性能，这也主要分三点。

* HTTPS需要多次握手，因此网络耗时变长，用户从HTTP跳转到HTTPS需要一些时间；

* HTTPS要做RSA校验，这会影响到设备性能；

* 所有CDN节点要支持HTTPS，而且需要有极其复杂的解决方案来面对DDoS的挑战。

其次，兼容性及周边。

* 页面里所有嵌入的资源(图片/附件/js/css/视频等)都要改成HTTPS的,否则浏览器就会报警(静态资源的URL，采用 // 引用资源，表示遵从当前页面的协议，浏览器会进行自动补全).

* 移动客户端（APP）也需要适配HTTPS，所以必须做调整修改；

* 解决第三方网站看不到Referer的问题；

* 所有的开发、测试环境都要做HTTPS的升级；

最后，为保证上线时的顺利切换，需要提前准备大量的预案，以应对各种可能出现的情况。

## 全站HTTPS还可以做的更多

X-Frame-Options 头部添加到HTTPS站点，确保不会嵌入到frame 或 iframe，避免点击劫持，以确保网站的内容不会嵌入到其他网站。

Apache配置
```markdown
Header always set X-Frame-Options DENY
```

Nginx配置
```markdown
add_header X-Frame-Options "DENY";
```
Lighttpd配置
```markdown
server.modules += ( "mod_setenv" )
$HTTP["scheme"] == "https" {
    setenv.add-response-header  = ( "X-Frame-Options" => "DENY")
}
```

设置``listen   443  ssl http2 default_server;``最好将openssl和nginx升级到当前版本的最新版本

```markdown
yum update nginx
yum update openssl
```

最后，盗张阿里的图
![阿里HTTPS](http://oqcey66z7.bkt.clouddn.com/public/resource/alibaba-https.jpeg)