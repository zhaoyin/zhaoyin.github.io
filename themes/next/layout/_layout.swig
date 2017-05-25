<!doctype html>

{% set html_class = 'theme-next ' + theme.scheme %}
{% if theme.use_motion %}
  {% set html_class = html_class + ' use-motion' %}
{% endif %}

<html class="{{ html_class | lower }}" lang="{{ config.language }}">
<head>
  {% include '_partials/head.swig' %}
  <title>{% block title %}{% endblock %}</title>
</head>

<body itemscope itemtype="http://schema.org/WebPage" lang="{{ page.lang || page.language || config.language }}">

  {% include '_third-party/analytics/index.swig' %}

  {% set container_class = "container " %}
  {% if theme.sidebar.position %}
    {% set container_class = container_class + 'sidebar-position-' + theme.sidebar.position %}
  {% endif %}

  <div class="{{ container_class }} {% block page_class %}{% endblock %} ">
    <div class="headband"></div>

    <header id="header" class="header" itemscope itemtype="http://schema.org/WPHeader">
      <div class="header-inner"> {%- include '_partials/header.swig' %} </div>
    </header>

    <main id="main" class="main">
      <div class="main-inner">
        <div class="content-wrap">
          <div id="content" class="content">
            {% block content %}{% endblock %}
          </div>

          <! -- 添加捐赠图标 -->
    <div class ="post-donate">
      <div id="donate_board" class="donate_bar center">
        <a id="btn_donate" class="btn_donate" href="javascript:;" title="Donate 打赏"></a>
        <span class="donate_txt">
           ↑<br>
           Enjoy it ? Donate me !  欣赏此文？求鼓励，求支持！
           {% endif %}          
        </span>
        <br>
      </div>  
  
    <!-- 支付宝打赏图案 -->
      <div id="donate_guide" class="donate_bar center hidden">
          <a href="http://oqcey66z7.bkt.clouddn.com/public/images/WechatIMG13.jpeg" title="支付宝打赏" class="fancybox" rel="article0"       style="float:left;margin-left:25%;margin-right:2px;">
          <img src="http://oqcey66z7.bkt.clouddn.com/public/images/WechatIMG13.jpeg" title="支付宝打赏" height="164px" width="164px">
          </a> 
      </div>

    <!-- 微信打赏图案 -->
      <div id="donate_guide" class="donate_bar center hidden">
          <a href="http://oqcey66z7.bkt.clouddn.com/public/images/WechatIMG14.jpeg" title="微信打赏" class="fancybox" rel="article0"  >
          <img src="http://oqcey66z7.bkt.clouddn.com/public/images/WechatIMG14.jpeg" title="微信打赏" height="164px" width="164px">
          </a> 
      </div>
  
      <script type="text/javascript">
        document.getElementById('btn_donate').onclick = function(){
          $('#donate_board').addClass('hidden');
          $('#donate_guide').removeClass('hidden');
        }
      </script>
    </div>
<! -- 添加捐赠图标 -->


          {% include '_third-party/duoshuo-hot-articles.swig' %}
          {% include '_partials/comments.swig' %}
        </div>
        {% if theme.sidebar.display !== 'remove' %}
          {% block sidebar %}{% endblock %}
        {% endif %}
      </div>
    </main>

    <footer id="footer" class="footer">
      <div class="footer-inner">
        {% include '_partials/footer.swig' %}
        {% include '_third-party/analytics/busuanzi-counter.swig' %}
        {% block footer %}{% endblock %}
      </div>
    </footer>

    {% if not theme.sidebar.b2t %}
      <div class="back-to-top">
        <i class="fa fa-arrow-up"></i>
        {% if theme.sidebar.scrollpercent %}
          <span id="scrollpercent"><span>0</span>%</span>
        {% endif %}
      </div>
    {% endif %}

  </div>

  {% include '_scripts/vendors.swig' %}
  {% include '_scripts/commons.swig' %}

  {% set scheme_script = '_scripts/schemes/' + theme.scheme | lower + '.swig' %}
  {% include scheme_script %}

  {% block script_extra %}{% endblock %}

  {% include '_scripts/boostrap.swig' %}

  {% include '_third-party/comments/index.swig' %}
  {% include '_third-party/search/index.swig' %}
  {% include '_third-party/analytics/lean-analytics.swig' %}
  {% include '_third-party/seo/baidu-push.swig' %}
  {% include '_third-party/mathjax.swig' %}
  {% include '_third-party/scroll-cookie.swig' %}
  {% include '_third-party/exturl.swig' %}
</body>
</html>
