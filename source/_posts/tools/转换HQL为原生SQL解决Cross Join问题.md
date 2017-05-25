
---
title: 转换HQL为原生SQL解决Cross Join问题
date: 2017-05-25 18:50:56
reward: true
categories:
    - tools
tags:
    - Hibernate
    - HQL
    - Cross Join
---

[Hibernate 测试用例](https://github.com/hibernate/hibernate-orm/blob/0a2a5c622e3eb30724e80bc8661c0ac55ebfb2be/hibernate-core/src/test/java/org/hibernate/test/locale/LocaleTest.java#L43)

Hibernate将HQL转换为原生sql的测试用例。

<!--more-->

为了能够让Gson直接解析实体类时不会出现栈溢出和死循环，我们去掉了实体类通过@OneToOne,@OneToMany,@ManyToMany注解的方式来描述元数据。而是通过元数据描述的形式来定义

```
{
    String srcType = "SaleReturn";
    List<Relation> relations = new ArrayList<>();
    relations.add(new Relation(srcType, "iLogisticWayId", "models.corp.CorprationLogistics", "id"));
    relations.add(new Relation(srcType, "iSaleReturnMemoId", "models.voucher.VoucherMemo", "id"));
    metaMap.put(srcType, relations);
}
{
    String srcType = "SaleReturnDetail";
    List<Relation> relations = new ArrayList<>();
    relations.add(new Relation(srcType, "cDeliveryNo", "models.voucher.SaleReturnPrice", "cVoucherNo"));
    metaMap.put(srcType, relations);
}
```

为了最终能够更通用的处理业务关系，我们选择通过元数据构造查询方案的方式来处理复杂业务数据查询。前端通过构造强大可自由定制的元数据查询方案来统一处理集合数据查询。

```
{
	"fields":[
		{"name":"(num?0)*(price?(goods.price?5))","alias":"totalmoney"},
		{"name":"belongOrder"},
		{"name":"belongOrder.code"},
		{"name":"num","aggr":"sum"},
		{"name":"price","aggr":"avg"},
		{"name":"1","alias":"totalcount","aggr":"count"}
	],
	"conditions":[
		{"op":"or","items":[
				{"op":"and","items":[
						{"name":"(num?0)*(price?(goods.price?1))/100","v1":"50","op":"gt"},
						{"name":"goods.name","v1":"电器","op":"leftlike"},
						{"name":"price","v1":"5","v2":"10","op":"between"}
					]
				},
				{"op":"and","items":[
						{"name":"belongOrder.status","v1":"1,2","op":"in"},
						{"name":"belongOrder.belongUser","op":"is_not_null"}
					]
				}
			]
		}
	],
	"groups":[
		{"name":"belongOrder"},
		{"name":"belongOrder.code"}
	],
	"orders":[
		{"name":"belongOrder.code","order":"desc"}
	],
	"pager":{"pageIndex":1,"pageSize":10}
}
```

这样的数据经过后台处理后，为了能结合实体对象处理，最终会生成hql，但是因为没有通过Hibernate的方式定义实体对象的数据关系，最终生成的hql在生成最终的原生sql时会变成通过cross join的方式处理数据关联。但是其实因为这些数据只是没有通过hql的方式定义，他们之间的关系完全是left join或者inner join的。

所以我们的方案是通过查询方案生成hql后，通过类似Hibernate测试用例中所用的方式来将hql处理成原生sql后再将原生sql中的cross join替换成left join。最终再以原生sql的方式来处理。当然这是基于我们数据处理的方式和关系决定的。
这样既不失高效，又能用上hql的面向对象。

**但是据说Hibernate在5.1之后已经解决了cross join的问题**
[Hibernate ORM](https://hibernate.atlassian.net/projects/HHH/issues/HHH-16?filter=allissues&orderby=votes+DESC%2C+priority+DESC%2C+updated+DESC)

回头可以试一下。