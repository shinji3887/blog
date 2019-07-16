---
title: "vue-cli3.0使用proxytable解决跨域问题"
date: 2019-05-11
excerpt: "vue-cli3.0使用proxytable解决跨域问题"
description: "vue-cli3.0使用proxytable解决跨域问题"
gitalk: true
image: "https://lupeier.cn-sh2.ufileos.com/blackboard-chalkboard-communication-355988.jpg"
author: L'
tags:
    - vue
categories: [ Tips ]
---

> 现代的web开发一般都是前后端分离，前后端使用rest api进行交互，分离使得前后端服务器一般都不在一起，这导致了跨域问题，本文说明在vue-cli中解决这一问题

### 跨域问题简述

如果浏览器有类似下面的报错信息，则说明碰到跨域问题了

```bash
localhost/:1 Failed to load http://www.abc.cn/test/testToken.php: Response to preflight request doesn't pass access control check: No 'Access-Control-Allow-Origin' header is present on the requested resource. Origin 'http://localhost:8080' is therefore not allowed access. If an opaque response serves your needs, set the request's mode to 'no-cors' to fetch the resource with CORS disabled.
```

在没有设置`Access-Control-Allow-Origin`这个标签的情况下，浏览器默认是不允许跨域发送请求的，这里面涉及到安全问题，XSS、CSRF等攻击手段都是恶意脚本的跨站访问，所以一般在服务端没有特殊说明的情况下，浏览器都是禁用CORS的。

浏览器如何判断是否是跨域访问呢？这里面就要讲到`同源策略`。同源策略（Same origin policy）是一种约定，它是浏览器最核心也最基本的安全功能，如果缺少了同源策略，则基于互联网的web访问安全会受到巨大威胁。可以说Web是构建在同源策略基础之上的，浏览器只是针对同源策略的一种实现。

简单的来说：**协议、IP、端口三者都相同，则为同源**。不是同源的脚本不能操作其他源下面的对象。
![cors.png](https://upload-images.jianshu.io/upload_images/14871146-70d0f99e722432dc.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 解决方案

`同源策略`保障了互联网的安全访问，但是却对于前后端分离的应用带来了挑战。幸运的是，现在的解决方案也很多，比如`script标签`、`jsonp`、`后端设置cors`等等。之前我是用的方式即是服务端设置cors，返回标头内携带`access-control-allow-origin: *`标签，可解决跨域问题。配置如下（使用spring boot开发的后端服务）

```java
@Configuration
public class CorsConfig {
    private CorsConfiguration buildConfig() {
        CorsConfiguration corsConfiguration = new CorsConfiguration();
        corsConfiguration.addAllowedOrigin("*"); // 1
        corsConfiguration.addAllowedHeader("*"); // 2
        corsConfiguration.addAllowedMethod("*"); // 3
        return corsConfiguration;
    }

    @Bean
    public CorsFilter corsFilter() {
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", buildConfig()); // 4
        return new CorsFilter(source);
    }
}
```

但这种方式一方面使得后端服务产生安全问题，另外如果碰到需要使用cookie的场景（比如会话保持），仍然还是失效的（cookie严格限制无法进行跨域访问）。所以比较推荐的做法还是在前端设置proxy代理，来解决跨域问题。这边使用的是vue-cli3.0，配置和之前略有不同,在根目录的`vue.config.js`下加入如下配置:

```js
devServer: {
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:33000/api',
        changeOrigin: true,
        ws: true,
        pathRewrite: {
          '^/api': ''
        }
      }
    }
  }
```

如此在前端所有发往`/api`的请求都会转发至后端服务`http://127.0.0.1:33000/api`,问题解决。注意这边配置的是开发环境,供调试使用,生产环境可使用nginx或haproxy的代理功能进行转发.
