
---
title: Jackson UnrecognizedPropertyException
date: 2017-07-03 22:40:56
categories:
    - build
tags:
    - jackson
    - UnrecognizedPropertyException
---

```angularjs
org.springframework.http.converter.HttpMessageNotReadableException: Could not read document: Unrecognized field "refusereason" (class com.xxx.cloud.bill.srvbill.vo.Workman), not marked as ignorable (16 known properties: "departTime", "arrivalPosition", "starttime2", "arrivallat", "departlat", "starttimerange", "starttime", "realStartTime", "arrivallon", "departlon", "refuseReason", "description", "result", "realOverTime", "arrivalTime", "departPosition"])
 at [Source: java.io.PushbackInputStream@45fded3c; line: 1, column: 19] (through reference chain: com.xxx.cloud.bill.srvbill.vo.Workman["refusereason"]); nested exception is com.fasterxml.jackson.databind.exc.UnrecognizedPropertyException: Unrecognized field "refusereason" (class com.xxxx.cloud.bill.srvbill.vo.Workman), not marked as ignorable (16 known properties: "departTime", "arrivalPosition", "starttime2", "arrivallat", "departlat", "starttimerange", "starttime", "realStartTime", "arrivallon", "departlon", "refuseReason", "description", "result", "realOverTime", "arrivalTime", "departPosition"])
 at [Source: java.io.PushbackInputStream@45fded3c; line: 1, column: 19] (through reference chain: com.xxx.cloud.bill.srvbill.vo.Workman["refusereason"])
	at org.springframework.http.converter.json.AbstractJackson2HttpMessageConverter.readJavaType(AbstractJackson2HttpMessageConverter.java:240)
	at org.springframework.http.converter.json.AbstractJackson2HttpMessageConverter.read(AbstractJackson2HttpMessageConverter.java:225)
	at org.springframework.web.servlet.mvc.method.annotation.AbstractMessageConverterMethodArgumentResolver.readWithMessageConverters(AbstractMessageConverterMethodArgumentResolver.java:201)
	at org.springframework.web.servlet.mvc.method.annotation.RequestResponseBodyMethodProcessor.readWithMessageConverters(RequestResponseBodyMethodProcessor.java:150)
	at org.springframework.web.servlet.mvc.method.annotation.RequestResponseBodyMethodProcessor.resolveArgument(RequestResponseBodyMethodProcessor.java:128)
	at org.springframework.web.method.support.HandlerMethodArgumentResolverComposite.resolveArgument(HandlerMethodArgumentResolverComposite.java:121)
	at org.springframework.web.method.support.InvocableHandlerMethod.getMethodArgumentValues(InvocableHandlerMethod.java:160)
	at org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:129)
	at org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod.invokeAndHandle(ServletInvocableHandlerMethod.java:116)
	at org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.invokeHandlerMethod(RequestMappingHandlerAdapter.java:827)
	at org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.handleInternal(RequestMappingHandlerAdapter.java:738)
	at org.springframework.web.servlet.mvc.method.AbstractHandlerMethodAdapter.handle(AbstractHandlerMethodAdapter.java:85)
	at org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:963)
	at org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:897)
	at org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:970)
	at org.springframework.web.servlet.FrameworkServlet.doPost(FrameworkServlet.java:872)
	at javax.servlet.http.HttpServlet.service(HttpServlet.java:707)
	at org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:846)
	at javax.servlet.http.HttpServlet.service(HttpServlet.java:790)
	...
```
<!--more-->
属性大小写问题，属性全部大写或小写，JackSon 默认是通过驼式命名法处理。比如 nickName 这样儿，有时比较特殊，比如映入其他系统的字段，可能都是大写或小写
可以通过``@JsonProperty(value = "refusereason")``处理