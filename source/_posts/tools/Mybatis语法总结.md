
---
title: Mybatis语法总结
date: 2017-06-14 00:00:00
reward: true
categories:
    - tools
tags:
    - Mybatis
---

![mybatis](http://static.xcoder.ren/public/resource/mybatis.png)

## 动态传入查询字段和where

```markdown
   <sql id="query_columns">
       userName,id,sex,age,phone
    </sql>

    <select id="queryUsers" resultType="com.xx.user.User"
            parameterType="java.util.Map">
        select
        <include refid="query_columns"/>
        from user
        <where>
            <if test="null!=phone">
            phone = #{phone}
            </if>
        </where>

    </select>
```
查询条件通过sql标签动态传入
通过where节点的处理能防止传入phone为null时出现``select userName,id,sex,age,phone from user where ``导致的尴尬异常.
<!--more-->
## choose
choose标签是按顺序判断其内部when标签中的test条件出否成立，如果有一个成立，则 choose 结束。当 choose 中所有 when 的条件都不满则时，则执行 otherwise 中的sql。类似于Java 的 switch 语句，choose 为 switch，when 为 case，otherwise 则为 default。
因为\<if>...\</if>并没对应的<else>标签，所以要达到\<if>...\<else>...\</else> \</if>的效果，得借助\<choose>、\<when>、\<otherwise>组合使用
```markdown
<select id="queryUsers" resultType="com.xx.user.User" parameterType="java.util.Map">  
    SELECT *  
      FROM User u   
    <where>  
        <choose>  
            <when test="userName !=null ">  
                u.userName LIKE CONCAT(CONCAT('%', #{userName, jdbcType=VARCHAR}),'%')  
            </when >  
            <when test="sex != null and sex != '' ">  
                AND u.sex = #{sex, jdbcType=INTEGER}  
            </when >  
            <when test="birthday != null ">  
                AND u.birthday = #{birthday, jdbcType=DATE}  
            </when >  
            <otherwise>  
            </otherwise>  
        </choose>  
    </where>    
</select>  

```

## List参数生成in条件

```markdown
<select id="queryUsers" resultType="com.xx.user.User" parameterType="java.util.Map"> 
select * from user
<where>
   <if test="null!=ids and ids.size()>0">
               id in 
               <foreach item="item" index="index" collection="ids" open="("
                        separator="," close=")">
                   #{item}
               </foreach>
           </if>
    
</where>
</select>

```

## 使用#{}参数化防止SQL注入
```markdown
<select id="queryUsers" resultType="com.xx.user.User"
            parameterType="java.util.Map">
        select *
        from user
        <where>
            <if test="null!=phone">
            phone = #{phone}
            </if>
        </where>

    </select>
```
## \#{}和${}的区别和使用场景

* \#将传入的数据都当成一个字符串，会对自动传入的数据加一个双引号。如：order by #user_id#，如果传入的值是111,那么解析成sql时的值为order by "111", 如果传入的值是id，则解析成的sql为order by "id".
　　
* $将传入的数据直接显示生成在sql中。如：order by $user_id$，如果传入的值是111,那么解析成sql时的值为order by user_id,  如果传入的值是id，则解析成的sql为order by id.
　　
* \#方式能够很大程度防止sql注入。
　　
* $方式无法防止Sql注入。

* $方式一般用于传入数据库对象，例如传入表名.
　　
* 一般能用#的就别用$.

* 排序时使用order by 动态参数时需要注意，用$而不是#

### 说明

默认情况下，使用#{}格式的语法会导致MyBatis创建预处理语句属性并以它为背景设置安全的值（比如?）。这样做很安全，很迅速也是首选做法，有时你只是想直接在SQL语句中插入一个不改变的字符串。比如，像ORDER BY，你可以这样来使用：
ORDER BY ${columnName}
这里MyBatis不会修改或转义字符串。

重要：接受从用户输出的内容并提供给语句中不变的字符串，这样做是不安全的。这会导致潜在的SQL注入攻击，因此你不应该允许用户输入这些字段，或者通常自行转义并检查。

1. 使用#{}格式的语法在mybatis中使用Preparement语句来安全的设置值，执行sql类似下面的：
```markdown
PreparedStatement ps = conn.prepareStatement(sql);
ps.setInt(1,id);
```
这样做的好处是：更安全，更迅速，通常也是首选做法。

2. 不过有时你只是想直接在 SQL 语句中插入一个不改变的字符串。比如，像 ORDER BY，你可以这样来使用：

ORDER BY ${columnName}
此时MyBatis 不会修改或转义字符串。

这种方式类似于：
```markdown
Statement st = conn.createStatement();       
ResultSet rs = st.executeQuery(sql);
```
这种方式的缺点是： 以这种方式接受从用户输出的内容并提供给语句中不变的字符串是不安全的，会导致潜在的 SQL 注入攻击，因此要么不允许用户输入这些字段，要么自行转义并检验。

## statementType属性

这个属性的作用是告诉mybatis我们写的这个sql到底是预编译（PRESTATEMENT）还是非预编译（STATEMENT）的。有什么区别呢？如果是预编译的，那么系统在初始化时就会读取这段sql代码，将指定的实体类中的字段替换了类似#{}这样的语句，就是形成了类似这样的语句：
"select * from tableName where code=?" 这个时候你在系统运行时再想向这句sql中替换tableName或者code，结果可想而知。如果是非预编译呢，结果刚好相反，他会在系统运行时才会去生成这样类似的语句。此时就可以去替换这些动态的字段或者表名之类。这样在结合之前所讲的返回类型的设置，我们的问题就解决了
。我们可以不用设定参数和返回类型的实体类，只需要形成一个动态的表名和字段名的列表类。就可以动态对那些未知的物理模型进行操作.
注明statementType="CALLABLE"表示调用存储过程.

## 兼容多数据库
```markdown
<insert id="insert">
 <selectKey keyProperty="id" resultType="int" order="BEFORE">
 <if test="_databaseId == 'oracle'">
 select seq_users.nextval from dual
 </if>
 <if test="_databaseId == 'db2'">
 select nextval for seq_users from sysibm.sysdummy1"
 </if>
 </selectKey>
 insert into users values (#{id}, #{name})
</insert>
```

另一种

mybatis.xml中配置
```markdown
<databaseIdProvider type="DB_VENDOR">  
  <property name="SQL value="sqlserver"/>  
  <property name="DB2" value="db2"/>          
  <property name="Oracle" value="oracle" />    
  <property name="Adaptive Server Enterprise" value="sybase"/>     
  <property name="MySQL" value="mysql" />  
</databaseIdProvider><!-- name是数据库厂商名，value是你自己的标识名 --> 
```

mapper的xml中
```markdown
<select id="getCountOfSql" resultType="int" useCache="false" statementType="STATEMENT" timeout="5000" databaseId="mysql">  
        <![CDATA[ 
            SELECT COUNT(*) FROM user 
        ]]>  
    </select>  
      
    <select id="getCountOfSql" resultType="int" useCache="false" statementType="STATEMENT" timeout="5000" databaseId="oracle">  
        <![CDATA[ 
            SELECT COUNT(*) FROM user 
        ]]>  
    </select>      
```

一个运用了其中内容的查询配置
```markdown
<mapper namespace="com.a.b.dao">
    <sql id="query_other_columns">
        count(id) as srvCount,
        sum(settlemoney) as srvSettle,sum(receivedmoney) as srvReceived,sum(settlemoney-receivedmoney) as srvNotReceived,
        sum(agentmoney) as srvAgent,
        sum(settlemoney+agentmoney) as srvMoney,
        sum(case ifNull(bizstatus,0) when 2 then 1 else 0 end) as srvCompleted,sum(case when ifnull(bizstatus,0)!=2 then 1 else 0 end ) as srvNotCompleted,
        group_concat(id) as srvIds
    </sql>
    <sql id="query_week_columns">
        week(vouchdate) as srvDate,<include refid="query_other_columns"/>
    </sql>
    <sql id="query_year_columns">
        DATE_FORMAT(vouchdate, '%Y') as srvDate,<include refid="query_other_columns"/>
    </sql>
    <sql id="query_quarter_columns">
        CONCAT(YEAR(vouchdate),'_',QUARTER(vouchdate),'Q') as srvDate,<include refid="query_other_columns"/>
    </sql>
    <sql id="query_month_columns">
        DATE_FORMAT(vouchdate, '%Y-%m月') as srvDate,<include refid="query_other_columns"/>
    </sql>
    <sql id="query_date_columns">
        date(vouchdate) as srvDate,<include refid="query_other_columns"/>
    </sql>
    <select id="queryReport" resultType="java.util.Map" parameterType="com.a.b.vo.Report">
        select
        <choose>
            <when test=" type == 1">
                <include refid="query_year_columns"/>
            </when>
            <when test=" type == 2">
                <include refid="query_quarter_columns"/>
            </when>
            <when test=" type == 3">
                <include refid="query_month_columns"/>
            </when>
            <when test=" type == 4">
                <include refid="query_week_columns"/>
            </when>
            <when test=" type == 5">
                <include refid="query_date_columns"/>
            </when>
            <otherwise>
                <include refid="query_date_columns"/>
            </otherwise>
        </choose>
        from sr_srvvouch
        <where>
            tenant=#{tenant}
            <choose>
                <when test=" ( type == 1 or type == 6)">
                    and DATE_FORMAT(vouchdate, '%Y')=DATE_FORMAT(now(), '%Y')
                </when>
                <when test=" ( type == 2 or type == 7)">
                    and CONCAT(YEAR(vouchdate),'_',QUARTER(vouchdate),'Q')=CONCAT(YEAR(now()),'_',QUARTER(now()),'Q')
                </when>
                <when test=" ( type == 3 or type ==8)">
                    and DATE_FORMAT(vouchdate, '%Y-%m月')=DATE_FORMAT(now(), '%Y-%m月')
                </when>
                <when test=" ( type == 4 or type==9)">
                    and week(vouchdate)=week(now())
                </when>
                <when test=" type == 5 and startTime==null and endTime==null">
                    and date(vouchdate)=date(now())
                </when>
                <otherwise>
                    <if test=" startTime!=null and endTime!=null">
                        and vouchdate between #{startTime} and #{endTime}
                    </if>
                </otherwise>
            </choose>
            <if test=" customerName!=null">
                and customer_id in (select id from customer where name like CONCAT(CONCAT('%', #{customerName, jdbcType=VARCHAR}),'%'))
            </if>
            <if test=" providerName!=null">
                and corpration_id in (select id from corpration where name like CONCAT(CONCAT('%', #{providerName, jdbcType=VARCHAR}),'%'))
            </if>
        </where>
        <choose>
            <when test=" type == 1">
                group by DATE_FORMAT(vouchdate, '%Y')
            </when>
            <when test=" type == 2">
                group by CONCAT(YEAR(vouchdate),'_',QUARTER(vouchdate),'Q')
            </when>
            <when test=" type == 3">
                group by DATE_FORMAT(vouchdate, '%Y-%m月')
            </when>
            <when test=" type == 4">
                group by week(vouchdate)
            </when>
            <when test=" type == 5">
                group by date(vouchdate)
            </when>
            <otherwise>
                group by date(vouchdate)
            </otherwise>
        </choose>
        order by vouchdate asc;
    </select>

</mapper>
```