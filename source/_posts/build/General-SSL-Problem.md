
---
title: General SSL Problem总结
date: 2017-05-23 20:59:56
categories:
    - build
tags:
    - JAVA
    - 证书
---

General SSL Problem 如果您有同样的报错日志，不要急，下面讲解原因与解决办法。

       在此之前需要了解下信任管理器(TrustManager)，它负责判断决定是否信任对方的安全证书，TrustManager对象由TrustManagerFactory工厂类生成。想了解Java安全套接字扩展详情，请访问 http://www.2cto.com/kf/201408/323963.html

原因：
       沃通顶级根，没有存在jdk信任管理器中，信任管理器，它的职责是觉得是否信任远端的证书，那么它凭借什么去判断呢？如果不显式设置信任存储器的文件路径，将遵循如下规则：①如果系统属性javax.net.ssl.truststore指定了truststore文件，那么信任管理器将去jre路径下的lib/security目录寻找这个文件作为信任存储器；②如果没设置①中的系统属性，则去寻找一个%java_home%/jre/lib/security/jssecacerts文件作为信任存储器；③如果jssecacerts不存在而cacerts存在，则cacerts作为信任存储器。一般情况下，都是%java_home%/jre/lib/security/cacerts作为任务管理器。


解决办法：
       方法一：申请沃通企业级SHA2证书，沃通将这类型证书和certum做了交叉认证，certum在jdk 1.5+ 环境已经存在信任管理器中，这样不用做任何其他操作，替换证书即可通过信任。
       方法二：将您的公钥文件（for other server 包中的3_domian.crt文件）直接导入到信任管理器中，那么首先要确认是需要导入到哪个java环境呢？需要用户去判断是在哪个服务器的java环境调用https链接不受信任，那么就将证书公钥导入到这个Java环境的信任管理器中，方法如下。（以cacerts为例，其他信任管理器请相应修改！）
linux环境：执行 “ keytool -import -file 公钥文件路径/3_domian.crt -keystore %java_home%/jre/lib/security/cacerts -storepass changeit -alias wosign ”。
windows环境：dos下先cd到jdk的java\jdk1.8.0.45\bin目录下，执行 “ keytool -import -file 公钥文件路径\3_domian.crt -keystore ../jre\lib\security\cacerts -storepass changeit -alias wosign ”。
       选择一种解决方法，然后再次测试