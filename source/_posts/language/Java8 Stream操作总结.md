
---
title: Java8 Stream使用总结
date: 2017-06-10 21:51:56
reward: true
categories:
    - language
tags:
    - JAVA
    - Stream
---

Stream 作为 Java 8 的一大亮点，它与 java.io 包里的 InputStream 和 OutputStream 是完全不同的概念。它也不同于 StAX 对 XML 解析的 Stream，也不是 Amazon Kinesis 对大数据实时处理的 Stream。java 8 中的 Stream 是对集合（Collection）对象功能的增强，它专注于对集合对象进行各种非常便利、高效的聚合操作（aggregate operation），或者大批量数据操作 (bulk data operation)。Stream API 借助于同样新出现的 Lambda 表达式，极大的提高编程效率和程序可读性。同时它提供串行和并行两种模式进行汇聚操作，并发模式能够充分利用多核处理器的优势，使用 fork/join 并行方式来拆分任务和加速处理过程。通常编写并行代码很难而且容易出错, 但使用 Stream API 无需编写一行多线程的代码，就可以很方便地写出高性能的并发程序。所以说，Java 8 中首次出现的 java.util.stream 是一个函数式语言+多核时代综合影响的产物。

<!--more-->

### List转Map
原来的代码
```markdown
Map<String,Worker> mapWorkers = new HashMap<>();
for(Worker worker:workers){
    if(worker.getBill()!=null && !worker.getWorkers().isEmpty()){
        mapWorkers.put(worker.getKey(),worker);
    }
}
```
Stream代码
```markdown
Map<String,Worker> mapWorkers = workers.parallelStream().filter(item->!item.getWorkers().isEmpty() && item.getBill()!=null)
                .collect(Collectors.toMap(Worker::getKey, Function.identity(), (key1, key2) -> key2));        


public static <T, K, U>
    Collector<T, ?, Map<K,U>> toMap(Function<? super T, ? extends K> keyMapper,
                                    Function<? super T, ? extends U> valueMapper,
                                    BinaryOperator<U> mergeFunction) {
        return toMap(keyMapper, valueMapper, mergeFunction, HashMap::new);
    }
                  
```

### List再加工
```markdown
List<AgentSettles> settles = source.parallelStream().filter(item->item.hasId() && item.getCorp()!=null)
                        .collect(ArrayList::new,(list,item)->{
                            List<SrvItems> srvItems = item.SrvItems();
                            if(srvItems!=null && !srvItems.isEmpty()){
                                List<AgentSettles> subSettles = srvItems.parallelStream().filter(srvItem->srvItem.hasId())
                                        .collect(ArrayList::new,(subList,srvItem)->subList.add(transferSub(item,srvItem,newId,user).orElse(null)),(subList1,subList2)->subList1.addAll(subList2));

                                list.addAll(subSettles);
                            }
                        },(list1,list2)->list1.addAll(list2));

<R> R collect(Supplier<R> supplier,
                  BiConsumer<R, ? super T> accumulator,
                  BiConsumer<R, R> combiner);
                  

这就是toList
    Collector<T, ?, List<T>> toList() {
        return new CollectorImpl<>((Supplier<List<T>>) ArrayList::new, List::add,
                                   (left, right) -> { left.addAll(right); return left; },
                                   CH_ID);
    }

```

### 分组
比如有个主子表，因为业务逻辑有批量操作，需要按主表id取出所有子表数据后再装配以提高效率
代码是这样子的
```markdown
List<SrvRequests> srvRequests = buildSourceChilds(parameter.getBills(),tenant).orElse(new ArrayList<>());
//形成表体分组
Map<Long,List<SrvRequests>> childs = srvRequests.parallelStream().filter(item->item.hasId())
        .collect(Collectors.groupingBy(SrvRequests::getMainid));
```

### 求和
比如对集合中满足一定条件的所有对象求和
```markdown
Double settleMoney = entity.parallelStream().filter(item->item.hasId() && item.getCorp()!=null)
                .mapToDouble(item->{
                    if(item.getAgentmoney()==null){
                        return 0;
                    }
                    return item.getAgentmoney().doubleValue();
                })
                .sum();
```


##使用场景

由于创建stream和传输会有性能开销，所以stream不是一个什么场合都能替代传统使用方式的特性。
* 集合操作超过两个步骤 
    比如先filter再for each，这时Stream显得优雅简洁，效率也高
* 任务较重，注重效能，希望并发执行 
    很容易的就隐式利用了多线程技术。非常好的使用时机。
* 针对的是复杂对象集合操作而非简单类型
    复杂对象而非List<Long>,List<String>这样的简单类型集合操作会比普通for each更高效。






