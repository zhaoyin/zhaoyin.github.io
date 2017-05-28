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

    name = "cnblogs"

    def start_requests(self):
        urls = [
            'https://news.cnblogs.com/n/page/1/',
            'https://news.cnblogs.com/n/page/2/',
            'https://news.cnblogs.com/n/page/3/'
        ]
        for url in urls:
            yield scrapy.Request(url=url, callback=self.parse)

    def parse(self, response):
        page = response.url.split('/')[-2]
        filename = 'cnblogs-%s.json' % page
        with open(filename, 'wb') as f:
            data = []
            for new in response.css('div#news_list div.content'):
                new_content = {
                    'title': ''.join(new.css('h2.news_entry a::text').extract()),
                    'summary': ''.join(new.css('div.entry_summary::text').extract()[1].lstrip().rstrip()),
                    'author': ''.join(new.css('div.entry_footer a::text').extract()[0].strip()),
                    'url': 'https://news.cnblogs.com'+new.css('h2.news_entry a::attr(href)').extract_first()
                }
                data.append(new_content)

            f.write(unicode.encode(json.dumps(data, ensure_ascii=False, sort_keys=True, indent=4)+'\r\n', 'utf-8'))
        self.log('save file %s' % filename)
        f.close()

```

## 运行Spider

完成了一个简单的spider，如何运行它来输出我们需要的结果呢？
在项目的根目录中执行如下的命令：

```
scrapy crawl cnblogs
```
其中cnblogs即为定义的spider的name


最终输出一个完整的json数据
![img](http://oqcey66z7.bkt.clouddn.com/public/images/scrapy-spider-export-json.png)

这只是一个简单的示例程序，如果需要按照一定抓取规则采集数据还需要进一步改造spider。




    
    