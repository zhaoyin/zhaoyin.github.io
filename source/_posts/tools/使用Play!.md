
---
title: 使用PlayFramework开发Web应用
date: 2017-05-10 22:10:20
reward: true
categories:
    - tools
tags:
    - playframework
---

## 请求的生命周期

![请求的生命周期](http://oqcey66z7.bkt.clouddn.com/public/resource/%E8%AF%B7%E6%B1%82%E7%9A%84%E7%94%9F%E5%91%BD%E5%91%A8%E6%9C%9F.png)

Play框架是一个完全的stateless框架，而且只面向request/response。所有的http请求都遵循以下过程：
一个http请求被框架接收。
Router组件试着找到能够接收这个请求的确切路由，相应的action方法随后被调用。
应用程序代码被执行。
如果需要生成一个复杂的view，那么一个模板文件将会被渲染。
acton方法的结果（http 响应代码、内容）随后被作为http response发出。

<!--more-->

## 控制器
在Play框架中，商业逻辑在domain model层里进行管理，Web客户端不能直接调用这些代码，domain对象的功能作为URI资源暴露出来。
客户端使用HTTP协议提供的统一API来暗中操作这些底层的商业逻辑实现资源的维护。然而，这些domain对象到资源的映射并不是双向注入的：它可以表示成不同级别的粒度，一些资源可能是虚拟的，某些资源的别名或许已经定义了…
这正是控制器层发挥的作用：它在模型对象和传输层事件之间提供了粘合代码。和模型层一样，控制器也是纯java书写的代码，这样控制器层就很容易访问和修改model对象。和http接口类似，控制器是一个面向Request/Response的程序。
控制器层减少了http和模型层之间的阻抗。
### 控制器概览
一个controller就是一个java类，位于controller包下，是play.mvc.Controller的一个子类。
```angularjs
package controllers;
 
import models.Client;
import play.mvc.Controller;
 
public class Clients extends Controller {
 
    public static void show(Long id) {
        Client client = Client.findById(id);
        render(client);
    }
 
    public static void delete(Long id) {
        Client client = Client.findById(id);
        client.delete();
    }
 
}
```

控制器中的每个public、static方法叫做Action（动作）。action动作方法签名总是如下：
``public static void action_name(params...);``
在action方法签名里可以定义参数，这些参数值会被框架自动从相应的http参数里找到。
通常情况下，一个action方法不包括return字段，方法退出是通过调用result方法完成的，在上面的示例里，render()就是一个result方法，用于执行和显示一个模板。
### 获取http参数
一个HTTP请求包含有数据。这些数据可以从如下渠道提取：
•	URI路径：比如/clients/1541请求, 1541就是URI范示的动态部分
•	请求字符串：/clients?id=1541
•	请求体：如果是通过html窗体发送的请求，请求体就包含有以x-www-urlform-encoded方式编码的窗体数据
所有这些情况下，play都会自动进行数据提取，并存入同一个Map<String, String[]> ，这里面包含有所有的HTTP参数。key就是参数名name，具体从以下方式确定：
•	URI范示的动态部分名称（和在routes文件里指定的一样） 
•	查询字符串里的name-value pair中的name
•	x-www-urlform-encoded体的内容
#### 使用params map
params对象是一个可用于任何控制器类的变量（在play.mvc.Controller超类中定义的），这个对象包含了所有从当前http请求找到的参数。
```angularjs
public static void show() {
    String id = params.get("id");
    String[] names = params.getAll("names");
}
```
你也可以让Play帮助完成类型转换:
```angularjs
public static void show() {
    Long id = params.get("id", Long.class);
}
```
你还有更好的方式完成类型转换，如下：
还可以从action方法签名实现转换
你可以直接从action方法签名里取回http参数。但Java参数的名称必须和http参数的名称相同：
比如下面的请求:
``/clients?id=1451``
一个action方法可以通过在其方法签名里声明一个id参数来取回id参数值：
```angularjs
public static void show(String id) {
    System.out.println(id); 
}
```
还可以使用其他java类型，比如String。在这种情况下，框架将试着预测参数值的正确类型：
```angularjs
public static void show(Long id) {
    System.out.println(id);  
}
```
如果某个参数具有多个值，则可以声明一个数组参数：
```angularjs
public static void show(Long[] id) {
    for(String anId : id) {
        System.out.println(anid); 
    }
}
```
或是一个集合类型：
```angularjs
public static void show(List<Long> id) {
    for(String anId : id) {
        System.out.println(anid); 
    }
}
```
例外情况！

如果在action方法参数里找不到http参数对应的参数，则相应的方法参数将默认设置为默认值（对象类型为null，数字类型为0）。如果能够在action方法参数里找到对应参数，但框架不能预测需要的java类型， play将在validation error集合里增加一个错误，并使用默认值。
#### 高级HTTP Java绑定
* 简单类型
所有本地的和通用的java类型都是自动进行绑定的：
int, long, boolean, char, byte, float, double, Integer, Long, Boolean, Char, String, Byte, Float, Double
注意：如果http请求的参数丢失或自动类型转换失败，对象类型将置null，简单类型将设置为其默认值。
* Date类型
如果日期的字符串输出匹配下面的范示，，日期对象将进行自动绑定：
•	yyyy-MM-dd’T’hh:mm:ss’Z' // ISO8601 + 时区 
•	yyyy-MM-dd’T’hh:mm:ss" // ISO8601 
•	yyyy-MM-dd 
•	yyyyMMdd’T’hhmmss 
•	yyyyMMddhhmmss 
•	dd'/‘MM’/'yyyy 
•	dd-MM-yyyy 
•	ddMMyyyy 
•	MMddyy 
•	MM-dd-yy 
•	MM'/‘dd’/'yy
使用@As注释，你可以指定日期格式：
``archives?from=21/12/1980``
```angularjs
public static void articlesSince(@As("dd/MM/yyyy") Date from) {
    List<Article> articles = Article.findBy("date >= ?", from);
    render(articles);
}
```
你也可以依照对应的语言调整日期格式：
```angularjs
public static void articlesSince(@As(lang={"fr,de","*"}, 
        value={"dd-MM-yyyy","MM-dd-yyyy"}) Date from) {
    List<Article> articles = Article.findBy("date >= ?", from);
    render(articles);
}
```

在这个示例里，我们假定法语和德语的日期格式为dd-MM-yyyy，其他语言的日期格式为MM-dd-yyyy。请注意lang和value可以用逗号进行分隔。最为重要的是lang的数字型参数匹配的是value的数字型参数。 
如果没有指定@As注释，那么play将依照访问者的时区使用默认的日期格式。date.format configuration可以指定默认的日期格式。
* Calendar日历
日历可以精确与日期进行绑定，除非play依照你的时区来选择Calendar对象，还可以使用@Bind注释。
* File
在play里，实现文件上传非常简单。首先使用一个multipart/form-data编码格式的请求来传送文件到服务器，然后使用ava.io.File类型来取回上传的文件对象：
```angularjs
public static void create(String comment, File attachment) {
    String s3Key = S3.post(attachment);
    Document doc = new Document(comment, s3Key);
    doc.save();
    show(doc.id);
}
```
上传到服务器的文件名称和原始文件名称一致。首先，上传的文件会暂时保存在服务器的tmp临时目录，当请求结束时，该文件将被删除。因此，你必须把这个文件复制到安全的目录。
上传文件的MIME类型，通常情况下在http请求的Content-type header里已经 指定。然而，当从一个Web浏览器上传文件时，一些不常见的文件可能不会为其指定MIME类型。在这种情况，你可以手工使用play.libs.MimeTypes类映射文件的扩展名到某个MIME类型。
String mimeType = MimeTypes.getContentType(attachment.getName()); 
play.libs.MimeTypes类将查找$PLAY_HOME/framework/src/play/libs/mime-types.properties里设定的文件扩展名来得到MIME类型。
使用Custom MIME types configuration配置，你也可添加你自己的MIME类型。
* 支持类型的数组或集合
所有支持类型都可以当作对象的集合或数组取回：
```angularjs
public static void show(Long[] id) {
    …
}
```
或:
```angularjs
public static void show(List<Long> id) {
    …
}
```
或:
```angularjs
public static void show(Set<Long> id) {
    …
}
```
Play也可以处理特殊的Map<String, String>绑定，比如：
```
public static void show(Map<String, String> client) {
    …
}
```
下面这个查询字符串:
``?client.name=John&client.phone=111-1111&client.phone=222-2222``
将绑定client变量到一个带有两个元素的map。第一个元素为name:John(key/value)，第二个元素为phone: 111-1111, 222-2222(同一个key,两个值)。
* POJO对象绑定
使用同样的命名转换规则，Play也可自动对任何model类进行绑定。
```angularjs
public static void create(Client client ) {
    client.save();
    show(client);
}
```
使用上面这个create方法，创建一个client的查询字符串可以是下面这个样式：
``?client.name=Zenexity&client.email=contact@zenexity.fr``
Play将创建一个Client实例，同时把从http参数里取得的值赋值给对象中与http参数名同名的属性。不能明确的参数将被安全忽略，类型不匹配的也会被安全忽略。
参数绑定是通过递归来实现的，也就是说你可以采用如下的查询字符串来编辑一个完整的对象图（object graphs）：
```angularjs
?client.name=Zenexity
&client.address.street=64+rue+taitbout
&client.address.zip=75009
&client.address.country=France
```
使用数组标记（即[]）来引用对象的id，可以更新一列模型对象。比如，假设Client模型有一列Customer模型声明作为List Customer customers。为了更新这列Customers对旬，你需要提供如下查询字符串：
```angularjs
?client.customers[0].id=123
&client.customers[1].id=456
&client.customers[2].id=789
```
* JPA 对象绑定
使用http到java的绑定，可以自动绑定一个JPA对象。
比如，在http参数里提供了user.id字段，当play找到id字段里，play将从数据库加载匹配的实例进行编辑，随后会自动把其他通过http请求提供的参数应用到实例里，因此在这里可以直接使用save()方法，如下：
```angularjs
public static void save(User user) {
    user.save(); // ok with 1.0.1
}
```
和在POJO映射里采取的方式相同，你可以使用JPA绑定来编辑完整的对象图（object graphs）,唯一区别是你必须为每个打算编辑的子对象提供id:
```angularjs
user.id = 1
&user.name=morten
&user.address.id=34
&user.address.street=MyStreet 
```
#### 定制绑定
绑定系统现在支持更多的定制化。
``@play.data.binding.As``
首先是@play.data.binding.As注释，这个注释使上下方相关的配置进行绑定成为可能。比如，你可以使用这个注释来明确指定日期必须使用DateBinder进行格式化:
```angularjs
public static void update(@As("dd/MM/yyyy") Date updatedAt) {
    …
}
```
@As注释也提供了国际化支持，也就是说你可以为每个时区提供一个特定的注释：
```angularjs
public static void update(
        @As(
            lang={"fr,de","en","*"},
            value={"dd/MM/yyyy","dd-MM-yyyy","MM-dd-yy"}
        )
        Date updatedAt
    ) {
    …
}
```
@As可以和所有支持它的绑定一起工作，包含你自己的绑定，比如使用ListBinder:
```angularjs
public static void update(@As(",") List<String> items) {
    …
}
```
这个绑定简单使用逗号分隔List里的String。 
``@play.data.binding.NoBinding``
@play.data.binding.NoBinding注释允许你标记一个非绑定字段，以解决潜在的安全问题。比如：
```angularjs
public class User extends Model {
    @NoBinding("profile") public boolean isAdmin;
    @As("dd, MM yyyy") Date birthDate;
    public String name;
}
 
public static void editProfile(@As("profile") User user) {
    …
}
```
在这种情况下， isAdmin字段绝不会被editProfile action绑定, 即使某个恶意用户在伪造的窗体post里写入了user.isAdmin=true代码。
``play.data.binding.TypeBinder``
@As注释也允许你定制一个绑定。一个定制绑定必须是TypeBinder接口的子类，比如：
```angularjs
public class MyCustomStringBinder implements TypeBinder<String> {
 
    public Object bind(String name, Annotation[] anns, String value, 
    Class clazz) {
        return "!!" + value + "!!";
    }
}
```
这样，你就可以在任何action里使用这个绑定了，比如：
```angularjs
public static void anyAction(@As(binder=MyCustomStringBinder.class) 
String name) {
    …
}
```
``@play.data.binding.Global``
作为选择，你可以定义一个全局性的定制绑定，这样的绑定将应用于相应的类型。比如，为java.awt.Point类定制了一个绑定，如下：
```angularjs
@Global
public class PointBinder implements TypeBinder<Point> {
 
    public Object bind(String name, Annotation[] anns, String value, 
    Class class) {
        String[] values = value.split(",");
        return new Point(
            Integer.parseInt(values[0]),
            Integer.parseInt(values[1])
        );
    }
}
```
正如你所看到的，一个全局性绑定就是一个使用@play.data.binding.Global进行注释的传统绑定。通过这种方式，一个外部模块可以将其定制的绑定应用到一个项目里，这就为定义一个可重用的绑定扩展提供了方法。
#### 结果类型
一个action方法必须生成一个http response响应，最简便的方法就是放出一个结果Result对象。当一个Result对象被放出时，常规的执行流程被中断，方法退出。比如:
```angularjs
public static void show(Long id) {
    Client client = Client.findById(id);
    render(client);
    System.out.println("这个消息永远不会显示~! ");
}
```
render(…)方法放出一个Result对象，并停止方法执行。
##### 返回一些文本类型的内容
renderText(…)方法放出一个简单的Result事件，只在底层的http Response里写入了一些简单的文本，比如：
```angularjs
public static void countUnreadMessages() {
    Integer unreadMessages = MessagesBox.countUnreadMessages();
    renderText(unreadMessages);
}
```
你也可使用java标准的格式化语法来格式化输出文本消息:
```angularjs
public static void countUnreadMessages() {
    Integer unreadMessages = MessagesBox.countUnreadMessages();
    renderText("There are %s unread messages", unreadMessages);
}
```
##### 返回一个JSON字符串
Play使用renderJSON(…)方法来返回一个JSON字符串。这个方法的作用是设置响应内容为application/json，同时返回一个JSON字符串。 
你可以指定你自己的JSON字符串，或把这个字符串传递到一个通过GsonBuilder进行串行化的对象里，比如：
```angularjs
public static void countUnreadMessages() {
    Integer unreadMessages = MessagesBox.countUnreadMessages();
    renderJSON("{\"messages\": " + unreadMessages +"}");
}
```
当然，如果面对一个更加复杂的对象结构，你可能会希望使用GsonBuilder来创建这个JSON字符串。
```angularjs
public static void getUnreadMessages() {
    List<Message> unreadMessages = MessagesBox.unreadMessages();
    renderJSON(unreadMessages);
}
```
当传递一个对象到rndoerJSON(…)方法时，如果你需要对JSON构建器进行更多控制，那么你可以把JSON串行化并把对象输入到定制的输出里。 
##### 返回一个XML字符串
和JSON方法一样，这里有几个可以直接从控制器渲染XML的方法。renderXml(…) 方法返回一个内容类型设置为text/xml的XML字符串。
在这里，你可指定自己的xml字符串，传递一个org.w3c.dom.Document对象，或传递一个将被XStream串行化的POJO对象，比如：
```angularjs
public static void countUnreadMessages() {
    Integer unreadMessages = MessagesBox.countUnreadMessages();
    renderXml("<unreadmessages>"+unreadMessages+"</unreadmessages>");
}
```
当然，你也可以使用org.w3c.dom.Document对象：
```angularjs
public static void getUnreadMessages() {
    Document unreadMessages = MessagesBox.unreadMessagesXML();
    renderXml(unreadMessages);
}
```
##### 返回二进制内容
向用户返回一个存储在服务器上的二进制文件需要使用renderBinary()方法。比如你有一个User对象，并且有一个play.db.jpa.Blob的图片属性。这时，就可以使用如下语句在一个控制器方法里加载这个模型对象，并使用对应的MIME类型渲染这个对象里的图片：
```angularjs
public static void userPhoto(long id) { 
   final User user = User.findById(id); 
   response.setContentTypeIfNotSet(user.photo.type());
   java.io.InputStream binaryData = user.photo.get();
   renderBinary(binaryData);
} 
```
##### 作为附件下载文件
通过设置http header，可以指示web浏览器把一个二进制响应当作“附件”来对待，这样就可以在web浏览器把文件下载到用户的电脑。为了完成这个任务，可以把一个文件的名称传递给renderBinary方法，并作为它的参数，这时play会自动设置Content-Disposition响应header。比如，当上面示例里的User模型作为一个photoFileName属性时：
``renderBinary(binaryData, user.photoFileName); ``
##### 执行一个模板
如果生成的内容，你应该使用模板来生成response内容。
```angularjs
public class Clients extends Controller {
 
    public static void index() {
        render();    
    }
}
```
模板名称且根据play约定自动进行推断。默认模板路径就是控制器和Action的名称。
在上面这个示例里调用的模板路径和名称如下:
``app/views/Clients/index.html``
* 向模板作用域添加数据
通常情况下，模板是需要数据的。你可以使用renderArgs对象添加数据到模板作用域：
```angularjs
public class Clients extends Controller {
 
    public static void show(Long id) {
        Client client = Client.findById(id);
        renderArgs.put("client", client);
        render();    
    }
}
```
在模板执行期间，client变量将被定义。
比如：``Client ${client.name}``
* 更加简洁的形式添加数据到模板作用域
使用render(…)方法的参数，可以把数据直接传递到模板：
```angularjs
public static void show(Long id) {
    Client client = Client.findById(id);
    render(client);    
}
```
在这种情况下，模板可以访问的变量与java局部变量的名称完全相同。当然，还可通过这种方式传递多个变量:
```angularjs
public static void show(Long id) {
    Client client = Client.findById(id);
    render(id, client);    
}
```
非常重要!

你只能通过这种方式向模板传递局部变量。
* 指定其他模板
如果不想使用默认的模板，可以使用renderTemplate(…)方法指定自己的模板文件，但模板名称要作为第一个参数:
如：
```angularjs
public static void show(Long id) {
    Client client = Client.findById(id);
    renderTemplate("Clients/showClient.html", id, client);    
}
```
* 跳转到其他URL
redirect(…)方法放出一个跳转事件， 用于切换生成一个http跳转响应。
```angularjs
public static void index() {
    redirect("http://www.zenexity.fr");
}
```
* Action链
play和Servlet API的forward不同，一个http请求只能调用一个action。如果你想要调用其他的action，就必须跳转浏览器到能够调用这个action的URL。通过这种方式，浏览器URL就总是和被执行的Action保持一致，因此对浏览器的back/forward/refresh管理就非常容易。
在java代码里，通过调用其他action方法，就可以实现发送一个跳转响应到任何action里，比如：
```angularjs
public class Clients extends Controller {
 
    public static void show(Long id) {
        Client client = Client.findById(id);
        render(client);
    }
 
    public static void create(String name) {
        Client client = new Client(name);
        client.save();
        show(client.id);
    }
}
```
上面的示例在使用下面这两条路由的情况下:
GET    /clients/{id}            Clients.show
POST   /clients                 Clients.create 
•	浏览器发送一个POST到/clients URL
•	路由调用Clients控制器的create action
•	action方法直接调用show action方法
•	Java调用被中断，反向路由生成器创建一个带id参数的Clients.show方法调用的URL
•	HTTP响应为： 302 Location:/clients/3132
•	浏览器随后发布GET /clients/3132
•	…
##### 定制web编码
play着重使用UTF-8编码，但某些情况下必须使用其他编码。
* 为当前response定制编码
要为当前response改变编码，可以控制器里参照下面的方法进行定制：
``response.encoding = "ISO-8859-1";``
当传递一个与服务器默认编码不同的窗体时，你应该在窗体里使用encoding/charset两次，两次都用在accept-charset属性指定上， 而且是用在一个名称叫_charset_的特殊隐藏窗体上。accept-charset属性会告诉浏览器在传递窗体里要使用哪种编码，form-field _charset_ 则告诉play需要采用哪个编码进行处理：
```angularjs
<form action="@{application.index}" method="POST" accept-charset="ISO-8859-1">
    <input type="hidden" name="_charset_" value="ISO-8859-1">
</form>
```
* 为整个应用程序定制编码
配置application.web_encoding 用于指定play与浏览器进行通信时需要采用哪种编码。
##### 拦截器
在控制器里，可以定义拦截器方法。拦截器将被控制器类及其后代的所有action调用。可以利用这个特点为所有的action定义一些通用的提前处理代码：比如对用户进行验证、加载请求作用域信息等…
这些方法必须是static的，但不能是public的，并且使用有效的拦截注释：
* @Before
用@Before注释的方法将在这个控制器的每个action被调用前执行。因此，可以利用这个注释创建一个安全检查方法：
```angularjs
public class Admin extends Controller {
 
    @Before
    static void checkAuthentification() {
        if(session.get("user") == null) login();
    }
 
    public static void index() {
        List<User> users = User.findAll();
        render(users);
    }
    …
}
```
如果不希望@Before方法中断所有的action调用，可以指定一个需要排除的Action列表：
```angularjs
public class Admin extends Controller {
 
    @Before(unless="login")
    static void checkAuthentification() {
        if(session.get("user") == null) login();
    }
 
    public static void index() {
        List<User> users = User.findAll();
        render(users);
    }
 
    …
}
```
如果希望@Before方法中断列表中的action调用，可以使用only参数：
```angularjs
public class Admin extends Controller {
 
    @Before(only={"login","logout"})
    static void doSomething() {  
        …  
    }
    …
}
```
unless和only 参数也可用于@After, @Before和@Finally注释。
* @After
用@After注释的方法将在每个action调用执行完后执行。
```angularjs
public class Admin extends Controller {
 
    @After
    static void log() {
        Logger.info("Action executed ...");
    }
 
    public static void index() {
        List<User> users = User.findAll();
        render(users);
    }
 
    …
}
```
* @Catch
用@Catch注释的方法将在其他action方法抛出指定异常时执行。这个被抛出的异常将作为参数传递给@Catch注释的方法。
```angularjs
public class Admin extends Controller {
	
    @Catch(IllegalStateException.class)
    public static void logIllegalState(Throwable throwable) {
        Logger.error("Illegal state %s…", throwable);
    }
    
    public static void index() {
        List<User> users = User.findAll();
        if (users.size() == 0) {
            throw new IllegalStateException("Invalid database - 0 users");
        }
        render(users);
    }
}
```
和普通的java异常处理一样，你可以捕获一个超类来捕获更多的异常类型。如果不只一个捕获方法，可以指定他们的priority（优先级）参数，以确定执行顺序（1是最高优先级）。
```angularjs
public class Admin extends Controller {
 
    @Catch(value = Throwable.class, priority = 1)
    public static void logThrowable(Throwable throwable) {
        // Custom error logging…
        Logger.error("EXCEPTION %s", throwable);
    }
 
    @Catch(value = IllegalStateException.class, priority = 2)
    public static void logIllegalState(Throwable throwable) {
        Logger.error("Illegal state %s…", throwable);
    }
 
    public static void index() {
        List<User> users = User.findAll();
        if(users.size() == 0) {
            throw new IllegalStateException("Invalid database - 0 users");
        }
        render(users);
    }
}
```
* @Finally
用@Finally注释的方法总是在这个控制器里的每个action调用执行后被执行。用@Finally注释的方法，不管action调用是否成功也会执行。
```angularjs
public class Admin extends Controller {
 
    @Finally
    static void log() {
        Logger.info("Response contains : " + response.out);
    }
 
    public static void index() {
        List<User> users = User.findAll();
        render(users);
    }
    …
}
```
如果 @Finally注释的方法带有一个Throwable类型的参数，那么有异常发生时，异常将会传送到方法里面来。
```angularjs
public class Admin extends Controller {
 
    @Finally
    static void log(Throwable e) {
        if( e == null ){
            Logger.info("action call was successful");
        } else{
            Logger.info("action call failed", e);
        }
    }
 
    public static void index() {
        List<User> users = User.findAll();
        render(users);
    }
    …
}
```
* 控制器继承
如果一个控制器类是其他控制器类的子类，那么拦截器也会按照继承顺序应用于相应层级的子类。
* 使用@With注释添加更多的拦截器
Because Java does not allow multiple inheritance, it can be very limiting to rely on the Controller hierarchy to apply interceptors. But you can define some interceptors in a totally different class, and link them with any controller using the @With annotation.由于java不允许多继承，通过控制器继承特点来应用拦截器就受到极大的限制。但是我们可以在一个完全不同的类里定义一些拦截器，然后在任何控制器里使用@With注释来链接他们。
比如：
```angularjs
public class Secure extends Controller {
    
    @Before
    static void checkAuthenticated() {
        if(!session.containsKey("user")) {
            unAuthorized();
        }
    }
} 
``` 
另一个控制器:
```angularjs
@With(Secure.class)
public class Admin extends Controller {
    
    …
}
```
##### Session和Flash作用域
为了在多个http请求间保存数据，你可以把这些数据存入Session或Flash作用域。存储在Session里的数据在整个用户session期间是可用的，存储在Flash里的数据只在下一个请求里可用。
明白把session和flash数据通过Cookie机制存储在每个请求客户端电脑里而不是存储在服务器上这点很重要，这就确定了数据大小不能超过最多4kb，而且只能存储字符串类型的值。
当然，play已经为cookie指派了一个安全key,因此客户端不能编辑cookie数据（否则cookie将无效）。因此play框架不打算把session用作缓存，如果你需要缓存一些与session相关的数据，你可以使用Play内建的缓存机制，并用session.getId()key来保存某个特定用户session相关的数据，比如：
```angularjs
public static void index() {
    List messages = Cache.get(session.getId() + "-messages", List.class);
    if(messages == null) {
        // Cache miss
        messages = Message.findByUser(session.get("user"));
        Cache.set(session.getId() + "-messages", messages, "30mn");
    }
    render(messages);
}
```
当你关闭浏览器里，session就过期了。除非对application.session.maxAge进行了配置。
play里的缓存和传统的Servlet HTTP session对象的概念完全不同。千万不要认为这些缓存了的对象会永远在缓存里。因此，play会强迫你去处理缓存丢失的情况，以防止缓存数据丢失，这样就保证了应用程序是完全无状态的。
## 模板引擎
Play有一个高效的模板系统，它允许动态生成html、xml、json或其他文本格式的文档。Play的模板引擎使用Groovy作为表达式语言。它的标签系统允许你创建一些可以重复使用的功能。
模板默认存储在app/views目录下。
### 模板语法
模板文件是一个文本文件，其中的一些占位符用于动态生成内容。模板的动态元素是用groovy语言写的。Groovy语法非常接近java的语法。
动态元素在模板执行期间被提取出来，最后以http response方式返回给客户端。
* Expressions: ${…}
要创建一个动态元素，最简单的方法就是声明一个表达式。语法为${…}，表达式的最终结果将被插入在表达式使用的地方。
如:
``Client ${client.name}``
如果不确定client对象是否为null，则可以使用如下的groovy语法:
``Client ${client?.name}``
如果client不为null，则显示，否则不显示。
* Template decorators : #{extends /} and #{doLayout /}
Decorators(装饰？母版)提供了一个清晰的解决方案来在多个不同的模板间共享同一个页面布局（或设计）。
使用#{get} 和 #{set}标签来在模板和decorator（母版）之间共享变量。
在decorator（母版）里嵌入一个页面就是一行代码的事：
```
#{extends 'simpledesign.html' /}
 
#{set title:'A decorated page' /}
```
This content will be decorated.
decorator（母版）文件simpledesign.html的代码为：
```
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <title>#{get 'title' /}</title>
  <link rel="stylesheet" type="text/css" href="@{'/public/stylesheets/main.css'}" />
</head>
<body>
  <h1>#{get 'title' /}</h1>
  #{doLayout /}
  <div class="footer">Built with the play! framework</div>
</body>
</html>
```
* Tags: ``#{tagName /}```
一个tag就是一个可以带参数的模板碎片，如果只有一个参数，则默认的参数名称就是arg，而且arg可以省略。
例如，如下的tag用于插入一个javascript脚本:
``#{script 'jquery.js' /}``
tag必须是关闭的:
``#{script 'jquery.js' /}``
或
```angularjs
#{script 'jquery.js'}
#{/script}
```
例如，list标签用于迭代所有的集合元素，它带有两个必须的参数items和as:
```angularjs
<h1>Client ${client.name}</h1>
<ul>
    #{list items:client.accounts, as:'account' }
        <li>${account}</li>
    #{/list}
</ul>
```
所有的动态表达式将被模板引擎转义以避免XSS安全问题（XSS:跨站脚本攻击），因此下列的title变量将被转义:
``${title} --> &lt;h1&gt;Title&lt;/h1&gt;``
如果不想转义，可以明确调用raw()方法:
``${title.raw()} --> <h1>Title</h1>``
当然，如果你想显示一个较多内容的raw html，你可以使用#{verbatim /}标签:
```angularjs
#{verbatim}
    ${title} --> <h1>Title</h1>
#{/verbatim}
```
* Actions: @{…} or @@{…}
可以使用Route来反向找到URL相应的特定route配置，在模板里，可以使用@{…}语法来完成这个任务，主要用于生成URL链接。
示例:
```angularjs
<h1>Client ${client.name}</h1>
<p>
   <a href="@{Clients.showAccounts(client.id)}">All accounts</a>
</p>
<hr />
<a href="@{Clients.index()}">Back</a>
```
//得到index()方法的链接
@@{…}语法与@{…}相似，不过它生成的绝对URL路径，对email很实用。
* Messages: &{…}
&{…}语法可用于国际化支持，以显示不同语言的消息：
例如在conf/messages目录下的文件里，我们可以这样定义:
clientName=The client name is %s
在模板里使用时:
``&{'clientName', client.name}``
* Comment: *{…}*
注释部分将被模板引擎忽略：
```angularjs
*{**** Display the user name ****}*
<div class="name">
    ${user.name}
</div>
```
* Scripts: %{…}%
脚本是一段复杂的表达式集合，在脚本内可以声明变量和定义一些语句，play使用%{…}%来插入一段脚本。
```angularjs
%{
   fullName = client.name.toUpperCase()+' '+client.forname;
}%
 
<h1>Client ${fullName}</h1>
```
在脚本里可以使用out对象直接输出动态内容：
```angularjs
%{
   fullName = client.name.toUpperCase()+' '+client.forname;
   out.print('<h1>'+fullName+'</h1>');
}%
```
在脚本里也可创建一个结构，比如用于迭代：
```angularjs
<h1>Client ${client.name}</h1>
<ul>
%{
     for(account in client.accounts) { 
}%
     <li>${account}</li>
%{
     }
}%
</ul>
```
请记住，模板不是一个放置复杂代码的好地方。因此，请使用tag代替或放置在在controller或model对象里。
* Template inheritance继承
模板可以被继承，比如模板被作为另外一个模板的一部分而被包含进去。
要继承另一个模板，请使用#{extends  ‘…’}:
```angularjs
#{extends 'main.html' /}
 
<h1>Some code</h1>
main.html模板是一个标准模板，它使用doLayout标签来包含本模板的内容：
<h1>Main template</h1>
 
<div id="content">
    #{doLayout /}
</div>
```

### 定制模板标签
一个tag就是一个模板文件，存储于app/views/tags目录下，模板文件名将用作tag名称。
例如，创建一个hello标签，只需在app/views/tags/目录下创建一个hello.html文件，其内容如下：
Hello from tag!
不需要任何配置，你就可以直接使用hello标签了:
``#{hello /}``
#### 检索tag参数
tag参数默认被暴露为模板变量，变量名称带有‘_’字符前缀。
例如: 
``Hello ${_name} !``
现在你就可以给name变量传递参数了:
``#{hello name:'Bob' /}``
如果你的tag只有一个参数，默认的参数名称是arg，而且可以忽略。
例如:
``Hello ${_arg}!``
使用更简单:
``#{hello 'Bob' /}``
#### 调用标签体
如果标签支持body，使用doBody标签，你就能在标签代码里的任何位置包含它。
比如：
``Hello #{doBody /}!``
然后你可使用这个名字作为标签体：
```angularjs
#{hello}
   Bob
#{/hello}
```

#### 格式化特定标签
你可以为不同的内容类型创建多个tag版本，play将自动选择适当的Tag。例如，play将使用app/views/tags/hello.html来处理request.format为html的内容，使用app/views/tags/hello.xml来处理格式为xml的请求。
如果内容格式不匹配， play将返回一个app/views/tags/hello.tag的处理结果。
### 定制java标签
你也可以使用java代码来定义一个定制tags。这和继承自play.templates.JavaExtensions类的JavaExtensions类相似，创建一个FastTag时，需要在类里创建一个方法，并且继承自play.templates.FastTags。每一个要当作tag来执行的方法都必须遵循如下的方法签名：
``public static void _tagName(Map<?, ?> args, Closure body, PrintWriter out, ExecutableTemplate template, int fromLine)``
注意：tag名称之前必须要有下划线”_”。
为了理解如何创建一个真正的tag，让我们看一下两个内建的tags。
比如，verbatim标签仅通过简单调用JavaExtensions的toString()方法来实现的，并且被传递给tag的body。
```angularjs
public static void _verbatim(Map<?, ?> args, Closure body, PrintWriter out, ExecutableTemplate template, int fromLine) {
   
   out.println(JavaExtensions.toString(body));
}
```
tag的body一定是在一对tag之间的（一开一关），即
``<verbatim>My verbatim</verbatim>``
Body的值应该是
My verbatim
第二个示例是option标签，要复杂一点，因为这个标签依赖于其父标签来实现相关功能。
```angularjs
public static void _option(Map<?, ?> args, Closure body, PrintWriter out, 
      ExecutableTemplate template, int fromLine) {
 
   Object value = args.get("arg");
   Object selection = TagContext.parent("select").data.get("selected");
   boolean selected = selection != null && value != null 
      && selection.equals(value);
 
   out.print("<option value=\"" + (value == null ? "" : value) + "\" " 
      + (selected ? "selected=\"selected\"" : "") 
      + "" + serialize(args, "selected", "value") + ">");
   out.println(JavaExtensions.toString(body));
   out.print("</option>");
}
```
这些代码将输出一个标准的html option标签，并依据父标签的值设置为相应的option为selected，前三行用于设置用于输出的变量。最后三行输出tag的结果。
在FastTags.java in github里有不同难度的标签示例。
* 标签命名空间
请检查你的tag在项目或与play标签之间没有冲突，你可以使用类级别的注释@FastTags.Namespace来设置命名空间。
因此，对hello标签来说，可以如下设置(空间名称为my.tags)
```angularjs
@FastTags.Namespace("my.tags") 
public class MyFastTag extends FastTags {
   public static void _hello (Map<?, ?> args, Closure body, PrintWriter out, 
      ExecutableTemplate template, int fromLine) {
      ...
   }
}
```
之后在模板里用如下方式进行调用。
``#{my.tags.hello/}``
### 在模板里的Java对象扩展
当你在模板引擎里使用一个java对象时，play为其加入了一些新的方法，这些方法在原始的java类里并不存在，而是被模板引擎动态加入到模板里的,play对一些基本的java原始类进行了扩展。
例如，为了方便在模板里对数字进行格式化，play在java.lang.Number里增加了一个format方法：
之后，我们在模板里就很容易对一个数字进行格式化：
```angularjs
<ul>
#{list items:products, as:'product'}
    <li>${product.name}. Price: ${product.price.format('## ###,00')} €</li>
#{/list}
</ul>
```
同样可用于java.util.Date
具体的内容见Java extensions，它列出了一些扩展了的方法，如下：
对集合的扩展：
```angularjs
join(‘/’)		用/进行连接后返回
last()				返回最后一个元素
pluralize()		是否大于1个，大于则返回一个字符串：集合名+s
pluralize(plural)		是否大于1个，大于则返回一个字符串：集合名+plural指定的字符串，如es
pluralize(singular,plural)		为1则返回集合名+singular指定的字符串，不为1则返回集合名+plural指定的字符串
对Date的扩展：
Format(foramt)		返回格式化后的日期，如new Date().format(‘dd  MMMM  yyyy))
Format(format,language)		带语言，如new Date().format(‘dd MM yy’,’en’)
Since()
Since(condition)
另外还对Long、Map、Number、对象、String、String数组等类型进行扩展。
```
* 创建定制扩展
只需要创建一个继承了play.templates.JavaExtensions的类即可。
例如，创建一个定制数字格式化的方法:
```angularjs
package ext;
 
import play.templates.JavaExtensions;
 
public class CurrencyExtensions extends JavaExtensions {
 
  public static String ccyAmount(Number number, String currencySymbol) {
     String format = "'"+currencySymbol + "'#####.##";
     return new DecimalFormat(format).format(number);
  }
 
}
```
每个扩展方法都是一个static方法，而且要返回一个java.lang.String结果，以便于在页面里显示。第一个参数将用于保存扩展后的对象。
使用方法如下：
``<em>Price: ${123456.324234.ccyAmount()}</em>``
模板扩展类会被play自动加载，你只需要重启你的应用程序即可。
* 模板里可以使用的保留对象
所有添加到renderArgs作用域的对象都将直接注入成模板变量。
例如，从controller向模板注入一个user bean：
renderArgs.put("user", user );
在一个action里渲染模板里时，框架会自动添加以下保留对象：
```angularjs
Variable 
Description 
API documentation 
See also 
errors 
Validation errors 
play.data.validation.Validation.errors() 
Validating HTTP data 
flash 
Flash scope 
play.mvc.Scope.Flash 
Controllers - Session & Flash Scope 
lang 
The current language 
play.i18n.Lang 
Setting up I18N - Define languages 
messages 
The messages map 
play.i18n.Messages 
Setting up I18N - Externalize messages 
out 
The output stream writer 
java.io.PrintWriter 

params 
Current parameters 
play.mvc.Scope.Params 
Controllers - HTTP parameters 
play 
Main framework class 
play.Play 

request 
The current HTTP request 
play.mvc.Http.Request 

session 
Session scope 
play.mvc.Scope.Session 
Controllers - Session & Flash Scope 
```
以上列出的名称和owner/delegate/it在Groovy里是默认的保留字，在创建变量时要注意回避。
## 域对象模型
模型是play应用程序中核心。是应用程序操作的信息的特定领域呈现。
Martin Fowler将之定义为：
模型层主要负责表现商业内容、商业状态和商业规则的信息。在这里主要进行商业状态控制和作用，相应技术细节则委托给基础设施。这个层是商业软件的最重要部分。
通用的java反映模式用许多简单的java Bean来映射模型以保存数据，应用程序逻辑被放入“service”层，用于操作模型对象。
Martin fowler把这种反映模式命名为贫血对象模型 Anemic object model: 
贫血对象模型的基本特征就是外表看起来就是一个真实的事物，但在模型里几乎没有行为，只有getter和setter，不能在模型对象里放入逻辑。模型的行为通过许多包括有域逻辑的service对象来实现。

这样的模型是和OO相反的，OO对象既有数据也有对象的方法。
### 属性模仿
在play里，类的变量都是public的。这引起java开发界的一些质疑。在java的标准教程里，为了对数据进行封闭，要求属性都是private的。这导致了一些批评。
java并没有真正的内建属性定义系统。只是一个Java Bean的约定：在java对象里的属性都要有getter和setter方法，如果属性是只读的，那么只能有getter。
虽然系统可以很好地工作，但编码十分乏味。每个属性都必须声明为私有变量并为此书写getter和setter。因此，许多时候，getter和setter实现都是相同的：
```angularjs
private String name;
 
public String getName() {
    return name;
}
 
public void setName(String value) {
    name = value;
}
```
在play里，play会为模型自动生成这些内容，以保证代码清晰。事实上，所有public变量都是实例属性。在play里约定为：类的任何public,non-static,no-final域都将以属性对待。
比如：
```angularjs
public class Product {
 
    public String name;
    public Integer price;
}
```
类在加载时，就变成了如下内容:
```angularjs
public class Product {
 
    public String name;
    public Integer price;
 
    public String getName() {
        return name;
    }
 
    public void setName(String name) {
        this.name = name;
    }
 
    public Integer getPrice() {
        return price;
    }
 
    public void setPrice(Integer price) {
        this.price = price;
    }
}
```
要访问一个属性里，只需要以下代码：
```angularjs
product.name = "My product";
product.price = 58;
```
在加载时会自动翻译为：
```angularjs
product.setName("My product");
product.setPrice(58);
```
注意！

在自动生成方式下，不能直接作用getter和setter方法来访问属性。这些方法仅存在于运行时状态，因此，如果在编写代码时调用这些方法，将导致不能找到方法的编译错误。
当然也可自行定义getter和setter方法。如果自行定义了这两个方法，play会自动使用这两个手工编写的方法。
为了保护Product类的price属性值，可以使用以下方法：
```angularjs
public class Product {
 
    public String name;
    public Integer price;
 
    public void setPrice(Integer price) {
        if (price < 0) {
            throw new IllegalArgumentException("Price can’t be negative!");
        }
        this.price = price;
    }
}
```
然后试着给price赋值一个负数时，就会抛出参数异常：
product.price = -10: // Oops! IllegalArgumentException
Play总是会使用已经手工定义好的getter或setter，如下：
```angularjs
@Entity
public class Data extends Model {
 
   @Required
   public String value;
   public Integer anotherValue;
 
   public Integer getAnotherValue() {
       if(anotherValue == null) {
           return 0;
       }
       return anotherValue;
   }
 
   public void setAnotherValue(Integer value) {
       if(value == null) {
           this.anotherValue = null;
       } else {
           this.anotherValue = value * 2;
       }
   }
 
   public String toString() {
       return value + " - " + anotherValue;
   }
 
}
```
在另外一个类里对上面的类进行断言:
```angularjs
Data data = new Data();
data.anotherValue = null;
assert data.anotherValue == 0;
data.anotherValue = 4
assert data.anotherValue == 8;
```
正常工作，这是因为增加了getter和setter的类遵循Java Bean约定。
### 设置数据库来持久化模型对象
很多时候都需要把模型对象数据永久保存，最自然的方式就是把数据存入数据库。
在开发期间，可以直接使用内建的数据库来临时保存数据到内存或一个子目录里。
play发布包里包含了H2和Mysql的JDBC驱动（$PLAY_HOME/framework/lib/）。如果打算使用PostgreSQL 或Oracle数据库，那么就需要把对应的jdbc驱动放入库目录里，或放入应用程序的lib目录。
连接到任何JDBC规范的数据，只需要设置jdbc的db.url, db.driver, db.user 和 db.pass属性：
```angularjs
db.url=jdbc:mysql://localhost/test
db.driver=com.mysql.jdbc.Driver
db.user=root
db.pass=
```
使用jpa.dialect属性可以为jpa定义方言。
在代码里，就可以从play.db.DB获取一个java.sql.Connection。
Connection conn = DB.getConnection();
conn.createStatement().execute("select * from products");
### 用hibernate持久化对象模型
使用hibernate来自动持久化java对象到数据库里。
在任何java对象增加 @javax.persistence.Entity注释就可以定义一个jpa实体。play会自动启动一个jpa实体管理器。
```angularjs
@Entity
public class Product {
 
    public String name;
    public Integer price;
}
```
注意！ 
一个经常发生的错误是使用hibernate的@Entity注释来代替JPA注释。请记住，play是通过hibernate来使用的jpa的api。也就是说要引入：javax.persistence.Entity包，而不是hibernate的包。
然后就可以从play.db.jpa.JPA获取一个EntityManager：
EntityManager em = JPA.em();
em.persist(product);
em.createQuery("from Product where price > 50").getResultList();

play提供了一个非常漂亮的支持类来处理jpa，只需要实体类继承play.db.jpa.Model即可。
@Entity
public class Product extends Model {
 
    public String name;
    public Integer price;
}
之后使用Product实例的简单方法就可以操作Product对象：
Product.find("price > ?", 50).fetch();
Product product = Product.findById(2L);
product.save();
product.delete();
### 保持模型stateless
play被设计成“什么都不共享”的机制。这个机制用于保持应用是完全无状态的。这样就允许程序可以同时运行于多个服务器节点。
Play 框架的设计架构就是无状态的。它没有提供服务器端的机制用来维护跨多个请求的数据。如果确实需要保存这样的数据的话，可以考虑下面几种方案： 
1.	如果数据很少很简单，可以存储在flash或session使用域里。但这些域只能存储小于4kb的数据，并且只能是字符串类型的数据。
2.	使用数据库，比如需要创建一个横跨多个请求的wizard对象：
o	在第一次请求时初始化并持久化对象到数据库中。
o	把新创建的对象的ID存储到flash或session域中。
o	在接下来的请求中，使用对象id找回数据、更新数据、再次存储等。
3.	暂时存储到Cache中，比如需要创建一个横跨多个请求的wizard对象：
o	在第一次请求时初始化并持久化对象到Cache中。
o	把新创建的对象的key存储到flash或session域中。
o	在接下来的请求中，使用正确的key找回数据、更新数据、再次存储等。
o	在结束最后一次请求后，把对象永久存储到数据库中。
Cache不是一个可靠的存储位置，在系统未出现故障时应该可以正确操作数据。但Cache是比Java Servlet session更好的选择。
## JPA持久化
play提供了一些非常有用的帮助类来简单管理jpa实体。
注意：如果需要，你仍旧可以继续使用原始的JPA API。
### 启动JPA实体管理器
当play找到至少一个注释了@javax.persistence.Entity标识的类时，play将自动启动hibernate实体管理器。前提是已经有一个正确的JDBC数据源配置，否则会导致失败。
### 获取JPA实体管理器
当JPA实体管理器启动后，就可以在应用程序代码中得到管理器，并使用JPA帮助类了，比如：
public static index() {
    Query query = JPA.em().createQuery("select * from Article");
    List<Article> articles = query.getResultList();
    render(articles);
}
### 事务管理
play会自动管理事务。当http请求到达，play就会为每个http请求启动一个事务。当http response发送的时候，就会把事务提交。如果代码抛出异常，事务将会自动回滚。
如果需要在代码中强制回滚事务，可以使用JPA.setRollbackOnly()方法，以告诉JPA不要提交当前事务。
也可使用注释明确哪些事务要进行处理。
如果在控制器里用@play.db.jpa.Transactional(readOnly=true)注释了控制器的某个方法，那么这个事务是只读的。
如果不想让play启动事务，可以使用以下注释@play.db.jpa.NoTransaction。
如果不想让类的所有方法执行事务，可以对控制器类进行注释： @play.db.jpa.NoTransaction.
当使用@play.db.jpa.NoTransaction注释时，Play不会从连接池中获取连接，以提高运行速度。
### play.db.jpa.Model支持类
在play中，这是最主要的帮助类，如果你的jpa实体继承了play.db.jpa.Model类，那么这个实体类将得到许多非常有用的方法来管理jpa访问。
比如下面的Post模型对象：

```angularjs
@Entity
public class Post extends Model {
   public String title;
    public String content;
public Date postDate;   
@ManyToOne
public Author author;   
@OneToMany
    public List<comment> comments;
}
```
play.db.jpa.Model类自动提供了一个自增长的Long id域。采用自增长的Long id主键对jpa模型来说是个好主意。
注意，我们事实上已经使用了play中的一特性，也就是说play会自动把Post类中的public成员认作属性。因此，我们不需要为这些成员书写setter/getter。
### 为GenreicModel定制id映射
play并不强制使用play.db.jpa.Model。你的JPA实体也可以继承play.db.jpa.GenericModel，如果不打算使用Long类型的id作为主键，就必须这样做。
比如，下面是一个非常简单的User实体类。它的id是UUID， name和mail属性都是非空值，我们使用Play验证进行强制检测：
```angularjs
@Entity
public class User extends GenericModel {
    @Id
    @GeneratedValue(generator = "system-uuid")
    @GenericGenerator(name = "system-uuid", strategy = "uuid")
public String id;

@Required public String name; 
@Required 
@MaxSize(value=255, message = “email.maxsize”) 
@play.data.validation.Email 
public String mail; 
} 
```

### Finding对象
play.db.jpa.Model提供了几种方式来查找数据，比如：
#### Find by ID
这是查找对象最简单的方式：
``Post aPost = Post.findById(5L);``
#### Find all
``List<Post> posts = Post.findAll();``
这是获取所有posts对象最简单的方式，类似的应用还有：
``List<Post> posts = Post.all().fetch();``
下面对结果进行分页：
// 最多100条
``List<Post> posts = Post.all().fetch(100);``
或
// 50至100条
``List<Post> posts = Post.all().from(50).fetch(100);``

#### 使用简单查询进行查找
以下方式允许你创建一些非常有用的查询，但仅限于简单查询：

```angularjs
Post.find("byTitle", "My first post").fetch();
Post.find("byTitleLike", "%hello%").fetch();
Post.find("byAuthorIsNull").fetch();
Post.find("byTitleLikeAndAuthor", "%hello%", connectedUser).fetch();
```
简单查询遵循以下语法[属性][比较]And?，比较可取以下值：
•	LessThan –小于给定值 
•	LessThanEquals – 小于等于给定值
•	GreaterThan – 大于给定值
•	GreaterThanEquals – 大于等于给定值
•	Like –等价于SQL的like表达式，但属性要为小写。
•	Ilike – 和Like相似，大写不敏感，也就是说参数要转换成小写。
•	Elike -等价于SQL的like表达式，不进行转换。
•	NotEqual – 不等于 
•	Between – 两个值之间（必须带2个参数）
•	IsNotNull – 非空值（不需要任何参数）
•	IsNull – 空值（不需要任何参数）
#### 使用JPQL 查询进行查找
如：

```angularjs
Post.find(
    "select p from Post p, Comment c " +
    "where c.post = p and c.subject like ?", "%hop%"
);
```
或仅查询某部分:

```angularjs
Post.find("title", "My first post").fetch();
Post.find("title like ?", "%hello%").fetch();
Post.find("author is null").fetch();
Post.find("title like ? and author is null", "%hello%").fetch();
Post.find("title like ? and author is null order by postDate", "%hello%").fetch();
```
也可仅有order by语句：
``Post.find("order by postDate desc").fetch();``
### Counting统计对象
统计对象非常容易：
``long postCount = Post.count();``
或使用查询进行统计：
``long userPostCount = Post.count("author = ?", connectedUser);``
### 用play.db.jpa.Blob存储上传文件
使用play.db.jpa.Blob类型可以存储上传的文件到文件系统里（不是数据库）。在服务器端，Play以文件方式存储上传的图片到应用程序目录下的attachments文件夹下。文件名(一个UUID是指在一台机器上生成的数字，通用唯一识别码，用来唯一标识不同的文件)和MIME类型将存储到数据库的属性中（SQL数据类型为VARCHAR）。
在play里上传、存储、下载文件非常容易。这是因为框架自动对html窗体到jpa模型进行了文件上传绑定,而且play还提供了便利的方法来操作二进制数据，就像操作普通文本一样简单。为了在模型里存储上传文件，需要增加一个play.db.jpa.Blob类型的属性

```angularjs
import play.db.jpa.Blob;
 
@Entity
public class User extends Model {
 
   public String name;
   public Blob photo;
}
```
为了上传文件，需要在视图模板里添加一个窗体，在窗体里使用文件上传组件，组件名称应为模型的Blob属性，如user.photo：
```
#{form @addUser(), enctype:'multipart/form-data'}
   <input type="file" name="user.photo">
   <input type="submit" name="submit" value="Upload">
#{/form}
```
之后，在控制器里增加一个方法用于存储上传的文件：
```
public static void addUser(User user) {
   user.save();
   index();
}
```
这些代码除了jpa实体的存储操作外，好像什么都没做，这是因为play自动对上传文件进行了处理。首先，在启动action方法之前，上传的文件已经存储到应用程序的tmp/uploads/文件夹下，接着，当实体存储完成后，上传的文件会被复制到应用程序的attachments/目录，文件的名称为UUID。最后，当action完成后，临时文件将被删除。
如果同一用户上传另外一个文件，服务器将把上传的文件当作新文件进行存储，并为新文件生成一个新的UUID文件名，也就是说之前上传的文件无效。要实现多文件上传，就必须自行去实现，比如采用异步job方式。
如果http请求没有指定文件的MIME类型，你可以使用文件名称扩展。
要想把文件存储到不同的目录，需要配置attachments.path。
要想下载存储的文件，需要给控制器的renderBinary()方法传递Blob.get()参数。
### 强制保存
Hibernate负责维护从数据库查询出来的对象缓存，这些对象将被当作持久化对象进行对待，其时限和EntityManager生命周期一样长。也就是说所有绑定了事务的对象的任何改变都会在事务提交时自动进行持久化。在标准的JPA里，更新操作属于事务范围，也就不需要强制调用任何方法来持久化值。
负面影响就是你必须手工管理所有的对象，而不是告诉EntityManager去更新对象（哪种更直观）。我们必须告诉EntityManager哪个对象不需要更新，这个操作是通过调用refresh()来实现的，本质上是回滚一个单实体。我们在提交事务之前调用refresh()方法的目的就是为了让某些对象不被更新。
下面是一个通用情况，在窗体已经提交后，对一个持久化对象进行编辑：
```
public static void save(Long id) {
    User user = User.findById(id);
    user.edit("user", params.all());
    validation.valid(user);
    if(validation.hasErrors()) {
        //这里我们必须丢弃用户的编辑
        user.refresh();
        edit(id);
    }
    show(id);
}
```
这里我们看到，许多开发者并未意识到这个问题，总是忘记在错误的情况下丢弃对象现有状态。
因此，应该知道我们在play里修改了什么？所有继承自JPASupport/JPAModel的持久化对象在没有明白调用save()方法时都不会进行存储。因此，你可以重新书写上面的代码：
```
public static void save(Long id) {
    User user = User.findById(id);
    user.edit("user", params.all());
    validation.valid(user);
    if(validation.hasErrors()) {
        edit(id);
    } else{
       user.save(); // 强制保存
       show(id);
    }
}
```
这样就更加直观。但是，如果在一个比较大的对象视图里每次都明确调用save()方法将变得乏味，这时可使用关系注释的cascade=CascadeType.ALL属性来自动调用save()方法。
### 更多公共类型generic typing问题
play.db.jpa.Model定义了许多公共方法。这些方法使用一种类型参数来指定方法的返回值类型。在使用这些方法的时候，返回值的具体类型由调用的上下文类型接口确定。
比如，findAll定义如下：
``<T> List<T> findAll();``
使用情况为：
``List<Post> posts = Post.findAll();``
在这里，java编译器使用你分配给结果方法List<Post>的类型作为T的实际类型。因此，T的结果类型为Post。
遗憾的是，如果通用方法的返回值直接作为另外一个方法调用的参数时，或用作循环时，这些方法将不能正常工作。因此，下面的代码将抛出编译错误“Type mismatch: cannot convert from element type Object to Post”:
```
for(Post p : Post.findAll()) {
    p.delete();
}
```
当然可以使用临时局部变量来解决这个问题：
```
List<Post> posts = Post.findAll(); //类型引用在这里实现！
for(Post p : posts) {
    p.delete();
}
```
请等一等，还有更好的方式，你可以使用已经实现的但不太广泛使用的java语言特性来解决该问题，这样可以使代码更短小易读：
```
for(Post p : Post.<Post>findAll()) {
    p.delete();
}
```

很重要的一点就是play不支持XA(两阶段提交)。如果你在同一请求里使用多个不同的jpa配置，play将试着提交更多的事务。如果在第一个数据库成功提交，而在第二个数据库提交失败，那么第一个数据库提交的数据将不会回滚。当在同一个请求里使用多个jpa配置时一定要牢记这一点。
## Play.libs库包
play.libs包包含了很多有用的库，以帮助实现通用的编程任务。 
大多数据库都是简单的帮助类，而且非常易懂易用： 
•	Codec:数据编码和解码工具箱
•	Crypto:密码图形工具（验证码？）
•	Expression:动态评价表达式？
•	F: java实用编程工具
•	Files:文件系统控制帮助类
•	I18N:国际化帮助类
•	IO:流控制帮助类
•	Images:图片控制工具箱
•	Mail: E-mail功能
•	MimeTypes: MIME类型交换
•	OAuth: OAuth客户端协议（安全认证）
•	OAuth2: OAuth2客户端协议（安全认证）
•	OpenID: OpenID客户端协议（安全认证）
•	Time: 时间和持续期间工具箱
•	WS: 强大的Web services客户端
•	XML: 加载XML结构
•	XPath: 用XPath解析XML
下面的内容着重介绍一些非常重要的库。
用XPath解析XML
XPath 或许是最容易解析XML文档的工具了，而且不需要使用代码生成工具。play.libs.XPath库为高效完成解析任务提供了所有需求。
XPath可以操作所有的org.w3.dom.Node类型:

```angularjs
org.w3.dom.Document xmlDoc = … // 找到 a Document somewhere
  
for(Node event: XPath.selectNodes("events//event", xmlDoc)) {
    
    String name = XPath.selectText("name", event);
    String data = XPath.selectText("@date", event);
    
    for(Node place: XPath.selectNodes("//place", event)) {
        String place = XPath.selectText("@city", place);
        …
    }
    
    …
}
```
### Web Service client
play.libs.WS提供了一个强大的http客户端，Under the hood it uses Async HTTP client. 
创建一个请求非常容易：
HttpResponse res = WS.url("http://www.google.com").get();
一旦获得HttpResponse对象后，就可以访问所有的response属性了：
int status = res.getStatus();
String type = res.getContentType();
也可获得不同类型的内容体：
```angularjs
String content = res.getString();
Document xml = res.getXml();
JsonElement json = res.getJson();
InputStream is = res.getStream();
```

也可以非阻塞方式使用async API来创建一个http请求。然后就可以得到一个Promise<HttpResponse>，一旦兑现成功，就可以和平常一样使用HttpResponse：
Promise<HttpResponse> futureResponse = WS.url(
    "http://www.google.com"
).getAsync();
Functional programming with Java功能扩展？
play.libs.F库从功能编程（functional programming）带来了许多非常有用的概念constructs。这些概念用于处理复杂的抽象环境。这些概念之前也有涉及：
•	Option<T> (T值可设置也可不用设置)
•	Either<A,B> (不是A就是B)
•	Tuple<A,B> (同是包含了A和B)
Option<T>, Some<T> and None<T>
在某些情况下，函数可能不会返回结果（比如find方法），通常做法（非常糟糕）是返回null，这样做实际上非常危险，因为函数的返回类型不清晰。Option<T>就是一个优雅的解决方案。如果函数成功执行，就返回明确的类型Some<T>（封装了真实的结果），否则返回对象None<T>（Option<T>的子类型）。示例：
/* 安全除法(绝不抛出ArithmeticException运行时错误) */

```angularjs
public Option<Double> div(double a, double b) {
    if (b == 0)
        return None();
    else
        return Some(a / b);
}
```
用法：

```angularjs
Option<Double> q = div(42, 5);
if (q.isDefined()) {
    Logger.info("q = %s", q.get()); // "q = 8.4"
}
```
这儿还有更便利的语法，这是因为Option<T>实现了Iterable<T>：

```
for (double q : div(42, 5)) {
    Logger.info("q = %s", q); // "q = 8.4"
}
```
仅在div成功的情况下，for循环才被执行一次。
Tuple<A, B>
Tuple<A, B>类包装了两种类型的对象A和B。使用_1和_2域可以分别找回A和B，如：

```
public Option<Tuple<String, String>> parseEmail(String email) {
    final Matcher matcher = Pattern.compile("(\\w+)@(\\w+)").matcher(email);
    if (matcher.matches()) {
        return Some(Tuple(matcher.group(1), matcher.group(2)));
    }
    return None();
}
```
然后：

```angularjs
for (Tuple<String, String> email : parseEmail("foo@bar.com")) {
    Logger.info("name = %s", email._1); // "name = foo"
    Logger.info("server = %s", email._2); // "server = bar.com"
}
```
T2<A, B>类是Tuple<A, B>的别名。处理三个元素时使用T3<A, B, C>类，一直可到T5<A, B, C, D, E>。
Pattern Matching模式匹配
有些时候我们需要在java里进行模式匹配。遗憾的是java没有内建的模式匹配机制，java也缺乏功能性概念，所以很难增加到库里。在这里，我们采取的方案并不算太坏。
我们的主意是使用最后一次“for loop”语法来实现基本的模式匹配任务。模式匹配必须检测对象是否匹配必须的条件，还要能提取感兴趣的值。play使用的模式匹配库位于play.libs.F：
示例，假设已经有一个对象类型的引用，现在想检测这个对象是否是String类型，并且是以‘command:’字符串开始的。
标准方式为：

```
Object o = anything();
 
if(o instanceof String && ((String)o).startsWith("command:")) {
    String s = (String)o;
    System.out.println(s.toUpperCase());
}
```
使用Play模式匹配库，就可以这样写：
```
for(String s: String.and(StartsWith("command:")).match(o)) {
    System.out.println(s.toUpperCase());
}
```

只有在条件符合的情况下，for循环才会被执行一次，并且会自动提取字符串值，而不需要进行转换。这是因为每个对象都是类型安全的，并且由编译器进行检测，不需要进行转换。
Promises
Promise是play定制的“将来Future”类型。事实上一个Promise<T>类型也是一个Future<T>类型，因此，可以用作标准的Future。但它拥有一个非常有趣的属性：使用onRedeem(…)方法能够获取注册返回的能力，该方法仅在允许的值可用时才能被调用。 
Promise实例可以用在任何Future实例里（比如Jobs, WS.async，等待)。
Promises还可进行组合，比如:
```angularjs
Promise p = Promise.waitAll(p1, p2, p3)
Promise p = Promise.waitAny(p1, p2, p3)
Promise p = Promise.waitEither(p1, p2, p3)
```

