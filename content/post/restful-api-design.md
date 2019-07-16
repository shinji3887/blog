---
title: "浅淡RESTful api设计规范"
date: 2018-11-29
excerpt: "restful架构的设计思想与最佳实践"
description: "restful架构的设计思想与最佳实践"
gitalk: true
image: "https://lupeier.cn-sh2.ufileos.com/abstract-expressionism-abstract-painting-acrylic-1509534.jpg"
author: L'
tags:
    - Microservice
    - RESTful
categories: [ Tech ]
---

>目前主流的通讯协议主要有RPC、http/1.1、http/2等，而http中最主流的无疑就是restful了，由于工作的原因，经常需要和不同的外部服务商进行系统集成，给出的文档都说是基于restful规范设计，遗憾的是，在我看来，几乎没有看到过真正可以称之为restful架构的api设计。今天就来谈谈如何设计一个规范、优雅、可读性高的restful api

restful其实本身并不是一个新鲜的东西，最早是在2000年由[Roy Thomas Fielding](http://en.wikipedia.org/wiki/Roy_Fielding)博士在他的[博士论文](http://www.ics.uci.edu/~fielding/pubs/dissertation/top.htm)中提出。说起这位老兄，来头可不小，他是http 1.0和1.1版本协议的主要设计者，apache基金会的第一任主席，可以说是现代互联网体系的奠基者。Fielding将他对互联网软件的架构原则，定名为REST，即表述层状态转移（Representational State Transfer）。这是一套在互联网体系下，调用者如何与被调用者（资源实体）进行互动的规范设计。
![rest.jpeg](https://lupeier.cn-sh2.ufileos.com/rest.jpeg)

当时的互联网其实还是处于刚萌芽的状态，这个设计思想过于超前，所以早些年一直处于不温不火的状态。直到近年来，互联网业务高速发展，系统架构越来越复杂，移动互联网的兴起，前后端分离架构的流行，人们发现原来这套用于超文本传输的协议是如此适合用于设计基于互联网的api接口，基于http动词以及标准的http status返回信息，能够非常好的描述api的特性，并且可读性非常好。更重要的是，由于http是事实上的互联网通讯标准协议，基于rest设计的api接口，就好像你出国用英语和别人交流，完全不存在沟通障碍。

关于restful设计的最佳实践，这里还是推荐阮一峰老师的[RESTful API 设计指南](http://www.ruanyifeng.com/blog/2014/05/restful_api.html)，个人觉得是国内范围里讲的最好的了。rest架构，从个人角度理解，核心做了两件事情

- 资源定位
- 资源操作

其实从REST的定义中就能看出来，表述层对应的就是描述资源的位置（资源定位），状态转移就是对资源的状态进行变更操作（增删改查）
下面举个实际的例子：
假设我们数据库里有一张User表，我们根据表建好了领域对象模型User，按照restful规范设计的接口应该是这样的：

- 新增用户

```bash
POST /users
```

- 修改用户

```bash
PUT /users/id
```

- 删除用户

```bash
DELETE /users/id
```

- 查找全部用户

```bash
GET /users
```

看到这里可能有同学就要问了，干嘛非得这么设计，还要用什么http动词，delete、put神马的我都没用过，平时都是get、post走天下，也用的好好的呀。新增用户不能用`/addUser`吗？删除用户不能用`/deleteUser`吗？感觉也很清楚啊（事实上很多公司的所谓的restful接口文档都是这么定义的）
好，现在让我们回到前面，复习一下rest的定义，第一条叫做**资源定位**，如果还不理解，那让我们再想想URL的定义，叫做**统一资源定位符**，也就是说url是用来表示资源在互联网上的位置的，所以说在url中不应该包含动词，只能包含名词，对资源的操作应该体现在http method上面。

为了便于理解，这里我们再做一个假设，jane的网站上有一张小汽车的图片，地址是`http://jane.com/img/car.jpg`,现在jane想设计一个api接口，实现对这张图片的删除操作，这个api应该怎么设计？根据rest的设计规范，很容易得出是

```bash
DELETE http://jane.com/img/car
```

非常的清晰明了（这里暂时先不考虑调用方是否有权限删除服务器上的资源）
注意这里为了讲述原理没有加资源的后缀.jpg，引用阮一峰老师的话

>严格地说，有些网址最后的".html"后缀名是不必要的，因为这个后缀名表示格式，属于"表现层"范畴，而URI应该只代表"资源"的位置。它的具体表现形式，应该在HTTP请求的头信息中用Accept和Content-Type字段指定，这两个字段才是对"表现层"的描述。

在这个例子里，我们可以通过在http header里指定content-type为`image/jpeg`来申明这个资源是一张jpg格式的图片
接下来，如果要查询（获取）这张图片呢？自然就是

```bash
GET http://jane.com/img/car
```

再进一步，我们再改造一下这个api，加上.jpg后缀，这个api就变成了

```bash
GET http://jane.com/img/car.jpg
```

看到这里大家应该都很熟悉了，这就是我们每天上网要进行无数次操作的api，就是这么设计出来的

我们继续扩展一下，现在我们要获取的不是静态图片资源了，而是一辆小汽车的相关信息，并且需要对车库里的汽车进行增删改查的维护操作。如果用上面讲的那种一般http的写法，可能会写出类似下面这样的api（只用GET和POST方法）

```bash
POST http://jane.com/garage/addCar

{"brand":"ford","model":"focus","price":"120000"}

POST http://jane.com/garage/udpateCar?id=123

{"brand":"ford","model":"focus","price":"130000"}

GET http://jane.com/garage/queryCarList

GET http://jane.com/garage/queryCarSingle?id=123

GET http://jane.com/garage/deleteCar?id=123
```

看出问题来了吗？一个严重的问题是**url丢失了资源的位置**，更重要的是，你可以叫`deleteCar`，也可以叫`eraseCar`，还可以叫`removeCar`，具体什么含义只有设计这个api的人才能说清楚。而如果用http method，那就肯定是`DELETE`这个方法,所有看这个api的人都知道你提供的是一个删除这个资源的方法，这就叫做**语义化**，能用最少的话把一个意思表达清楚，这本身就是一种优雅的设计方式。使用rest设计上述api，结果如下

```bash
POST http://jane.com/garage/cars

{"brand":"ford","model":"focus","price":"120000"}

PUT http://jane.com/garage/cars/123

{"brand":"ford","model":"focus","price":"130000"}

GET http://jane.com/garage/cars

GET http://jane.com/garage/cars/123

DELETE http://jane.com/garage/cars/123
```

这里`http://jane.com/garage/cars/123`代表了id为123的这辆小汽车在网上的唯一位置，本质上和`http://jane.com/img/car`所代表的含义是一样的。
使用rest能带来的额外的好处，是你可以做很方便的权限控制。因为`POST`、`PUT`、`DELETE`、`GET`等都是标准的http方法，你可以很轻松的在nginx这样的7层代理或者防火墙上设置策略，禁止某些资源的修改及删除操作，而这显然是自定义的url所达不到的。
除了`HTTP METHOD`,rest另外一套重要的规范就是`HTTP STATUS`，这套状态码规范定义了常规的api操作所可能产生的各种可能结果的描述，遵循这套规范，会使得你的api变得更加可读，同时也便于各种网络、基础设施进行交易状态监控。经常会用到的status code整理如下：

```bash
200 OK - [GET]：服务器成功返回用户请求的数据，该操作是幂等的（Idempotent）。
201 CREATED - [POST/PUT/PATCH]：用户新建或修改数据成功。
202 Accepted - [*]：表示一个请求已经进入后台排队（异步任务）
204 NO CONTENT - [DELETE]：用户删除数据成功。
400 INVALID REQUEST - [POST/PUT/PATCH]：用户发出的请求有错误，服务器没有进行新建或修改数据的操作，该操作是幂等的。
401 Unauthorized - [*]：表示用户没有权限（令牌、用户名、密码错误）。
403 Forbidden - [*] 表示用户得到授权（与401错误相对），但是访问是被禁止的。
404 NOT FOUND - [*]：用户发出的请求针对的是不存在的记录，服务器没有进行操作，该操作是幂等的。
406 Not Acceptable - [GET]：用户请求的格式不可得（比如用户请求JSON格式，但是只有XML格式）。
410 Gone -[GET]：用户请求的资源被永久删除，且不会再得到的。
422 Unprocesable entity - [POST/PUT/PATCH] 当创建一个对象时，发生一个验证错误。
500 INTERNAL SERVER ERROR - [*]：服务器发生错误，用户将无法判断发出的请求是否成功。
```

事情到了这里似乎一切都很美好，可惜人生不如意十之八九，api设计也不可能一帆风顺。总有一些场景是CRUD所抽象不了的，举个简单的例子，用户登陆，如何去匹配CRUD模型？这里我的建议是，先把你的操作对象或者行为抽象为资源，然后就简单了，无非就是对这个资源的CRUD。
针对用户登陆这个场景，我们可以把用户在远程服务器的会话信息抽象为一个资源，这样的话，登陆其实就是在远程服务器增加了一个会话资源，不难想到，登出就是在远程服务器删除了一个会话资源，所以api可以这样设计

```bash
POST /login
DELETE /logout
```

如果是发送短信呢？似乎更难。。。这里再次请出阮一峰老师

>如果某些动作是HTTP动词表示不了的，你就应该把动作做成一种资源。比如网上汇款，从账户1向账户2汇款500元，正确的写法是把动词transfer改成名词transaction，资源不能是动词，但是可以是一种服务

这样的话你把发送短信理解成一种服务，api可以这样设计

```bash
POST  /smsService

{"mobile":"13813888888","text":"hello world"}
```

最后建议大家去看一下github的[api文档](https://developer.github.com/v3/)，可以说是restful架构最完整的实现了，看完后一定会对restful规范有着更深入的理解。
