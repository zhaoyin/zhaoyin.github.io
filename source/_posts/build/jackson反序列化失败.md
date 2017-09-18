
---
title: jackson反序列化化无法构造实例的问题
date: 2017-06-03 22:40:56
categories:
    - build
tags:
    - jackson
    - JsonMappingException
---

今天在一个项目的前端调用后台服务出现如下的错误：
```
Could not read document: Can not construct instance of xxxxx: no suitable constructor found, can not deserialize from Object value (missing default constructor or creator, or perhaps need to add/enable type information?)


Caused by: com.fasterxml.jackson.databind.JsonMappingException: Can not construct instance of xxxx: no suitable constructor found, can not deserialize from Object value (missing default constructor or creator, or perhaps need to add/enable type information?)
 at [Source: java.io.PushbackInputStream@517c5e; line: 1, column: 3] (through reference chain: java.util.ArrayList[0])
	at com.fasterxml.jackson.databind.JsonMappingException.from(JsonMappingException.java:270) ~[jackson-databind-2.8.8.jar:2.8.8]
	at com.fasterxml.jackson.databind.DeserializationContext.instantiationException(DeserializationContext.java:1456) ~[jackson-databind-2.8.8.jar:2.8.8]
	at com.fasterxml.jackson.databind.DeserializationContext.handleMissingInstantiator(DeserializationContext.java:1012) ~[jackson-databind-2.8.8.jar:2.8.8]
	at com.fasterxml.jackson.databind.deser.BeanDeserializerBase.deserializeFromObjectUsingNonDefault(BeanDeserializerBase.java:1206) ~[jackson-databind-2.8.8.jar:2.8.8]
	at com.fasterxml.jackson.databind.deser.BeanDeserializer.deserializeFromObject(BeanDeserializer.java:314) ~[jackson-databind-2.8.8.jar:2.8.8]
	at com.fasterxml.jackson.databind.deser.BeanDeserializer.deserialize(BeanDeserializer.java:148) ~[jackson-databind-2.8.8.jar:2.8.8]
	at com.fasterxml.jackson.databind.deser.std.CollectionDeserializer.deserialize(CollectionDeserializer.java:287) ~[jackson-databind-2.8.8.jar:2.8.8]
	at com.fasterxml.jackson.databind.deser.std.CollectionDeserializer.deserialize(CollectionDeserializer.java:259) ~[jackson-databind-2.8.8.jar:2.8.8]
	at com.fasterxml.jackson.databind.deser.std.CollectionDeserializer.deserialize(CollectionDeserializer.java:26) ~[jackson-databind-2.8.8.jar:2.8.8]
	at com.fasterxml.jackson.databind.ObjectMapper._readMapAndClose(ObjectMapper.java:3798) ~[jackson-databind-2.8.8.jar:2.8.8]
	at com.fasterxml.jackson.databind.ObjectMapper.readValue(ObjectMapper.java:2922) ~[jackson-databind-2.8.8.jar:2.8.8]
	at org.springframework.http.converter.json.AbstractJackson2HttpMessageConverter.readJavaType(AbstractJackson2HttpMessageConverter.java:237) ~[spring-web-4.3.5.RELEASE.jar:4.3.5.RELEASE]
	... 51 more
```

无法实例化json对象，没有找到适合的构造函数。
<!--more-->
在进行反序列号的时候，需要要转换类是普通的pojo类，并且类中的变量都需要有setXXX的set方法，如果没有set方法或者没有“正确”的set方法，就会报无法实例化JSON对象的异常