### OAuth
OAuth 是一个开源协议的安全API验证， 应用地桌面和web应用程序。
这里有两种不同的定义: OAuth 1.0和OAuth 2.0。Play提供库来以消费者方式连接至可能的服务。
标准步骤为：
•	跳转用户到提供者的验证页
•	在用户授权验证结束后，将直接返回到原来的服务器
•	你的服务器将会为当前用户交换修改已经验证的信息令牌，这步操作是以服务器至服务器的方式完成的。
play会自动完成许多处理过程。
#### OAuth 1.0
OAuth 1.0功能库是通过play.libs.OAuth类提供的，这个类基于oauth-signpost。主要用于Twitter 和 Google的验证服务。
要想连接到一个服务，你需要使用下面的信息创建一个OAuth.ServiceInfo实例，以获取service provider:
•	Request token URL
•	Access token URL
•	Authorize URL
•	Consumer key
•	Consumer secret
access token可通过如下方式找到：

```angularjs
public static void authenticate() {
    // TWITTER 是OAuth.ServiceInfo对象
    // getUser() 用于返回当前用户
    if (OAuth.isVerifierResponse()) {
        // 得到verifier检验者
        // 然后使用请求tokens得到access tokens
        OAuth.Response resp = OAuth.service(TWITTER).retrieveAccessToken(
            getUser().token, getUser().secret);
        // 存储它们并返回index
        getUser().token = resp.token; getUser().secret = resp.secret;
        getUser().save()
        index();
    }
    OAuth twitt = OAuth.service(TWITTER);
    Response resp = twitt.retrieveRequestToken();
    //得到未经授权的标志tokens 
    //在继续之前先要保存
    getUser().token = resp.token; getUser().secret = resp.secret;
    getUser().save()
    // 跳转用户到验证页
    redirect(twitt.redirectUrl(resp.token));
}
```
现在可以使用token对通过分配的请求执行下面的调用：
mentions = WS.url(url).oauth(TWITTER, getUser().token, getUser().secret).get().getString();
尽管这个事例没有进行错误检测，但在生产环境，还是应该进行检测。OAuth.Response对象拥有一个error域，错误发生的时候，其中含有错误的内容。很多情况下不能给用户授权的原因是提供者已经下线或错误太多。
完整的示例见samples-and-tests/twitter-oauth。
#### OAuth 2.0
OAuth 2.0比OAuth 1.0更简单，这是因为它不需要调用signing请求。主要用于Facebook 和 37signals。
play.libs.OAuth2类提供了该支持。
为了连接到服务，你需要使用下面的信息创建一个OAuth2实例，从服务提供者获取：
•	Access token URL
•	Authorize URL
•	Client ID
•	Secret

