---
title: "vue-cli3.0项目中[WDS] Disconnected!的解决方法"
date: 2018-11-13
excerpt: "vue-cli3.0热加载问题"
description: "vue-cli3.0热加载问题"
gitalk: true
author: L'
tags:
    - vue
    - vue-cli
categories: [ Tips ]
---

项目中的前端工程用到了vue-cli3.0脚手架，启动后console一直报错

```bash
Failed to load resource: net::ERR_EMPTY_RESPONSE [http://localhost:8080/sockjs-node/info?t=1541988880077]
[WDS] Disconnected!
```

查了下应该是webpack中的用到的热加载功能需要通过websocket方式连接`http://localhost:8080/sockjs-node/info`,连不上导致报错。试了下本机`http://localhost:8080/sockjs-node/info`确认连不上，但是`http://127.0.0.1:8080/sockjs-node/info`可以连上，感觉有点诡异，遂ping了一下localhost,系统返回

```bash
C:\Users\user>ping localhost

正在 Ping DESKTOP-RNQGUFA [::1] 具有 32 字节的数据:
来自 ::1 的回复: 时间<1ms
来自 ::1 的回复: 时间<1ms
来自 ::1 的回复: 时间<1ms
来自 ::1 的回复: 时间<1ms
```

看来就是这个问题了，一番百度之后原来是win10默认设置的ipv6的优先级高于ipv4，所以把localhost解析到ipv6去了（win7应该不存在这个问题）,解决方案有设置参数及修改注册表等好几种，命令行要打很多相关设置，我这边使用的是比较简单的修改注册表方式,具体方法为打开注册表`HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\tcpip6\Parameters`,增加键值`DisabledComponents`,类型为`DWORD`,值为`20`,指类型为`16进制`，重启电脑后生效
