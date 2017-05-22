
---
title: next主题前端资源CDN加速
date: 2017-05-22 13:40:46
categories:
    - build
tags: 
    - Hexo
    - NexT
---

为NexT主题设置第三方CDN加速的资源库，提高博客加载效率
<!--more-->
```
vendors:
  # Internal path prefix. Please do not edit it.
  _internal: lib

  # Internal version: 2.1.3
  jquery: //cdn.staticfile.org/jquery/2.1.3/jquery.min.js

  # Internal version: 2.1.5
  # See: http://fancyapps.com/fancybox/
  fancybox: //cdn.staticfile.org/fancybox/2.1.5/jquery.fancybox.min.js
  fancybox_css: //cdn.staticfile.org/fancybox/2.1.5/jquery.fancybox.min.css

  # Internal version: 1.0.6
  # See: https://github.com/ftlabs/fastclick
  fastclick: //cdn.staticfile.org/fastclick/1.0.6/fastclick.min.js

  # Internal version: 1.9.7
  # See: https://github.com/tuupola/jquery_lazyload
  lazyload: //cdn.staticfile.org/jquery_lazyload/1.9.7/jquery.lazyload.min.js

  # Internal version: 1.2.1
  # See: http://VelocityJS.org
  velocity: //cdn.staticfile.org/velocity/1.2.1/velocity.min.js

  # Internal version: 1.2.1
  # See: http://VelocityJS.org
  velocity_ui: //cdn.staticfile.org/velocity/1.2.1/velocity.ui.min.js

  # Internal version: 0.7.9
  # See: https://faisalman.github.io/ua-parser-js/
  ua_parser:

  # Internal version: 4.6.2
  # See: http://fontawesome.io/
  fontawesome: //cdn.staticfile.org/font-awesome/4.6.2/css/font-awesome.min.css

  # Internal version: 1
  # https://www.algolia.com
  algolia_instant_js:
  algolia_instant_css:

  # Internal version: 1.0.0
  # https://github.com/hustcc/canvas-nest.js
  canvas_nest: //cdn.staticfile.org/canvas-nest.js/1.0.0/canvas-nest.min.js

  # three
  three: //cdn.staticfile.org/three.js/r83/three.min.js

  # three_waves
  # https://github.com/jjandxa/three_waves
  three_waves:

  # three_waves
  # https://github.com/jjandxa/canvas_lines
  canvas_lines:

  # three_waves
  # https://github.com/jjandxa/canvas_sphere
  canvas_sphere:

  # Internal version: 1.0.0
  # https://github.com/zproo/canvas-ribbon
  canvas_ribbon:

  # Internal version: 3.3.0
  # https://github.com/ethantw/Han
  han: //cdn.staticfile.org/Han/3.3.0/han.min.js

```