```angularjs
public static void auth() {
    // FACEBOOK 是一个OAuth2对象
    if (OAuth2.isCodeResponse()) {
        // authUrl必须和retrieveVerificationCode调用一致
        OAuth2.Response response = FACEBOOK.retrieveAccessToken(authUrl);
        //如果有错误发生则为null
        String accessToken = response.accessToken;
        //调用成功则为null
        OAuth2.Error = response.error;
        //存储accessToken，在请求服务时要用到
        index();
    }
    // authUrl是一个包含了服务绝对URL的字符串 
    // 应该跳转回来
    // 下面将触发一个跳转
    FACEBOOK.requestVerificationCode(authUrl);
}
```
一旦获取当前用户的access token，就可以用它来查询服务：

```angularjs
WS.url(
    "https://graph.facebook.com/me?access_token=%s", access_token
).get().getJson();
```
完整示例见samples-and-tests/facebook-oauth2。
### OpenID
OpenID 是一个开源的分散式身份认证系统。在你的系统里不需要保存特定用户的信息就可以很容易接受新的用户。只需通过它们的OpenID跟踪验证用户即可。
本示例提供一个轻量级的演示，用于演示如果使用OpenID验证用户：
•	对每个请求，检测用户是否已经连接
•	如果没有，就显示用户可以提交OpenID的页面
•	跳转用户到OpenID提供者
•	当用户回来的时候，获取验证的OpenID并存储到HTTP session里
play.libs.OpenID类提供了OpenID功能：
```
@Before(unless={"login", "authenticate"})
static void checkAuthenticated() {
    if(!session.contains("user")) {
        login();
    }
}
 
public static void index() {
    render("Hello %s!", session.get("user"));
}
     
public static void login() {
    render();
}
    
public static void authenticate(String user) {
    if(OpenID.isAuthenticationResponse()) {
        UserInfo verifiedUser = OpenID.getVerifiedID();
        if(verifiedUser == null) {
            flash.error("Oops. Authentication has failed");
            login();
        } 
        session.put("user", verifiedUser.id);
        index();
    } else {
        if(!OpenID.id(user).verify()) { // will redirect the user
            flash.error("Cannot verify your OpenID");
            login();
        } 
    }
}
```
login.html模板代码为：
```
#{if flash.error}
<h1>${flash.error}</h1>
#{/if}
 
<form action="@{Application.authenticate()}" method="POST">
    <label for="user">What’s your OpenID?</label>
    <input type="text" name="user" id="user" />
    <input type="submit" value="login…" />
</form>
</code>
```
路由定义为：
```
GET   /                     Application.index
GET   /login                Application.login
*     /authenticate         Application.authenticate
```

