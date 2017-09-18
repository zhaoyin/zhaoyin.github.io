
---
title: IntelliJ IDEA 配置 PlayFramework(play1)
date: 2017-06-04 00:00:00
reward: true
categories:
    - tools
tags:
    - IntelliJ Idea
    - playframework
---

## 生成ipr工程文件

 ** IntelliJ IDEA官方说play framework 1.x只被IntelliJ IDEA11及以下版本支持，新版本的IntelliJ IDEA现在只支持最新的Play Framework 2.x。**
通过配置发现高版本是可以支持play1的。

配置好play1的具体应用后，在应用目录可以通过执行``play idea``可以为该play应用生成Intellij IDEA需要的ipr文件和iml文件

```
~        _            _ 
~  _ __ | | __ _ _  _| |
~ | '_ \| |/ _' | || |_|
~ |  __/|_|\____|\__ (_)
~ |_|            |__/   
~
~ play! 1.4.4, https://www.playframework.com
~
~ OK, the application is ready for Intellij Idea
~ Use File, Open Project... to open "playdemo.ipr"
~

```

之后在Intellij IDEA中通过菜单栏--文件>>打开>>找到之前的ipr文件打开应用

如果当前应用有play modules，可以打开iml文件，看对应的module路径是否配置正确，如果配置不正确，play应用启动的时候会因为找不到相应的引用类而报错

```
<content url="file://$MODULE_DIR$/mymodules/module1">
      <sourceFolder url="file://$MODULE_DIR$/mymodules/module1/app" isTestSource="false" />
    </content>
```
比如上面的配置就是修改后的，play idea生成的iml文件默认缺少``$MODULE_DIR$/``这一级，会导致引用的模块无法找到的错误。

<!--more-->

## 配置playframework框架信息

* 菜单栏点设置（Settings)按钮(即macOS 产品的Preferencs，按快捷键command+,)
* 在弹出窗口左侧搜索play configuration,会发现Play Configuration 在 Language & Frameworks菜单里面。
* 在右侧窗口设置playframework的Home（playframework本身目录，即play命令所在的目录），项目目录（working directory），当前项目的目录

## 配置项目依赖的play库文件

* 在项目中通过``文件(File)``打开``Project Structure``也可以通过快捷键command+;打开

* 在Modules找到项目，在右侧找到最后一个选项卡Dependencies（依赖）看是否加入了play框架对应的jar

* 如果没有在左下方点+号``Jars or directories.``

* 在弹出的文件选择框中选择play应用目录``framework\lib``和play的jar``framework\play-<version>.jar``

## 运行一个play项目

* 打开Intellij IDEA的Run菜单，找到Edit Configurations。``Run | Edit Configurations``

* 点击+号并选择Application

* 做以下配置
```
  Main class:play.server.Server
  VM options:-Dapplication.path="."
  Working directory:play应用所在的目录
```

以上的配置相当于命令行执行play run或者play start

## 运行项目单元测试

* 在上面的``配置项目依赖的play库文件``最后一步，即设置项目的依赖项的地方增加测试的依赖jar.将``<play_dir>\modules\testrunner\lib\play-testrunner.jar``加入依赖项

* ``Edit Configurations``时做如下配置
    ```
      Main class:play.server.Server
      VM options:-Dapplication.path="." -Dplay.id=test
      Working directory:play应用所在的目录
    ```

以上的配置相当于执行命令play test

## 调试项目

和运行play项目的配置相似，只是VM options设置如下：
```
-Dapplication.path="." -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8000
```
