---
title: "搭建eureka高可用集群"
date: 2019-03-08
excerpt: "eureka高可用集群搭建"
description: "eureka高可用集群搭建"
gitalk: true
image: "https://lupeier.cn-sh2.ufileos.com/architecture-athens-building-164336.jpg"
author: L'
tags:
    - Spring Cloud
categories: [ Tech ]
---

>eureka高可用集群搭建

通常来说，高可用集群需要3个节点，通过各个节点之间进行复制和互相注册来保障注册中心的高可用。任何一个注册中心节点挂掉对集群都不会有影响，甚至全部的eureka节点挂掉，客户端之间的调用也不受影响（客户端的ribbon会缓存服务注册列表，当然此时新的服务就没法注册了），集群架构图如下
![eureka-cluster.png](https://upload-images.jianshu.io/upload_images/14871146-4de9ba7fd9f2ba01.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

废话不多说，直接上配置文件

```yaml
spring:
    application:
        name: eureka-server
server:
    port: 10001
eureka:
    client:
        register-with-eureka: true
        fetch-registry: true
    server:
        enable-self-preservation: false
---
spring:
  profiles: peer1_test
eureka:
  instance:
    hostname: dce304-master-vm1
  client:
    serviceUrl:
      defaultZone: http://dce304-master-vm2:10001/eureka/,http://dce304-master-vm3:10001/eureka/
---
spring:
  profiles: peer2_test
eureka:
  instance:
    hostname: dce304-master-vm2
  client:
    serviceUrl:
      defaultZone: http://dce304-master-vm1:10001/eureka/,http://dce304-master-vm3:10001/eureka/
---
spring:
  profiles: peer3_test
eureka:
  instance:
    hostname: dce304-master-vm3
  client:
    serviceUrl:
      defaultZone: http://dce304-master-vm1:10001/eureka/,http://dce304-master-vm2:10001/eureka/
```

这边有两点需要注意

- `register-with-eureka`和`fetch-registry`两个参数要设置为`true`，这样eureka会自注册，否则的话其他eureka发现不了这个节点（当然也可以不设置这两个参数，默认值就是true）
- `eureka.instance.hostname`设置的主机名和其他两个节点中的`defaultZone`当中的主机名要保持一致，否则`available-replicas`中也不会出现可用副本信息

完成配置后，分别启动三个节点，启动时指定不同的profile参数
`java -jar eureka-server-0.0.1-SNAPSHOT.jar --spring.profiles.active=peer3_test >log.txt &`
启动完成后打开控制台，看到available-replicas中显示有两个节点，集群搭建完成
![eureka.png](https://upload-images.jianshu.io/upload_images/14871146-f9cd9270acb209ea.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
