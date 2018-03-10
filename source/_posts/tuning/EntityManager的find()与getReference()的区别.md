
---
title: EntityManager的find()与getReference()的区别
date: 2018-03-05 21:40:46
reward: true
categories:
    - tuning
tags: 
    - JPA
    - EntityManager
---

先说相同点

    这两个方法都接受实体的 class和代表实体主键的对象作为参数。由于它们使用了Java泛型方法，无需任何显示的类型转换即可获得特定类型的实体对象。其中，在primaryKey上面普遍使用了java5的autoboxing（自动装箱）的特性。

    再者，就是两者都会在EntityManager关闭的情况下抛出IllegalStateException - if this EntityManager has been closed. 在传入的第一个参数不是实体或者第二个参数不是一个有效的主键的情况下抛出

IlegalArgumentException - if the first argument does not denote an entity type or the second argument is not a valid type for that entity's primary key

 <!--more-->

不同点：

    find()返回指定OID的实体，如果这个实体存在于当前的persistence context中，那么返回值是被缓存的对象；否则会创建一个新的实体，并从数据库中加载相关的持久状态。如果数据库不存在指定的OID的记录，那么find()方法返回null。

    getReference()方法和find()相似。不同的是：如果缓存中没有指定的实体，EntityManager会创建一个新的实体，但是不会立即访问数据库来加载持久状态，而是在第一次访问某个属性的时候才加载。此外，getReference()方法不返回null，如果数据库找不到相应的实体，这个方法会抛出javax.persistence.EntityNotFoundException。

EntityNotFoundException - if the entity state cannot be accessed
某些场合下使用getReference()方法可以避免从数据库加载持久状态的性能开销。
 
   这里要着重提出的是两句话：

```
   getReference()如果缓存中没有指定的实体，EntityManager会创建一个新的实体，但是不会立即访问数据库来加载持久状态，而是在第一次访问某个属性的时候才加载。
```

   比如，em.find()返回的实体，我们就可以对它进行各种操作，而若对em.getReference()返回的实体，由于不会立即访问数据库来加载持久状态，对它进行的操作很可能就会出现Exception，比如在对它返回的实体做getter操作时，由于EntityManager对此采用延时加载，就会抛出org.hibernate.lazyinitializationexception could not initialize proxy no session

```
   因此将一个新的实体传递给事务的时候通常使用find()方法，而当不连接数据库，不使用getter方法，即使用setter方法改变状态时才使用getReference（）方法。（这是由于getReference返回是一个Proxy实体，即没有加载持久状态）
```

   某些场合下使用getReference()方法可以避免从数据库加载持久状态的性能开销。

    这也完全是由于getReference返回是一个Proxy实体.

    比如一个简单的update操作，先使用find()获取实体，而后使用实体的setter方法；或者是getReference()方法，而后使用实体的setter方法。

    对于前者JPA调用的SQL：select ****，而后才是update ****

    对于后者：仅为update *****

 

又如：
```
操作                                                                            执行的SQL

em.remove(em.getReference(Person.class,1))         delete from Person where personid = 1

em.remove(em.find(Person.class,1))                 select * from Person where personid =1

                                                   delete from Person where personid =1
```
 

   由此可以看出，find()做了一次select的操作，而getReference并没有做有关数据库的操作，而是返回一个代理，这样它就减少了连接数据库和从数据库加载持久状态的开销。