## 异步Jobs
因为play是一个web应用程序，因此许多应用程序逻辑都是由控制器返回给http请求的。
但有些时候，我们需要在http请求外执行一些应用逻辑。比如非常有用的初始化任务，维护任务或运行不能被http请求池中断的长时运行的任务等等。
Jobs可以被框架全面进行管理。意思是play负责管理所有的数据库连接原料stuff，JPA实体管理器负责管理数据同步和事务管理。要想创建一个job，只需要继承play.jobs.Job即可。

```angularjs
package jobs;
 
import play.jobs.*;
 
public class MyJob extends Job {
    
    public void doJob() {
        //在这儿执行某些逻辑
    }
    
}
```
有些时候需要任务返回结果，这时就需要重载doJobWithResult()方法。

```angularjs
package jobs;
 
import play.jobs.*;
  
public class MyJob extends Job<String> {
    
    public String doJobWithResult() {
        //在这儿执行某些逻辑
        return result;
    }
    
}
```
本示例仅使用了String作为返回类型，当然可以返回任何对象类型。
引导程序任务Bootstrap jobs
引导程序任务会在play应用启动时执行。要想实现该任务，只需要在你的任务上添加@OnApplicationStart注释：

```angularjs
import play.jobs.*;
 
@OnApplicationStart
public class Bootstrap extends Job {
    
    public void doJob() {
        if(Page.count() == 0) {
            new Page("root").save();
            Logger.info("A root page has been created.");
        }
    }
    
}
```
注意：在这里不需要返回结果，即使这样做了，结果也会丢失。
默认情况下，所有标识为@OnApplicationStart的任务都将以队列方式执行。当所有的job执行结束后，应用程序才正式启动并开始处理请求。
如果你打算让你的任务在应用程序启动时执行，但你又想立即管理进行请求处理，那么可以使用@OnApplicationStart(async=true)注释。然后，你的job将在后台启动。
警告！

