---
title: "基于Spring Cloud Config和Kubernetes ConfigMap进行微服务集群的配置管理"
date: 2018-11-12T22:57:00+08:00
excerpt: "spring cloud config分布式配置中心实践"
description: "spring cloud config分布式配置中心实践"
gitalk: true
author: L'
tags:
    - Spring Cloud
    - Kubernetes
categories: [ Tech ]
---

>众所周知，配置管理是微服务中非常重要的一环。通过集中化的配置中心，可以使维护人员统一管理`dev`、`test`、`stage`、`prod`等各类环境的配置，大大提高了维护效率，并使得配置变更可以实时下发给各节点，并被追踪和审计，本文探讨云原生环境下基于Spring Cloud Config+kubernetes ConfigMap的配置管理实践，大家如果有更好的实现方式，也欢迎一起探讨。

### 方案选择

目前的配置获取方式，基本上有以下几种

* 环境变量注入：这种方式把配置参数直接注入系统环境变量，应用直接从环境变量中获取配置信息，配置项较少的情况还是可以用用的，多了麻烦不说，配置的变更审计也是问题，`configmap`即是这种方式，好处是系统级，外部依赖较少

* 通过maven工具：执行类似`mvn cleanpackage-Penv`这样的命令，在编译打包阶段将环境信息注入

* spring boot：Spring Boot中也提供了多环境配置功能，可以设置`application-{env}.properties`区分环境信息，启动时增加
`spring.profiles.active=dev`这样的参数，在启动时将配置信息注入

* 配置中心：这是微服务架构中比较主流的解决方案，有代表性的有携程的apollo、百度disconf以及spring自己的 spring cloud config

综合几种方式的优缺点，我选择了Spring Cloud Config+kubernetes ConfigMap的解决方案。选择Spring Cloud Config的原因是比较轻量级，配合eureka可以快速搭建一个分布式的配置中心，再结合一些开源的配置管理UI框架（比如SCCA，后面会提到），基本可以满足目前的需要。结合Spring Cloud Bus组件可以实现实时的配置下发，另外由于是原生的，和Spring其他组件的集成也比较方便，不像apollo都是自己一套（自带eureka），个人感觉有点重了。为便于叙述，下文假设有dev、test、prod三个配置中心，分别对应三个不同的环境。

### 环境变量配置

使用环境变量的原因，是开发和测试的环境不一致，开发一般在自己电脑上进行开发，所以需要设置自己终端的环境变量，而测试及生产环境都是在K8S集群内，所以需要通过ConfigMap来进行环境变量配置，从而实现了配置中心地址与环境的解耦。

#### 开发终端配置

比较简单，直接在环境变量中设置如下参数，注意这里设置的是dev环境的配置中心 
![env.jpg](https://upload-images.jianshu.io/upload_images/14870226-daf5ce95376a040c.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


 注意设置完之后eclipse需要重启一下，否则读不到变更的环境变量（IDEA我没有测过，不知道是不是一样）。可以通过下面这段代码看看环境变量是否正确获取
```java
@RestController
public class WebController {

   @Autowired
   private Environment env;

   @RequestMapping(value = "getEnvParam", method = RequestMethod.GET)
   public String getEnvParam() {
        return "config server : " + env.getProperty("CONFIG_SERVER_ADDRESS");
   }

}
```
在浏览器输入URL后应该可以显示对应的环境变量值

#### ConfigMap配置

使用kubectl创建configmap资源有几种方式，这里我们直接使用命令行参数的方式创建配置信息对象，注意这里配置的是test环境的配置中心
```bash
[root@localhost ~]# kubectl create configmap config-server --from-literal=config.address=http://10.10.0.2:10002 --from-literal=config.profile=test
configmap "config-server" created
```
执行如下命令确认configmap资源被成功创建
```bash
[root@localhost ~]# kubectl get configmap config-server -o yaml
apiVersion: v1
data:
  config.address: http://10.10.0.2:10002
  config.profile: test
kind: ConfigMap
metadata:
   creationTimestamp: 2018-11-07T11:14:27Z
   name: config-server
   namespace: default
   resourceVersion: "18390952"
   selfLink: /api/v1/namespaces/default/configmaps/config-server
   uid: 4a4b3713-e27e-11e8-8088-005056bd4c7c
```
将configmap对象注入我们创建的应用deployment对象中，可以直接edit资源，也可以使用patch方式，注意`spec.containers.env`部分，即是我们注入的configmap信息
```yaml
spec:
  replicas: 1
  selector:
    matchLabels:
      run: service-base
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        run: service-base
    spec:
      containers:
      - command:
        - java
        - -Djava.security.egd=file:/dev/./urandom
        - -jar
        - /home/app.jar
        env:
        - name: CONFIG_SERVER_ADDRESS
          valueFrom:
            configMapKeyRef:
              key: config.uri
              name: config-server
        - name: CONFIG_SERVER_PROFILE
          valueFrom:
            configMapKeyRef:
              key: config.profile
              name: config-server
        image: 10.0.0.62:5000/alpine/jre:8
        imagePullPolicy: IfNotPresent
        name: service-base
        ports:
        - containerPort: 33300
          protocol: TCP
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /home
          name: app-volume
      dnsPolicy: ClusterFirst
```
### Spring Cloud Config配置

这其实就是一个标准的Spring Cloud Config配置中心配置，这里不展开了，需要的同学可以直接看[这篇教程](http://blog.didispace.com/spring-cloud-starter-dalston-3)。考虑到开发生产环境的隔离、管理和可靠性的需要，我这边使用的是db存储模式（需要edgware以上版本），配置文件如下
```yaml
spring:
    application:
        name: config-server
    datasource:  
        driver-class-name: oracle.jdbc.driver.OracleDriver
        url: jdbc:oracle:thin:@10.0.0.56:1521/orac
        username: test
        password: test
    jpa:
        properties:
            hibernate:
                dialect: org.hibernate.dialect.Oracle10gDialect
    profiles:
        active: jdbc
    cloud:
         config:
             server:
                 jdbc: 
                     sql: SELECT P_KEY, P_VALUE from PROPERTY where APPLICATION=? and PROFILE=? and LABEL=?
server:
    port: 10002
encrypt:
    key: test
```

之后配合一个程序猿DD同学开源的配置管理项目SCCA（[github地址](https://github.com/dyc87112/spring-cloud-config-admin)）,能以可视化方式管理各环境配置，基本满足目前要求。如果想和内部已有的服务管理平台集成，也非常方便，只要实现对property这张配置表的CRUD就行了，spring cloud config会自动监听property里的变化并刷新参数，这也是我比较推荐db模式的原因。SCCA配置界面如下：


![admin1.jpg](https://upload-images.jianshu.io/upload_images/14870226-351d78b661aa2cd5.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![admin2.jpg](https://upload-images.jianshu.io/upload_images/14870226-f081274ced7c8527.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 应用配置

至此所有准备工作完成，在应用里直接配置上配置中心的环境变量，就可以在各环境中无缝切换了，应用配置如下
```yaml
spring:
    application:
         name: service-base
    cloud:
         config:
             uri: ${CONFIG_SERVER_ADDRESS}
             profile: ${CONFIG_SERVER_PROFILE}
             label: master
server:
    port: 33000
```
