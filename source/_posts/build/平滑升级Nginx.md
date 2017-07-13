
---
title: 平滑升级Nginx
date: 2017-07-12 14:40:56
reward: true
categories:
    - build
tags:
    - nginx
---

* 通过``yum update nginx``升级

Nginx官方为RHEL/CentOS/Debian/Ubuntu/SLES提供了yum和apt源.

Pre-Built Packages for Stable version

To set up the yum repository for RHEL/CentOS, create the file named /etc/yum.repos.d/nginx.repo with the following contents:
```markdown
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/OS/OSRELEASE/$basearch/
gpgcheck=0
enabled=1
```
Replace “OS” with “rhel” or “centos”, depending on the distribution used, and “OSRELEASE” with “5”, “6”, or “7”, for 5.x, 6.x, or 7.x versions, respectively.
<!--more-->
For Debian/Ubuntu, in order to authenticate the nginx repository signature and to eliminate warnings about missing PGP key during installation of the nginx package, it is necessary to add the key used to sign the nginx packages and repository to the apt program keyring. Please download this key from our web site, and add it to the apt program keyring with the following command:
```markdown
sudo apt-key add nginx_signing.key
```

For Debian replace codename with Debian distribution codename, and append the following to the end of the /etc/apt/sources.list file:
```markdown
deb http://nginx.org/packages/debian/ codename nginx
deb-src http://nginx.org/packages/debian/ codename nginx
```

For Ubuntu replace codename with Ubuntu distribution codename, and append the following to the end of the /etc/apt/sources.list file:
```markdown
deb http://nginx.org/packages/ubuntu/ codename nginx
deb-src http://nginx.org/packages/ubuntu/ codename nginx
```

For Debian/Ubuntu then run the following commands:
```markdown
apt-get update
apt-get install nginx
```

For SLES run the following command:
```markdown
zypper addrepo -G -t yum -c 'http://nginx.org/packages/sles/12' nginx
```

最好还是通过手动编译来安装nginx而不是通过``yum install nginx``.
* 手动编译安装openssl版本是OpenSSL 1.0.2h
* 手动编译安装nginx，增加编译参数
 --with-http_ssl_module \
 --with-http_v2_module \
 --with-openssl=/usr/local/src/openssl-1.0.2h
 
手动编译的好处是可以控制OpenSSL为最新版本，目前大多Linux系统的OpenSSL均不是最新系统。
