
---
title: 一个线上CPU100%(could not prepare statement)问题的分析
date: 2017-07-13 21:40:46
reward: true
categories:
    - tuning
tags: 
    - CPU
---

![cpu100%](http://static.xcoder.ren/public/resource/cpu100%25.png)
## 问题
今天突然收到线上报警说CPU超过90%，收到短信后我不慌不忙的打开电脑，打开ELK搭的日志服务，查看有没有错误日志，因为根据经验，这种问题很容易是代码有问题造成的。找到了下面的内容
```markdown
Exception:org.hibernate.exception.JDBCConnectionException: could not prepare statement
javax.persistence.PersistenceException: org.hibernate.exception.JDBCConnectionException: could not prepare statement
	at org.hibernate.ejb.AbstractEntityManagerImpl.convert(AbstractEntityManagerImpl.java:1387)
	at org.hibernate.ejb.AbstractEntityManagerImpl.convert(AbstractEntityManagerImpl.java:1310)
	at org.hibernate.ejb.AbstractEntityManagerImpl.convert(AbstractEntityManagerImpl.java:1316)
	at org.hibernate.ejb.AbstractEntityManagerImpl.flush(AbstractEntityManagerImpl.java:999)
	at play.db.jpa.JPABase._save(JPABase.java:45)
	at play.db.jpa.GenericModel.save(GenericModel.java:232)
	....
	at java.lang.Thread.run(Thread.java:745)
Caused by: org.hibernate.exception.JDBCConnectionException: could not prepare statement
	at org.hibernate.exception.internal.SQLExceptionTypeDelegate.convert(SQLExceptionTypeDelegate.java:67)
	.....
	at org.hibernate.ejb.AbstractEntityManagerImpl.flush(AbstractEntityManagerImpl.java:996)
	... 17 more
Caused by: com.mysql.jdbc.exceptions.jdbc4.MySQLNonTransientConnectionException: No operations allowed after connection closed.
	at com.mysql.jdbc.Util.handleNewInstance(Util.java:425)
	at com.mysql.jdbc.Util.getInstance(Util.java:408)
	at com.mysql.jdbc.SQLError.createSQLException(SQLError.java:918)
	.....
	at com.mysql.jdbc.ConnectionImpl.prepareStatement(ConnectionImpl.java:4071)
	at org.hibernate.engine.jdbc.internal.StatementPreparerImpl$1.doPrepare(StatementPreparerImpl.java:96)
	at org.hibernate.engine.jdbc.internal.StatementPreparerImpl$StatementPreparationTemplate.prepareStatement(StatementPreparerImpl.java:183)
```
<!--more-->
果然，有大量的这种日志。正准备继续分析，又收到了下面的消息
```markdown
主机:xxx.xxxx.xxx.xx
时间:2017.07.13 19:32:41
等级:Warning
信息:Disk I/O is overloaded on xxx.xxx.xxx.xxxx
项目:system.cpu.util[,iowait]
详情:CPU iowait time:79.29 %
状态:PROBLEM:79.29 %
事件ID:2229710
```
```markdown
主机:xxx.xxx.xxx.xxx
时间:2017.07.13 20:25:37
等级:High
信息:xxxxx is unavailable!!
项目:web.test.rspcode[xx,xxxxxx]
详情:Response code for step "xxxxxxxx.xxx.xx" of scenario "xxxx".:502
状态:PROBLEM:502
事件ID:2230199
```
问题已经变得越来越严重了。没有时间分析了，必须马上重启应用，否则会造成更大范围的问题。因为该机器不是该应用实例独享的。一旦该应用实例问题积聚，就会造成CPU持续100%，接着就会造成这个机器无法访问，进而影响该机器上的其他应用实例。
果然，接着就收到另一个站点不能访问的短信。已经波及另一个应用了。ssh一试也已经登录不上去了。
登录阿里云重启机器后重启该机器的所有服务，过一会看日志服务又有大量的``could not prepare statement``这种日志了。因为这个是定时任务服务器，出问题的堆栈显示是一个每20分钟执行的JOB。现在要解决问题只能先停掉定时任务的服务，以免重蹈CPU飙升的覆辙。
停止后分析问题，该JOB执行是从数据表里面取出数据（其他站点服务存放的未处理数据），然后调用第三方服务处理数据后再将处理结果回写。
查看数据表中的数据量，不查不知道，一查吓一跳，里面有3400条未处理数据。这说明当时二十分钟内突然积聚了几百条数据，能短时间内突然积聚上百条数据应该是站点上导入数据造成的。
以下是出问题的代码
```markdown
for(Entity entity : entities){
    //以下是伪代码
    try{
        ApiResult result = thirdApi.doSomeThing(entity); //第三方api处理并返回结果
        entity = decorateEntity(result);  //根据返回结果处理数据
        entity.save();  //将处理好的数据执行更新操作
        if(result.success){ //返回执行成功的结果同时要处理另外的数据
            OtherEntity oEntity = getOtherEntity(entity); 
            oEntity = decorateOtherEntity(oEntity);
            oEntity.save();
        }
    }catch(Exception e){
        Logger.error(e);
    }
}
```
由于我们的应用本身如果不自行处理事务，默认会在每一个http请求开始时启动一个事务，如果不标记readonly=true则不是只读事务。但是JOB操作不会启事务。
当JOB中几百条数据,几千条数据过来（循环），会大量请求新的连接（session），最终会耗尽C3P0连接池的最大连接数，导致`` No operations allowed after connection closed.``，进而出现``could not prepare statement``;
而且没有单独处理每一条记录的事务，还会出现entity.save()成功了，但是oEntity.save()失败了，导致数据不一致的情况。
找到原因后做如下处理：
```markdown
for(Entity entity : entities){
    //以下是伪代码
    try{     
        if (!JPA.isInitialized()) {
            JPA.startTx(JPA.DEFAULT, false);
        }
        ApiResult result = thirdApi.doSomeThing(entity);
        entity = decorateEntity(result);
        entity.save();
        if(result.success){
            OtherEntity oEntity = getOtherEntity(entity);
            oEntity = decorateOtherEntity(oEntity);
            oEntity.save();
        }
    }catch(Exception e){
        JPA.rollbackTx(JPA.DEFAULT);
        Logger.error(e);
    }finally {
        JPA.closeTx(JPA.DEFAULT);
    }
}
```
这样的代码够了吗？
并不够，每条记录单独加事务，由于要处理的数据多，处理几条数据后就会发现可能会出下面的错误
```markdown
Exception:org.hibernate.PersistentObjectException: detached entity passed to persist: models.user.UhtUserShip
javax.persistence.PersistenceException: org.hibernate.PersistentObjectException: detached entity passed to persist: models.user.UhtUserShip
	at org.hibernate.ejb.AbstractEntityManagerImpl.convert(AbstractEntityManagerImpl.java:1387)
	at org.hibernate.ejb.AbstractEntityManagerImpl.convert(AbstractEntityManagerImpl.java:1310)
	at org.hibernate.ejb.AbstractEntityManagerImpl.convert(AbstractEntityManagerImpl.java:1316)
	at org.hibernate.ejb.AbstractEntityManagerImpl.persist(AbstractEntityManagerImpl.java:881)
	at play.db.jpa.JPABase._save(JPABase.java:35)
	at play.db.jpa.GenericModel.save(GenericModel.java:232)
	....
	at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.access$201(ScheduledThreadPoolExecutor.java:180)
	at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:293)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1142)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:617)
	at java.lang.Thread.run(Thread.java:745)
Caused by: org.hibernate.PersistentObjectException: detached entity passed to persist: models.user.UhtUserShip
	at org.hibernate.event.internal.DefaultPersistEventListener.onPersist(DefaultPersistEventListener.java:141)
	....
	at org.hibernate.internal.SessionImpl.persist(SessionImpl.java:750)
	at org.hibernate.ejb.AbstractEntityManagerImpl.persist(AbstractEntityManagerImpl.java:875)
	... 17 more
```
这是因为后面的记录在save时，由于中间连接关闭过，持久化对象已经由持久态转换为游离态，保存一个游离态的对象就可能会出现``detached entity passed to persist``的错误。
```markdown
for(Entity entity : entities){
    //以下是伪代码
    try{     
        if (!JPA.isInitialized()) {
            JPA.startTx(JPA.DEFAULT, false);
        }
        ApiResult result = thirdApi.doSomeThing(entity);
        entity = decorateEntity(result);
        entity = entity.merge();
        entity.save();
        if(result.success){
            OtherEntity oEntity = getOtherEntity(entity);
            oEntity = decorateOtherEntity(oEntity);
            oEntity = oEntity.merge();
            oEntity.save();
        }
    }catch(Exception e){
        JPA.rollbackTx(JPA.DEFAULT);
        Logger.error(e);
    }finally {
        JPA.closeTx(JPA.DEFAULT);
    }
}
```
通过merge将实体转换为持久态再save。由于可能会出现大量数据要处理，你应该处理的尽善尽美
```markdown
int index = 0;
for(Entity entity : entities){
    index +=1;
    //以下是伪代码
    try{     
        if (!JPA.isInitialized()) {
            JPA.startTx(JPA.DEFAULT, false);
        }
        if (index % 100 == 0) {
            JPA.em().flush();
            JPA.em().clear();
        }
        ApiResult result = thirdApi.doSomeThing(entity);
        entity = decorateEntity(result);
        entity = entity.merge();
        entity.save();
        if(result.success){
            OtherEntity oEntity = getOtherEntity(entity);
            oEntity = decorateOtherEntity(oEntity);
            oEntity = oEntity.merge();
            oEntity.save();
        }
    }catch(Exception e){
        JPA.rollbackTx(JPA.DEFAULT);
        Logger.error(e);
    }finally {
        JPA.closeTx(JPA.DEFAULT);
    }
}
```
每100条清理一次缓存。行百里者半九十，每一步都做好才能写出经得起考验的程序。

## 扩展:Hibernate三态转换
![三态转换](http://static.xcoder.ren/public/resource/hibernate-three-states.jpg)

Hibernate有三种状态：transient(瞬时状态)，persistent(持久化状态)以及detached(游离状态)。

* transient（瞬时状态）--临时状态

当new出来一个新对象，还没有保存到数据库中的时候，就是transient状态。

* persistent(持久化状态)

当临时状态的对象被执行save之后，就会被session托管，在session中有一个map存放着user对象，也就是说user对象被session引用着，被session纳入管理了。此时的user就处于持久状态了。

* detached(游离状态)

当持久状态的对象user,在session关闭之后就会变成有游离状态。