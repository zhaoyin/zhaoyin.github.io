---
title: Scrapy之新手上路
date: 2017-05-28 22:38:56
reward: true
categories:
    - Spider
tags:
    - Scrapy
    - Spider
    - python
---

## 安装Scrapy

我们使用crawler在github上搜索 most stars我们会看到Scrapy这个热门的开源项目

![img](http://oqcey66z7.bkt.clouddn.com/public/images/crawler-most-stars.png)

Scrapy，Python开发的一个快速,高层次的屏幕抓取和web抓取框架，用于抓取web站点并从页面中提取结构化的数据。Scrapy用途广泛，可以用于数据挖掘、监测和自动化测试。

Scrapy吸引人的地方在于它是一个框架，任何人都可以根据需求方便的修改。它也提供了多种类型爬虫的基类，如BaseSpider、sitemap爬虫等，最新版本又提供了web2.0爬虫的支持。

是不是迫不及待想体验一下强大的Scrapy呢？几个简单的步骤我们就可以开始用了

这些基础组件的安装，网络上都有很详细的安装过程，这里只是简单介绍，且针对macOs（想详细了解／其他系统？[scrapy-install]https://docs.scrapy.org/en/latest/intro/install.html）。

<!--more-->

* 安装python

    执行``python -V``看看是否安装了2.7或3.3的python。

    如果没有安装``brew install python``或者要升级python
    ```
    brew update; brew upgrade python
    ```
    不知道brew？难道你还没有用macOS的强大软件包管理器？赶紧来一套吧[Homebrew介绍](https://brew.sh/index_zh-cn.html)

* 使用pip安装Scrapy

    执行``pip --version``来确认你安装来pip
    没有安装？从 https://pip.pypa.io/en/latest/installing.html 安装 pip
    pip升级？``pip install --upgrade pip``
    
    好了，来安装Scrapy吧
    ```
    pip install Scrapy
    ```
    ![img](http://oqcey66z7.bkt.clouddn.com/public/images/success-install-scrapy.png)
    上面就说明安装成功了

## 创建一个爬虫项目
    
通过scrapy --help我们可以看到scrapy的基本命令
    
![img](http://oqcey66z7.bkt.clouddn.com/public/images/scrapy-help.png)

```
scrapy startproject project名称
```
创建一个项目可以看到它的目录结构

![img](http://oqcey66z7.bkt.clouddn.com/public/images/directory-struct.png)

* scrapy.cfg: 配置文件
* tutorial/: 该项目的python模块.
* tutorial/items.py: 项目中的item文件.
* tutorial/pipelines.py: 项目中的pipelines文件.
* tutorial/settings.py: 项目的设置文件.
* tutorial/spiders/: 放置spider代码的目录.

## 创建Spider

在tutorial/spiders中创建一个cnblogs_spider.py如下：
```
# encoding=utf8
import scrapy
import json


class CnblogsSpider(scrapy.Spider):
    # spider的唯一标示，在project中要唯一,spider名称
    name = "cnblogs"

    start_urls = [
        'https://news.cnblogs.com/n/page/1/',
        # 'https://news.cnblogs.com/n/page/2/',
        # 'https://news.cnblogs.com/n/page/3/'
    ]

    # def start_requests(self):
    #     urls = [
    #         'https://news.cnblogs.com/n/page/1/',
    #         'https://news.cnblogs.com/n/page/2/',
    #         'https://news.cnblogs.com/n/page/3/'
    #     ]
    #     for url in urls:
    #         yield scrapy.Request(url=url, callback=self.parse)

    def parse(self, response):
        # page = response.url.split('/')[-2]
        # filename = 'cnblogs-%s.json' % page
        # with open(filename, 'wb') as f:
        #     data = []
        #     for new in response.css('div#news_list div.content'):
        #         new_content = {
        #             'title': ''.join(new.css('h2.news_entry a::text').extract()),
        #             'summary': ''.join(new.css('div.entry_summary::text').extract()[1].lstrip().rstrip()),
        #             'author': ''.join(new.css('div.entry_footer a::text').extract()[0].strip()),
        #             'url': 'https://news.cnblogs.com'+new.css('h2.news_entry a::attr(href)').extract_first()
        #         }
        #         data.append(new_content)
        #
        #     f.write(unicode.encode(json.dumps(data, ensure_ascii=False, sort_keys=True, indent=4)+'\r\n', 'utf-8'))
        # self.log('save file %s' % filename)
        # f.close()
        for new in response.css('div#news_list div.content'):
            yield {
                'title': ''.join(new.css('h2.news_entry a::text').extract()),
                'summary': ''.join(new.css('div.entry_summary::text').extract()[1].lstrip().rstrip()),
                'author': ''.join(new.css('div.entry_footer a::text').extract()[0].strip()),
                'url': 'https://news.cnblogs.com'+new.css('h2.news_entry a::attr(href)').extract_first()
            }

```

## 运行Spider

完成了一个简单的spider，如何运行它来输出我们需要的结果呢？
在项目的根目录中执行如下的命令：

```
scrapy crawl spider名称 -o spider.json
```

例如``scrapy crawl cnblogs``其中cnblogs即为定义的spider的name


最终输出一个完整的json数据
![img](http://oqcey66z7.bkt.clouddn.com/public/images/scrapy-spider-export-json.png)
```
[
{"url": "https://news.cnblogs.com/n/570434/", "title": "传软银欲成印度打车应用Ola控股股东", "author": "itwriter", "summary": "腾讯科技讯，据外电报道，软银目前正在巩固所有的印度投资。有消息称，继操刀推动其投资的印度第三大电商 Snapdeal 与该国第一大电商 Flipkart 进行合并之后，软银当前又计划通过交易买下该国乘车分享应用 Ola 大股东老虎环球基金（Tiger Global）所持的股份，欲成为 Ola..."},
{"url": "https://news.cnblogs.com/n/570431/", "title": "黄金不仅可以做首饰 还能变成抗击癌症的“子弹”", "author": "itwriter", "summary": "说到黄金，大家可能会第一时间想到那些昂贵的黄金饰品，事实上黄金因其性质稳定，也多被用于制作一些医疗器具，比如心血管支架、假牙等等，那么黄金在医疗领域的应用又是否能更进一步呢，答案当然是肯定的，最近就有科学家发现黄金可以用来更有效地对抗癌症。通常来说，治疗癌症多为切除肿瘤之后进行放疗或..."},
{"url": "https://news.cnblogs.com/n/570430/", "title": "联通与腾讯阿里小米合作的流量卡如雨后春笋，然而有用吗？", "author": "itwriter", "summary": "文 / 宁宇，作者微信公众号：尚儒客栈（CMCC-ningyu）这段时间，中国联通的各种定制卡如雨后春笋般呈现在各个 APP 里。在我手机里看到的营销弹窗，包括与腾讯合作的大王卡、小王卡；与阿里巴巴合作的钉钉卡、蚂蚁宝卡；与百度合作的神卡（分大神卡、小神卡、女神卡..."},
{"url": "https://news.cnblogs.com/n/570429/", "title": "美国正式对尼康展开专利侵权调查：日本巨头面临禁售", "author": "itwriter", "summary": "今年是日本相机企业尼康诞生的第 100 周年，但 100 岁的尼康也如其年龄一般“夕阳西下”，不仅 2016 年业绩出现大幅跳水，还面临被美国禁售的危险。据路透社报道，由于蔡司公司和 ASML 公司同样对尼康启动了法律程序，美国国际贸易委员会目前已经正式受理并..."},
{"url": "https://news.cnblogs.com/n/570428/", "title": "高德诉滴滴不正当竞争：8起案件索赔7500万元", "author": "itwriter", "summary": "北京晨报讯（记者|颜斐）因认为北京滴滴无限科技发展有限公司、北京小桔科技有限公司虚假宣传，并伙同中智项目外包服务有限公司及公司原高级经理胡先生，拉拢公司掌握核心商业秘密的 6 名员工为滴滴公司、小桔公司提供服务，侵犯商业秘密，构成不正当竞争，高德软件有限公司、高德信息技术有限公司提起 8 起..."},
{"url": "https://news.cnblogs.com/n/570427/", "title": "从网易严选毛巾事件，看互联网撕逼的12个暗黑法则", "author": "itwriter", "summary": "一、撕逼是未来常态“丁磊，能给创业者一条活路吗？”“我有一个创业者的故事，你想听吗？”“你说我是说谎者，我只说些事实。”“来看看，撕逼的套路与逻辑！”“..."},
{"url": "https://news.cnblogs.com/n/570426/", "title": "马云李彦宏数博会上\"隔空对战\" 马化腾来“劝架”了", "author": "itwriter", "summary": "近日举行的贵阳数博会，BAT 三家第一次在同一届数博会到齐。昨日，马云和李彦宏隔空对战更是成为大会看点，究其根源是对“人工智能”的看法不同，一个谈了“人工智能”，另一个谈的是“机器智能”。今天马化腾在闭幕..."},
{"url": "https://news.cnblogs.com/n/570425/", "title": "小米转型里程碑！小米之家突破100家：端午一天开四家", "author": "itwriter", "summary": "曾经的“互联网手机之王”小米越来越重视线下市场，小米之家在全国遍地开花，今天端午佳节之时终于突破了 100 家，而目标是未来三年开到 1000 家。5 月 27 日，小米一口气开张了四家小米之家，分别是郑州大商新玛特国贸店(郑州的第三家)、广州西城都荟店、佛山顺德..."},
{"url": "https://news.cnblogs.com/n/570424/", "title": "看到AlphaGo难免想起“深蓝”？可IBM当年前赢得并不光彩", "author": "itwriter", "summary": "在关注“柯洁对战 AlphaGo”时，很多人或许都会想到 20 年前的“卡斯帕罗夫对战深蓝”，当时的那场世纪之战似乎比现在更加轰动，外媒撰文称，实际上深蓝之所以能够战胜卡斯帕罗夫，并非全凭技术，而是掺入了一些狡诈的伎俩。以下为 AI 世..."},
{"url": "https://news.cnblogs.com/n/570423/", "title": "知道苹果有多值钱吗？市值超瑞士、荷兰等国GDP", "author": "itwriter", "summary": "投资银行美银/美林日前发布一份名为《占领硅谷》的报告。在该报告中，美银美林指出苹果和谷歌母公司 Alphabet 的市值，已超出除洛杉矶和纽约之外的所有美国城市的国内生产总值（GDP），且苹果与洛杉矶的差距已不足4%。虽然这些数据并不意味着苹果和 Alphabet 如今就要比绝大多数..."},
{"url": "https://news.cnblogs.com/n/570422/", "title": "万人围观！雷军回老家过端午：亲登龙舟擂鼓", "author": "itwriter", "summary": "端午假期第一天，想必不少朋友已经回家或者在回家、游玩的路途中。昨天下午，小米董事长雷军也分享了动态，原来，他来到湖北仙桃老家，在这里庆祝传统端午佳节。雷军说，仙桃的风俗是赛龙舟、吃粽子，他此次也登船，泛舟莲花池，轻敲龙首鼓。按照仙桃小米之家的说法，雷军到访的是仙桃..."},
{"url": "https://news.cnblogs.com/n/570421/", "title": "运动App掌门人：我们不需要流量，只想做体育的服务行业", "author": "itwriter", "summary": "运动 APP 的社交功能，使得用户可以分享运动排名，结识跑友，加入圈子。当下，跑者对于跑步类 APP 的依赖不容小觑。回顾历程，2012 年国内出现了首款运动 APP，随后运动软件行业在 2014 年经历了资本热潮，又在 2016 年度过了资本寒冬。但是市场就摆在那里，201..."},
{"url": "https://news.cnblogs.com/n/570420/", "title": "十年版iPhone X最新爆料：会二选一", "author": "itwriter", "summary": "今年秋季，苹果将推出一款十年版手机（有媒体将其称之为 iPhone X 或是 iPhone 8），纪念第一部 iPhone 推出十周年。这款手机相较以往的 iPhone，将有比较大的升级内容（许多升级内容早已出现在其他品牌的手机中）。十年版手机的信息处于动态更新当中，日前外媒总结披露了该手机..."},
{"url": "https://news.cnblogs.com/n/570419/", "title": "马斯克的火箭7年共发射34次，成功率94%", "author": "itwriter", "summary": "Recode 中文站 5 月 29 日报道由埃隆·马斯克（Elon Musk）统帅并得到美国国家航空航天局（NASA）支持的星际间旅行公司 SpaceX 在过去的 7 年中共发射了 34 次猎鹰 9 号火箭，绝大数获得了成功，只有两次完全失败的经历，其中一次发生在测试的..."},
{"url": "https://news.cnblogs.com/n/570417/", "title": "亚马逊在纽约开了首家实体书店：全是四星以上评级的书", "author": "itwriter", "summary": "BI 中文站 5 月 28 日报道亚马逊在美国纽约市的首家实体店周四正式开张了，这是亚马逊在美国的第七家实体店。亚马逊的这家实体店位于纽约市曼哈顿的哥伦布圆环（Columbus Circle）内。店内主要销售书籍和一些电子产品（如亚马逊智能音箱 Echo）。亚马逊实体..."},
{"url": "https://news.cnblogs.com/n/570416/", "title": "比较Google地图和苹果地图一年的变化", "author": "itwriter", "summary": "2012 年，苹果开始用自家地图应用取代 Google 地图，但苹果的早期地图因为数据存在大量错误而饱受用户批评，CEO 库克甚至为此公开道歉。五年之后，苹果地图相比 Google 地图又如何呢？Justin O'Beirne 写了一个脚本每月在两个地图上截取相同地点的图像，仔细分析..."},
{"url": "https://news.cnblogs.com/n/570415/", "title": "两周过去了，“想哭”勒索蠕虫近来可好？", "author": "itwriter", "summary": "距离“想哭”勒索病毒爆发已经过去了两周时间，然而永恒之蓝勒索蠕虫并没有就此停下脚步，此次基于 MS17-010 多个漏洞也极有可能会一直存活下去，持续制造麻烦。以下为 360 威胁情报中心提供的关于“永恒之蓝”勒索蠕虫及值得警惕的趋势。36..."},
{"url": "https://news.cnblogs.com/n/570414/", "title": "暂缓IPO后，永安行回应单车专利侵权案：已委托律师应诉", "author": "itwriter", "summary": "暂缓 IPO 后，永安行加快了处理“单车专利纠纷案”的进度。5 月 27 日下午，永安行在其官方网站发布声明，坚持认为永安行的技术方案与顾泰来先生的专利权要求保护的范围不同，不构成侵权。并表示已经委托相关律师事务所全权处理并准备应诉事宜。声明中还继续谈到，永安..."},
{"url": "https://news.cnblogs.com/n/570413/", "title": "野心不小：从纸盒到Daydream 谷歌渴望VR独立运行", "author": "itwriter", "summary": "5 月 27 日消息，据 CNET 报道，3 年前，谷歌首次发布了 Cardboard，即不到 20 美元的 DIY 套件，几乎可以将任何手机变成虚拟现实（VR）浏览器。它是如此的简单，如此的便宜，以至于《纽约时报》最终决定向订阅印双版报纸的用户免费赠送。但是作为应对需要与高端电脑硬件绑定的 O..."},
{"url": "https://news.cnblogs.com/n/570412/", "title": "北斗/GPS导航定位基准服务启用！精度/信号大提升", "author": "itwriter", "summary": "卫星定位不准确、信号弱的情况时有发生，当然相比初期的导航已经有了很好的表现，但这都是凭借更多卫星数量实现的。现在全国卫星导航定位基准服务系统正式启用，意味着未来卫星定位将更加精准，更可靠快速。该系统是我国目前规模最大、覆盖范围最广的导航定位服务系统，能够兼容北斗、GPS、格洛..."},
{"url": "https://news.cnblogs.com/n/570411/", "title": "农村淘宝APP正式停用：并入手机淘宝", "author": "itwriter", "summary": "农村淘宝是阿里巴巴集团的战略项目，为服务农民、创新农业，阿里计划在三至五年内投资 100 亿元，建立 1000 个县级服务中心和 10 万个村级服务站。同时，阿里还推出了配套的农村淘宝 APP。不过根据官方公告，从 6 月 1 日起，农村淘宝 APP 将会完全停用，随后并入手..."},
{"url": "https://news.cnblogs.com/n/570410/", "title": "苹果地图更新 可显示Apple Park 3D模型", "author": "itwriter", "summary": "近日苹果对地图应用进行了更新，完善应用中与 Apple Park 园区相关的信息，这款应用现在可以显示 Apple Park 3D 模型、人行道以及园区中的其他 POI。如上图，苹果地图中已经有了非常详尽的 Apple Park 3D 建筑模型图，以及所有与园区里里外外相同的道路和人行道等，苹果..."},
{"url": "https://news.cnblogs.com/n/570409/", "title": "亚马逊市值不断飙升 CEO贝索斯财富快赶上比尔·盖茨了", "author": "itwriter", "summary": "根据福布斯的消息，亚马逊公司估价不断创下历史新高，这也使得亚马逊公司 CEO 贝佐斯的净资产不断提升。截至周五股市收盘，贝佐斯净资产增长 28 亿美元至 847 亿美元，创下历史新高。同时他也成为了财富增长最快的亿万富翁，距离比尔盖茨的差距越来越近，只有 38 亿美元左右的差距了。\r..."},
{"url": "https://news.cnblogs.com/n/570408/", "title": "腾讯AI Lab副主任俞栋：语音识别领域四大前沿问题亟待研究", "author": "itwriter", "summary": "5 月 27 日，由机器之心主办、为期两天的全球机器智能峰会（GMIS 2017）在北京 898 创新空间顺利开幕。腾讯 AI Lab 副主任俞栋博士、「LSTM 之父」Jürgen Schmidhuber、加州大学伯克利分校人工智能系统中心创始人 Stuart Russe..."},
{"url": "https://news.cnblogs.com/n/570407/", "title": "淘宝心选自营店试运营 满79元包邮/7天无理由退货", "author": "itwriter", "summary": "淘宝和京东是国内最大的两个电商平台一直以来各有各的特点，京东自营深深的吸引消费者，在全国主要城市下单都可以做到 24 小时内送货上门。而阿里旗下的淘宝以及天猫商城则货源品种丰富，可以随心所欲的买买买。但随着“自营”概念的深入人心，淘宝也采取了更灵活的方式，淘宝..."},
{"url": "https://news.cnblogs.com/n/570406/", "title": "爱奇艺龚宇：后来者居上的六点思考", "author": "itwriter", "summary": "编者按：本文来自“IDG 资本”（ID：idg_capital），在 5 月 12 日主题为“IPO 之路”的「IDG 资本私享会」上，爱奇艺创始人&CEO 龚宇分享了他创办爱奇艺以来的六点思考。其实当爱奇艺进入视频行业的时候，..."},
{"url": "https://news.cnblogs.com/n/570405/", "title": "新加坡首家苹果零售店开业：人山人海！", "author": "itwriter", "summary": "5 月 28 日，国外媒体报道，经过近两年的期盼，苹果在新加坡的首个零售店周六正式向公众开放，这也是苹果在东南亚的第一家零售店。该苹果商店位于新加坡著名的旅游购物街乌节路（Orchard Road)，店里的 237 名员工在上午 10 点就开门迎接大批粉丝的光顾，并向那些早日抵达的人发放..."},
{"url": "https://news.cnblogs.com/n/570404/", "title": "阿里成为二股东后，联华线下3618家门店会怎么变", "author": "itwriter", "summary": "在签订战略框架协议三个月多月后，阿里系与百联集团资本层面的合作终于落地。日前，阿里巴巴集团受让了易果生鲜持有的联华超市 18% 的内资股权，成为联华超市第二大股东，而联华超市的控股方正是百联集团。在阿里的大电商板块中，从此收购中，获益最多的板块，应该是天猫超市，3618 家门..."},
{"url": "https://news.cnblogs.com/n/570403/", "title": "来看看Win32资源监视器在Fluent Design设计语言下的样子", "author": "itwriter", "summary": "近日，微软推出了全新语言 Fluent Design，对此，一位来自 Redditor 的网友决定来看看 Win32 资源监视器(Resource Monitor)在这套新语言下的样子。可以看到，使用了新设计语言的 Win32 Resouce Monitor 看起来非常精简，像 CPU、内存、网..."},
{"url": "https://news.cnblogs.com/n/570402/", "title": "Google Play Music新用户免费服务使用期限延至4个月", "author": "itwriter", "summary": "据外媒报道，日前，谷歌将面向 Google Play Music 新用户推出的免费服务使用期限延长到了 4 个月，该免费服务使用期限只有 3 个月。据悉，只要用户开始使用他们的谷歌账号绑定 Google Play Music 即可享受这一优惠，等到 4 个月后，用户可以决定取消服务或继续使用，后..."}
]
```
这只是一个简单的示例程序，如果需要按照一定抓取规则采集数据还需要进一步改造spider。




    
    