当运行于DEV模式时，应用程序将在第一个请求到达时才启动。此外，在DEV模式时，在需要的时候，应用程序会自动重启。
当运行于PROD模式时，应用程序将和服务器一起同步启动。
预定义任务Scheduled jobs
预定义任务由框架周期性执行。你可以使用@Every注释要求play在一个特定的周期内运行job。

```
import play.jobs.*;
 
@Every("1h")
public class Bootstrap extends Job {
    
    public void doJob() {
        List<User> newUsers = User.find("newAccount = true").fetch();
        for(User user : newUsers) {
            Notifier.sayWelcome(user);
        }
    }
    
}
```
如果@Every注释还不足以满足需要，你可使用带有CRON表达式的@On注释来运行你的job。

```
import play.jobs.*;
 
/** Fire at 12pm (noon) every day **/ 
@On("0 0 12 * * ?")
public class Bootstrap extends Job {
    
    public void doJob() {
        Logger.info("Maintenance job ...");
        ...
    }
    
}
```
小建议

我们是使用Quartz library来解析CRON表达式的。
你不能返回结果，即使这样做了，结果也会被丢弃。
触发任务job
调用Job实例的now()方法可以在任何时候触发job来执行一段特定的任务。这个时候，job将以非阻塞方式立即执行。 
```angularjs
public static void encodeVideo(Long videoId) {
    new VideoEncoder(videoId).now();
    renderText("Encoding started");
}
```
调用job的now()方法以返回一个Promise值。
停止应用程序 
使用@OnApplicationStop注释可以在应用程序关闭时执行某些操作。
```angularjs
import play.jobs.*;
 
@OnApplicationStop
public class Bootstrap extends Job {
 
    public void doJob() {
        Fixture.deleteAll();
    }
}
```
## 使用cache
为了创建高效的系统，有里会需要缓存数据。play有一个cache库，在分布式环境中使用Memcached。
如果没有配置Memcached，play将使用标准的缓存来存储数据到JVM heap堆中。在JVM应用程序里缓存数据打破了play创造的“什么都不共享”的原则：你不能在多个服务器上运行同一应用程序，否则不能保证应用行为的一致性。每个应用实例将拥有不同的数据备份。
清晰理解缓存约定非常重要：当把数据放入缓存时，就不能保证数据永久存在。事实上不能这样做，缓存非常快，只在内存里存在（并没有进行持久化）。 
因此使用缓存最好的用途就是数据不需要进行修改的情况
```
public static void allProducts() {
    List<Product> products = Cache.get("products", List.class);
    if(products == null) {
        products = Product.findAll();
        Cache.set("products", products, "30mn");
    }
    render(products);
}
```
The cache API
缓存API由play.cache.Cache类提供，这个类包含了许多用于从缓存设置、替换、获取数据的方法。参考Memcached文档以了解每个方法的用法。
示例：

