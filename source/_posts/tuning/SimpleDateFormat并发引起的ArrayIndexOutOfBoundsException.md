
---
title: SimpleDateFormat并发引起的ArrayIndexOutOfBoundsException
date: 2017-10-22 21:40:46
reward: true
categories:
    - tuning
tags: 
    - ArrayIndexOutOfBoundsException
---

来自于[找bug记（1）](http://www.blogjava.net/killme2008/archive/2011/07/10/354062.html)，总结记录如下，感谢！

线上系统偶尔报出一行错误信息``java.lang.ArrayIndexOutOfBoundsException``。通过分析定位，打印出错误的详细堆栈如下。

```angularjs
java.lang.ArrayIndexOutOfBoundsException: 20
	at sun.util.calendar.BaseCalendar.getCalendarDateFromFixedDate(BaseCalendar.java:453)
	at java.util.GregorianCalendar.computeFields(GregorianCalendar.java:2397)
	at java.util.GregorianCalendar.computeFields(GregorianCalendar.java:2312)
	at java.util.Calendar.complete(Calendar.java:2236)
	at java.util.Calendar.get(Calendar.java:1826)
	at java.text.SimpleDateFormat.subFormat(SimpleDateFormat.java:1119)
	at java.text.SimpleDateFormat.format(SimpleDateFormat.java:966)
	at java.text.SimpleDateFormat.format(SimpleDateFormat.java:936)
	at java.text.DateFormat.format(DateFormat.java:345)
	at utils.xml.converter.TimestampConverterUtil.toString(TimestampConverterUtil.java:20)
	at com.thoughtworks.xstream.converters.SingleValueConverterWrapper.toString(SingleValueConverterWrapper.java:37)
	at com.thoughtworks.xstream.converters.SingleValueConverterWrapper.marshal(SingleValueConverterWrapper.java:45)
	at com.thoughtworks.xstream.core.TreeMarshaller.convert(TreeMarshaller.java:70)
	at com.thoughtworks.xstream.core.TreeMarshaller.convertAnother(TreeMarshaller.java:58)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter.marshallField(AbstractReflectionConverter.java:274)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter$2.writeField(AbstractReflectionConverter.java:250)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter$2.<init>(AbstractReflectionConverter.java:213)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter.doMarshal(AbstractReflectionConverter.java:144)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter.marshal(AbstractReflectionConverter.java:90)
	at com.thoughtworks.xstream.core.TreeMarshaller.convert(TreeMarshaller.java:70)
	at com.thoughtworks.xstream.core.TreeMarshaller.convertAnother(TreeMarshaller.java:58)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter.marshallField(AbstractReflectionConverter.java:274)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter$2.writeField(AbstractReflectionConverter.java:250)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter$2.<init>(AbstractReflectionConverter.java:213)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter.doMarshal(AbstractReflectionConverter.java:144)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter.marshal(AbstractReflectionConverter.java:90)
	at com.thoughtworks.xstream.core.TreeMarshaller.convert(TreeMarshaller.java:70)
	at com.thoughtworks.xstream.core.TreeMarshaller.convertAnother(TreeMarshaller.java:58)
	at com.thoughtworks.xstream.core.TreeMarshaller.convertAnother(TreeMarshaller.java:43)
	at utils.xml.converter.ListConverter.marshal(ListConverter.java:50)
	at com.thoughtworks.xstream.core.TreeMarshaller.convert(TreeMarshaller.java:70)
	at com.thoughtworks.xstream.core.TreeMarshaller.convertAnother(TreeMarshaller.java:58)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter.marshallField(AbstractReflectionConverter.java:274)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter$2.writeField(AbstractReflectionConverter.java:250)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter$2.<init>(AbstractReflectionConverter.java:213)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter.doMarshal(AbstractReflectionConverter.java:144)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter.marshal(AbstractReflectionConverter.java:90)
	at com.thoughtworks.xstream.core.TreeMarshaller.convert(TreeMarshaller.java:70)
	at com.thoughtworks.xstream.core.TreeMarshaller.convertAnother(TreeMarshaller.java:58)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter.marshallField(AbstractReflectionConverter.java:274)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter$2.writeField(AbstractReflectionConverter.java:250)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter$2.<init>(AbstractReflectionConverter.java:213)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter.doMarshal(AbstractReflectionConverter.java:144)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter.marshal(AbstractReflectionConverter.java:90)
	at com.thoughtworks.xstream.core.TreeMarshaller.convert(TreeMarshaller.java:70)
	at com.thoughtworks.xstream.core.TreeMarshaller.convertAnother(TreeMarshaller.java:58)
	at com.thoughtworks.xstream.core.TreeMarshaller.convertAnother(TreeMarshaller.java:43)
	at utils.xml.converter.ListConverter.marshal(ListConverter.java:50)
	at com.thoughtworks.xstream.core.TreeMarshaller.convert(TreeMarshaller.java:70)
	at com.thoughtworks.xstream.core.TreeMarshaller.convertAnother(TreeMarshaller.java:58)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter.marshallField(AbstractReflectionConverter.java:274)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter$2.writeField(AbstractReflectionConverter.java:250)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter$2.<init>(AbstractReflectionConverter.java:213)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter.doMarshal(AbstractReflectionConverter.java:144)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter.marshal(AbstractReflectionConverter.java:90)
	at com.thoughtworks.xstream.core.TreeMarshaller.convert(TreeMarshaller.java:70)
	at com.thoughtworks.xstream.core.TreeMarshaller.convertAnother(TreeMarshaller.java:58)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter.marshallField(AbstractReflectionConverter.java:274)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter$2.writeField(AbstractReflectionConverter.java:250)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter$2.<init>(AbstractReflectionConverter.java:213)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter.doMarshal(AbstractReflectionConverter.java:144)
	at com.thoughtworks.xstream.converters.reflection.AbstractReflectionConverter.marshal(AbstractReflectionConverter.java:90)
	at com.thoughtworks.xstream.core.TreeMarshaller.convert(TreeMarshaller.java:70)
	at com.thoughtworks.xstream.core.TreeMarshaller.convertAnother(TreeMarshaller.java:58)
	at com.thoughtworks.xstream.core.TreeMarshaller.convertAnother(TreeMarshaller.java:43)
	at com.thoughtworks.xstream.core.TreeMarshaller.start(TreeMarshaller.java:82)
	at com.thoughtworks.xstream.core.AbstractTreeMarshallingStrategy.marshal(AbstractTreeMarshallingStrategy.java:37)
	at com.thoughtworks.xstream.XStream.marshal(XStream.java:1067)
	at com.thoughtworks.xstream.XStream.marshal(XStream.java:1056)
	at com.thoughtworks.xstream.XStream.toXML(XStream.java:1029)
	at com.thoughtworks.xstream.XStream.toXML(XStream.java:1016)
	at utils.xml.XmlTool.bean2XML(XmlTool.java:63)
	at utils.result.XmlResult.getResult(XmlResult.java:79)
	at utils.result.XmlResult.getResult(XmlResult.java:60)
	at utils.result.XmlResult.getResult(XmlResult.java:55)
	at utils.result.XmlResult.data(XmlResult.java:130)
	at controllers.rs.Orders.getOrder(Orders.java:103)
	at play.mvc.ActionInvoker.invokeWithContinuation(ActionInvoker.java:536)
	at play.mvc.ActionInvoker.invoke(ActionInvoker.java:473)
	at play.mvc.ActionInvoker.invokeControllerMethod(ActionInvoker.java:467)
	at play.mvc.ActionInvoker.invokeControllerMethod(ActionInvoker.java:436)
	at play.mvc.ActionInvoker.invoke(ActionInvoker.java:159)
	at Invocation.HTTP Request(Play!)
```

但是发现并不是每一条错误记录都会出现完整的堆栈信息。我们线上日志一直出现一行错误信息ArrayIndexOutOfBoundsException却没有堆栈，是我们没有正确地写日志吗？检查代码不是的，这个问题其实是跟JDK5引入的一个新特性有关，对于一些频繁抛出的异常，JDK为了性能会做一个优化，在JIT重新编译后会抛出没有堆栈的异常。在使用server模式的时候，这个优化是开启的，我们的服务器跑在server模式下并且jdk版本大于1.5，因此在频繁抛出ArrayIndexOutOfBoundsException异常一段时间后优化开始起作用，只抛出没有堆栈的异常信息了。
那么怎么解决这个问题呢？因为这个优化是在JIT重新编译后才起作用，因此一开始抛出异常的时候还是有堆栈的，所以可以查看较旧的日志，寻找有完整堆栈的异常信息。但是由于我们的日志太大，会定期删除，我们的服务器也启动了很长时间，因此查找日志不是很靠谱的方法。
另一个解决办法是暂时禁用这个优化，强制要求每次都要抛出有堆栈的异常。
幸好JDK提供了选项来关闭这个优化，配置JVM参数
```angularjs
-XX:-OmitStackTraceInFastThrow
```
就可以禁止这个优化（注意选项中的减号，加号是启用）。

回到堆栈信息,这个问题是由于SimpleDateFormat的误用引起的。

```angularjs
Date formats are not synchronized. It is recommended to create separate format instances for each thread. 
If multiple threads access a format concurrently, it must be synchronized externally. 
```

简单来说就是SimpleDateFormat不是线程安全的，你要么每次都new一个来用，要么做加锁来同步使用。

出问题的代码就是由于工程师认为SimpleDateFormat的创建代价很高，在类的前面创建类一个static对象来缓存SimpleDateFormat（``private static final SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd");``），所有线程共用这个instance做format，同时没有做同步。悲剧就诞生了。
这里就引出我想提到的第二点问题，在使用一个类或者方法的时候，最好能详细地看下该类的javadoc，JDK的javadoc是做的非常好的，javadoc除了做说明之外，通常还会给示例，并且会点出一些关键问题，如线程安全性和平台移植性。

解决方案：

```angularjs
private static ThreadLocal<SimpleDateFormat> formatCache = new ThreadLocal<SimpleDateFormat>() {

        @Override
        protected SimpleDateFormat initialValue() {
            return new SimpleDateFormat("yyyy-MM-dd");
        }

    };

    public static String formatDate3(Date date) {
        SimpleDateFormat format = formatCache.get();
        return format.format(date);
    }
```
