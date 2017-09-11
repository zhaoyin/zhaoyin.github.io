---
title: Spring管理Bean的一些设置
date: 2017-09-11 12:38:56
reward: true
categories:
    - Spring
tags:
    - Spring
---

<!--more-->

```angularjs
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-3.0.xsd http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd"
       default-autowire="byName">
    <!--
        1.bean1和bean2效果是相同的,Spring默认以单例模式创建Bean,不配置scope或者配置scope为singleton即说明配置为以单例模式创建Bean
        2.单例Bean的生命周期受Spring管理，在Spring容器关闭或者销毁时销毁该Bean或者执行该Bean定义的destory-method方法。创建该Bean分为两种情况:
            1).未设置lazy-init=true时,Spring会在启动Spring容器时创建该Bean对象
            2).设置lazy-init=true时,Spring容器会在context.getBean时创建该对象
        3.多例Bean不受Spring管理生命周期,在别的Bean中注入Bean或者context.getBean时都会new一个Bean实例。所以lazy-init一定是true，设置为其他值无效，所以bean3和bean4是相同的。
        4.多例Bean由于不受Spring管理生命周期,需要自行销毁Bean中的资源，基本上destory-method在多例模式下也没什么用。
    -->

    <!--

        Spring容器初始化bean和销毁前所做的操作定义方式有三种:
        1.通过@PostConstruct和@PreDestroy方法实现初始化和销毁bean之前进行的操作。
        2.通过xml中配置init-method和destory-method方法。
        3.通过bean实现InitializingBean和DisposableBean接口

    -->

    <!--

        InitializingBean和init-method的异同
        1.InitializingBean
            1).Spring的InitializingBean为Bean提供了定义初始化方法的方式。
            2).InitializingBean是一个接口，它仅仅包含一个方法：afterPropertiesSet()。
            3).在Spring初始化后，执行完所有属性设置方法(即setXxx)将自动调用afterPropertiesSet(),在配置文件中无须特别的配置,但此方式增加了Bean对Spring的依赖，应该尽量避免使用
        但是InitializingBean增加了和Spring的耦合依赖。所以好的选择是给Bean设置init-method。
        2.init-method
            1)Spring要求init-method是一个无参数的方法，如果init-method指定的方法中有参数，那么Spring将会抛出java.lang.NoSuchMethodException
            2)init-method指定的方法可以是public、protected以及private的，并且方法也可以是final的。
        3.InitializingBean和init-method可以一起使用，Spring会先处理InitializingBean再处理init-method。
        4.init-method是通过反射执行的，而afterPropertiesSet是直接执行的。所以afterPropertiesSet的执行效率比init-method要高，不过init-method消除了bean对Spring依赖。
        5.需要注意的是Spring总是先处理Bean定义的InitializingBean，然后才处理init-method。如果在Spirng处理InitializingBean时出错，那么Spring将直接抛出异常，不会再继续处理init-method。
        6.如果一个bean被定义为非单例的，那么afterPropertiesSet和init-method在bean的每一个实例被创建时都会执行。单例Bean的afterPropertiesSet和init-method只在bean第一次被实例时调用一次。大多数情况下afterPropertiesSet和init-method都应用在单例的Bean上。

    -->

    <bean id="bean1" class="xx.xx.xx.x"/>
    <bean id="bean2" class="xx.xx.xx.x" scope="singleton"/>
    <bean id="bean3" class="xx.xx.xx.x" scope="prototype"/>
    <bean id="bean4" class="xx.xx.xx.x" scope="prototype" lazy-init="false"/>
    <bean id="bean5" class="xx.xx.xx.x" init-method="method1" destroy-method="method2" lazy-init="true"/>

    <!--

        1.在xml配置了``context:component-scan``标签后，spring可以自动去扫描base-package下面或者子包下面的java文件，如果扫描到有@Component @Controller@Service等这些注解的类，则把这些类注册为Bean.
        2.``context:component-scan``标签有默认属性``use-default-filters``,该属性默认值为``true``。如果为默认值时设置``context:include-filter``和``context:exclude-filter``无效。
        3.``use-default-filters``为``false``时可以设置扫描base-package包的同时只包含``context:include-filter``定义的包或者排除``context:exclude-filter``定义的包。

    -->

    <context:component-scan base-package="com.xx.xx.x"></context:component-scan>
    <context:component-scan base-package="com.xx.xx.x" use-default-filters="true"></context:component-scan>
    <context:component-scan base-package="com.xx.xx.x" use-default-filters="false">
        <context:include-filter type="annotation" expression="org.springframework.stereotype.Controller"/>
        <context:exclude-filter type="annotation" expression="com.xx.xx.x"/>
    </context:component-scan>
    <context:annotation-config></context:annotation-config>
</beans>
```