```angularjs
public static void showProduct(String id) {
    Product product = Cache.get("product_" + id, Product.class);
    if(product == null) {
        product = Product.findById(id);
        Cache.set("product_" + id, product, "30mn");
    }
    render(product);
}
 
public static void addProduct(String name, int price) {
    Product product = new Product(name, price);
    product.save();
    showProduct(product.id);
}
 
public static void editProduct(String id, String name, int price) {
    Product product = Product.findById(id);
    product.name = name;
    product.price = price;
    Cache.set("product_" + id, product, "30mn");
    showProduct(id);
}
 
public static void deleteProduct(String id) {
    Product product = Product.findById(id);
    product.delete();
    Cache.delete("product_" + id);
    allProducts();
}
```
有一些方法是以safe前缀开头的方法，比如safeDelete, safeSet。而标准方法是非阻塞式的，比如：
``Cache.delete("product_" + id);``
delete方法将立即返回，不会一直等到缓存对象是否真的删除。因此，如果发生错误时，比如IO错误，那么要删除的对象仍旧存在。
在继续之前如果需要确定是否真的把对象删除了，就可以使用safeDelete方法：
``Cache.safeDelete("product_" + id);``
这个方法是阻塞式的，并且会返回一个boolean值来确定是否真的把对象删除了。因此，从缓存中删除对象的完整模式应该是这样的：
```angularjs
if(!Cache.safeDelete("product_" + id)) {
    throw new Exception("Oops, the product has not been removed from the cache");
}
...
```
注意：这些方法会导致调用中断，安全方法会慢慢的顺着执行下去,一般情况下，只要确实需要的时候才使用这些方法。
同时要注意，当expiration == "0s" (0秒)时， 真正的中止时间可能与缓存执行的时间不同。
不要把Session当成缓存!
如果使用框架带来的内存式的session来作缓存， 你就会发现play只允许很小的字符串数据可以存入HTTP Session，这里不应该是缓存应用程序数据的地方！ 
如果你已经习惯了这样做：
```angularjs
httpServletRequest.getSession().put("userProducts", products);
...
// 之后进行请求
products = (List<Product>)httpServletRequest.getSession().get("userProducts");
```

