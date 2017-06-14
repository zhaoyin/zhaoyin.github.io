
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






