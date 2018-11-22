---
title: "Spring Cloud升级Finchley版本小结及遇到的坑"
date: 2018-11-08
excerpt: "spring cloud 版本升级"
description: "spring cloud版本升级说明"
gitalk: true
author: L'
tags:
    - Spring Cloud
categories: [ Tech ]
---
>Finchley正式RELEASE版本发布也有段时间了，如果想体验spring boot2.0的魅力以及spring 5.0的新功能，自然是要把Spring Cloud升级至F版。升级过程小结如下

### 准备工作
升级步骤非常简单，修改一下pom依赖项即可，maven会自动下载所有的对应依赖（注意jdk必须为1.8以上版本），这也是我喜欢spring boot的原因，清爽不紧绷~
原来的配置为
```xml
<version.spring-boot>1.5.14.RELEASE</version.spring-boot>
<version.spring-cloud>Edgware.SR3</version.spring-cloud>
```
直接修改为F版的依赖配置（此处按照官方文档的配置，第一个坑）
```xml
<version.spring-boot>2.0.1.RELEASE</version.spring-boot>
<version.spring-cloud>Finchley.SR2</version.spring-cloud>
```
### 趟坑之旅
下载完更新依赖之后，发现有一个地方报错，找不到eureka-client组件，原配置为
```xml
<dependency>
   <groupId>org.springframework.cloud</groupId>
   <artifactId>spring-cloud-starter-eureka</artifactId>
</dependency>
```
F版中spring cloud对这个组件的命名规范做了调整，增加了公司名，个人感觉是为了以后接入更多的注册中心做准备，比如 `spring-cloud-alibaba-nacos`这类的，修改配置如下：
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
```
依赖项解决，启动服务，发现起不来-_-#,系统报错有循环依赖
```bash
***************************
APPLICATION FAILED TO START
***************************
Description:
The dependencies of some of the beans in the application context form a cycle:
    servletEndpointRegistrar defined in class path resource [org/springframework/boot/actuate/autoconfigure/endpoint/web/ServletEndpointManagementContextConfiguration.class]
    ↓
    healthEndpoint defined in class path resource [org/springframework/boot/actuate/autoconfigure/health/HealthEndpointConfiguration.class]
    ↓
```
在百度一顿谷歌之后，发现是 `actuate`组件的健康检测和我自己注入的数据库连接池产生了循环依赖。因为spring boot2的默认数据库连接池改成了 `Hikari`，官方文档显示这是spring boot2的一个早期bug...(要不怎么叫趟坑之旅呢)，把spring boot依赖升级到最新的`2.0.6.RELEASE`,应用可以正常启动了
启动完成后，发现eureka注册中心里面注册的服务显示不了正确的ip地址了，一顿查之后发现是配置又改了...,原来是
```bash
${spring.cloud.client.ipAddress}
```
现在要改成
```bash
${spring.cloud.client.ip-address}
```
之后又发现项目里面有很多报错，因为我项目里用到jpa的语法做数据库查询（正常项目里应该都会用到），没错，spring boot2的jpa语法又改了...
原来的写法
```java
Service service = serviceRepository.findOne(id);
```
需要改成
```java
Service service = serviceRepository.findById(id).get();
```
同理还有 `exists`和 `delete`方法都要改成 `existsById`和 `deleteById`，所幸项目本身还在起步阶段，要改的地方不多，改完之后项目终于不报错了，启动完验证接口测试成功。

总结一下：前几步都是配置问题，耐心修改完即可，最后一步因为涉及到代码的修改，需要慎重评估，如果有项目中已经在大量使用原spring boot1.5的jpa，建议慎重考虑（当然还有一种方法可以单独降级jpa的版本至1.x版本，但不确定是否会和spring boot2有兼容性问题）。另外实测spring boot2的应用去连老版本的eureka和config server都没有问题，应该是对应服务的restful接口并没有修改，所以基础组件也可以不升级。针对 `SpringCloudGateway2.0` 以及 `spring boot2`的新特性，待后续分享。