在Play里可以用其他方式实现相同效果：
```angularjs
Cache.set(session.getId(), products);
...
//接下来的请求为：
List<Product> products = Cache.get(session.getId(), List.class)
```

在这里，我们使用唯一的UUID来为每个用户在缓存里保存唯一信息。请记住，这和session对象不同，缓存并不绑定任何特定的用户！
配置mcached
如果需要允许真正的Memcached实现，就需在 memcached configuration 定义守护地址 memcached.host configuration。

## 安全指南
play框架的安全设计只是存在于脑海中的一个概念——这就不可能阻止开发者在设计上出漏洞。本指南描述了在Web应用中常见的安全问题，并指导如何在play应用开发中去避免。
Sessions
一般情况下，你需要保存用户登录信息。如果不使用session，用户就需要在每次请求时传递证书。
这就是session要做的事：一系列cookies存储在用户的浏览器里，以用于标识不同的站点，并提供其他数据层之外的信息，比如语言。
守住你的安全…安全
session是一个key/values哈希表，有签名但没有加密。也就是说主要你的secret是安全的，那么第三方就不可能伪造session。
而secret存储在conf/application.conf里。保持这个文件的私有化非常重要：不要把它提交给公共仓库，为防止在安装某些人写的应用程序时对secret key进行修改，你可以运行命令play secret进行保护。
不要存储关键性的数据
然后，既然session没有加密，那么就不应该在session里存储关键性安全数据，通过本地网络连接或wifi连接进行嗅探，它将被看成是用户的cookie。
session被存储在cookie里, 而cookies被限制为4 KB大小。而且只能存储String。
跨站点脚本攻击
在web应用程序中，Cross-site scripting跨站点脚本是最常见的弱点。它包含了利用应用程序提供的窗体恶意注入到web页面的脚本代码。
假定这里有一个博客程序，任何人都可以发表评论，如果评论内容里包含了攻击脚本，那么你将打开你的站点进行攻击，可能步骤为：
•	为访问者弹出一个窗体
•	跳转访问者到被攻击者控制的站点
•	窃取当前用户的可见信息，并发回攻击者的站点
因此为防止类似攻击，进行保护非常重要。
play的模板引擎会自动转义字符串。如果需要在模板里插入未转义的HTML代码，那就需要使用java字符串扩展的 raw() 方法。但如果这个字符串是用户输入的，那么你就需要首先确定它是否是无害的。
在对用户输入进行sanitizing消毒的时候，只允许白名单（只允许列表中的安全标签通过）通过，黑名单 (禁止一些不安全的标签列表)则禁止。
详见cross-site scripting。
SQL注入
SQL注入所谓SQL注入，就是通过把SQL命令插入到Web表单递交或输入域名或页面请求的查询字符串，最终达到欺骗服务器执行恶意的SQL命令，比如先前的很多影视网站泄露VIP会员密码大多就是通过WEB表单递交查询字符暴出的，这类表单特别容易受到SQL注入式攻击。这个漏洞可以摧毁数据，或访问不应该让当前用户看到的数据。

当使用高级的“find”方法时，就应该小心sql注入。当手工构建自己的查询时，尽量不要用+来作连接符，而是用?占位符。
比如:
``createQuery("SELECT * from Stuff WHERE type= ?1").setParameter(1, theType);``
下面这个就不好了:
``createQuery("SELECT * from Stuff WHERE type=" + theType;``
跨站点请求伪造
跨站点请求伪造CSRF攻击在web应用程序里非常危险：
这个攻击方法通过在用户信任的web应用程序的页面里加入恶意代码或链接进行攻击。如果web应用程序的session没有设置超时，那么攻击者就可以执行未经验证的命令。
为预防这类攻击，首先就是要正确全用GET和POST方法。意思是仅允许POST方法用于修改应用程序的状态。
对POST请求来说，只有真实的token才会触发动作。Play现在内建了一个帮助类用于处理这样的问题：
•	checkAuthenticity() 检查真实性方法在控制器里可直接使用，用于检查请求参数里的token的真实有效，如果存在问题，就发送一个禁止response的命令。
•	session.getAuthenticityToken()方法用于为当前session生成一个真实可信的token
•	#{authenticityToken /}用于创建一个隐藏的输入域，可用于任何窗体 
示例：
```angularjs
public static destroyMyAccount() {
    checkAuthenticity();
    …
}
```
上面的方法仅当窗体包含了真实有效的token时，才会被调用:
```
<form method="post" action="/account/destroy">
    #{authenticityToken /}
    <input type="submit" value="destroy my account">
</form>
```
对POST请求来说，Play提供form标签会自动生成一个有效的token:
```
#{form @destroyMyAccount()}
    <input type="submit" value="destroy my account">
#{/form}
```
如果你想保护所有控制器的action动作，你也可以使用checkAuthenticity()方法作为before filter进行听说。
更多跨站点请求伪造见：More on cross-site request forgery。
管理数据库变化Evolution
当使用关系数据库时，你需要去跟踪和安排数据库schema（结构）变化，特别是有多个存储位置的情况下，你就需要更多的经验来跟踪数据的schema变化： 
•	当处理团队合作进行开发时，每个人都需要知道数据库结构的变化
•	当部署到生产服务器上时，就需要一个稳健的方式去更新数据库结构 
•	如果在多台数据库服务器上工作时，就需要保持所有数据库结构同步
如果在JPA下工作，Hibernate会自动为你处理好这些数据库变化。如果你不打算使用JPA或打算手工对数据库结构进行更好的调整，那么Evolutions将非常有用。
## Evolutions脚本
Play使用evolutions 脚本来跟踪你的数据库变化。这些脚本采用的是原始的sql语句来书写的，应该位于应用程序的db/evolutions目录。
第一个脚本名叫1.sql,第二为2.sql,以此类推…
每个脚本包含了两部分：
•	Ups 部分用于描述必要的转换 
•	Downs 部分用于描述如何恢复他们
比如，查看第一个evolution脚本，这个脚本用于引导一个基本的应用：

```angularjs
# Users schema
 
# --- !Ups
 
CREATE TABLE User (
    id bigint(20) NOT NULL AUTO_INCREMENT,
    email varchar(255) NOT NULL,
    password varchar(255) NOT NULL,
    fullname varchar(255) NOT NULL,
    isAdmin boolean NOT NULL,
    PRIMARY KEY (id)
);
 
# --- !Downs
 
DROP TABLE User; 
```
正如你看到的一样，必须在sql脚本里使用注释来界定Ups和Downs 节。
如果在applictaion.conf里配置了数据库，那么Evolutions将被自动激活，而且evolution scripts将被显示出来。通过设置evolutions.enabled 为false可以禁此显示脚本。比如，当测试他们自己的数据库里，你可以为测试环境设置为禁用模式。
当evolutions 被激活后， 在DEV模式下，Play将为每个请求检查数据库结构状态，或在PROD模式下启动应用程序时进行数据库结构状态检查。在DEV模式下，如果数据库结构不是最新的，一个错误页面会显示出来，它会建议你运行合适的sql脚本同步你的数据结构。

如果你同意推荐的SQL脚本，你可以点击‘Apply evolutions’按钮执行该建议脚本。
如果使用的是内存数据库(db=mem),并且数据库是空的情况下，Play会自动运行所有的evolutions脚本。
同步同时发生的改变
现在让我们假定现在在同一项目中有两个开发者，A开发者因工作需要必须创建一个新的数据库表，因此他将2.sql evolution 脚本:
```angularjs
# Add Post
 
# --- !Ups
CREATE TABLE Post (
    id bigint(20) NOT NULL AUTO_INCREMENT,
    title varchar(255) NOT NULL,
    content text NOT NULL,
    postedAt date NOT NULL,
    author_id bigint(20) NOT NULL,
    FOREIGN KEY (author_id) REFERENCES User(id),
    PRIMARY KEY (id)
);
 
# --- !Downs
DROP TABLE Post;
Play将应用这个evolution脚本到A开发者的数据库。
另外一方面，B开发者因工作需要，必须删除User表。因此他也将创建2.sql evolution脚本：
# Update User
 
# --- !Ups
ALTER TABLE User ADD age INT;
 
# --- !Downs
ALTER TABLE User DROP age;
```

B开发者结束开发工作后进行了提交（称为Git)。现在，A开发者在继续开发前必须合并他的同事的工作，因此他运行git pull，但合并操作产生了一个冲突，如下：
```angularjs
Auto-merging db/evolutions/2.sql
CONFLICT (add/add): Merge conflict in db/evolutions/2.sql
Automatic merge failed; fix conflicts and then commit the result.
```

每个开发者都创建了一个2.sql evolution脚本。因此，A开发者需要合并这个文件：
```angularjs
<<<<<<< HEAD
# Add Post
 
# --- !Ups
CREATE TABLE Post (
    id bigint(20) NOT NULL AUTO_INCREMENT,
    title varchar(255) NOT NULL,
    content text NOT NULL,
    postedAt date NOT NULL,
    author_id bigint(20) NOT NULL,
    FOREIGN KEY (author_id) REFERENCES User(id),
    PRIMARY KEY (id)
);
 
# --- !Downs
DROP TABLE Post;
=======
# Update User
 
# --- !Ups
ALTER TABLE User ADD age INT;
 
# --- !Downs
ALTER TABLE User DROP age;
>>>>>>> devB
这个合并操作其实很容易做:
# Add Post and update User
 
# --- !Ups
ALTER TABLE User ADD age INT;
 
CREATE TABLE Post (
    id bigint(20) NOT NULL AUTO_INCREMENT,
    title varchar(255) NOT NULL,
    content text NOT NULL,
    postedAt date NOT NULL,
    author_id bigint(20) NOT NULL,
    FOREIGN KEY (author_id) REFERENCES User(id),
    PRIMARY KEY (id)
);
 
# --- !Downs
ALTER TABLE User DROP age;
 
DROP TABLE Post;
```

这个evolution脚本显示为新修订revision 2 的数据库，这个版本不同于A开发者之前已经应用的修订2版本。 
因此Play会察觉到这个情况，并要求A开发者通过首先恢复已经应用的旧的修订2版本来同步他的数据库，并应用新的修订2版本脚本：

数据不一致状态
某些时候可能会在evolution脚本里犯错，那么这些脚本就会失效。在这种情况下，play将标记数据库结构为数据不一致状态，同时要求你在继续工作前手工解决这个问题。
比如，Evolution脚本的 Ups 存在一个错误：
```angularjs
# Add another column to User
  
# --- !Ups
ALTER TABLE Userxxx ADD company varchar(255);
 
# --- !Downs
ALTER TABLE User DROP company;
```
因此，试着应用这个evolution将导致失败，play将把数据库结构标记为inconsistent:

现在要继续工作前，你必须解决这个不一致的问题，因此你就运行了fixed SQL 命令:
``ALTER TABLE User ADD company varchar(255);``
… 之后，通过单击按钮，手工解决了这个标记的问题。
但是由于你的evolution脚本存在错误，你或许希望修复这个错误。因此你修改了3.sql脚本：
```
# Add another column to User
  
# --- !Ups
ALTER TABLE User ADD company varchar(255);
 
# --- !Downs
ALTER TABLE User DROP company;
```
Play检测到这个新的evolution，然后替换了之前的3版， 之后将运行下面的脚本：

现在所有的问题都已处理好，你又可以继续工作了。
在开发模式里，处理这样的问题非常简单，可以直接丢弃现在的开发数据库，然后再次重头申请所有的evolutions脚本即可。
Evolutions 命令
在DEV模式里，evolutions是交互式执行的。然而在PROD模式里，在运行应用程序前，你就必须使用evolutions命令来修订你的数据库结构。
在生产模式下如果你试着运行一个数据库不是最新版的应用程序时，应用程序将不能启动。
```angularjs
~        _            _ 
~  _ __ | | __ _ _  _| |
~ | '_ \| |/ _' | || |_|
~ |  __/|_|\____|\__ (_)
~ |_|            |__/   
~
~ play! master-localbuild, http://www.playframework.org
~ framework ID is prod
~
~ Ctrl+C to stop
~ 
13:33:22 INFO  ~ Starting ~/test
13:33:22 INFO  ~ Precompiling ...
13:33:24 INFO  ~ Connected to jdbc:mysql://localhost
13:33:24 WARN  ~ 
13:33:24 WARN  ~ Your database is not up to date.
13:33:24 WARN  ~ Use `play evolutions` command to manage database evolutions.
13:33:24 ERROR ~ 
 
@662c6n234
Can't start in PROD mode with errors
 
Your database needs evolution!
An SQL script will be run on your database.
 
play.db.Evolutions$InvalidDatabaseRevision
	at play.db.Evolutions.checkEvolutionsState(Evolutions.java:323)
	at play.db.Evolutions.onApplicationStart(Evolutions.java:197)
	at play.Play.start(Play.java:452)
	at play.Play.init(Play.java:298)
	at play.server.Server.main(Server.java:141)
Exception in thread "main" play.db.Evolutions$InvalidDatabaseRevision
	at play.db.Evolutions.checkEvolutionsState(Evolutions.java:323)
	at play.db.Evolutions.onApplicationStart(Evolutions.java:197)
	at play.Play.start(Play.java:452)
	at play.Play.init(Play.java:298)
	at play.server.Server.main(Server.java:141)
```

错误消息要求你运行play evolutions命令：
```angularjs
$ play evolutions
~        _            _ 
~  _ __ | | __ _ _  _| |
~ | '_ \| |/ _' | || |_|
~ |  __/|_|\____|\__ (_)
~ |_|            |__/   
~
~ play! master-localbuild, http://www.playframework.org
~ framework ID is gbo
~
~ Connected to jdbc:mysql://localhost
~ Application revision is 3 [15ed3f5] and Database revision is 0 [da39a3e]
~
~ Your database needs evolutions!
 
# ----------------------------------------------------------------------------
 
# --- Rev:1,Ups - 6b21167
 
CREATE TABLE User (
    id bigint(20) NOT NULL AUTO_INCREMENT,
    email varchar(255) NOT NULL,
    password varchar(255) NOT NULL,
    fullname varchar(255) NOT NULL,
    isAdmin boolean NOT NULL,
    PRIMARY KEY (id)
);
 
# --- Rev:2,Ups - 9cf7e12
  
ALTER TABLE User ADD age INT;
CREATE TABLE Post (
    id bigint(20) NOT NULL AUTO_INCREMENT,
    title varchar(255) NOT NULL,
    content text NOT NULL,
    postedAt date NOT NULL,
    author_id bigint(20) NOT NULL,
    FOREIGN KEY (author_id) REFERENCES User(id),
    PRIMARY KEY (id)
);
 
# --- Rev:3,Ups - 15ed3f5
 
ALTER TABLE User ADD company varchar(255);
 
# ----------------------------------------------------------------------------
 
~ Run `play evolutions:apply` to automatically apply this script to the db
~ or apply it yourself and mark it done using `play evolutions:markApplied`
~
```

如果你打算让Play自动为你运行evolution，那么要使用如下命令：
``$ play evolutions:apply``
如果你喜欢在你的生产数据库上手工运行脚本，那么你需要告诉play你的数据库是最新的：
``$ play evolutions:markApplied``
如果在自动运行evolution脚本时存在错误，在DEV模式下，可以手工解决他们，之后标记数据库结构为已修正状态：
``$ play evolutions:resolve``

