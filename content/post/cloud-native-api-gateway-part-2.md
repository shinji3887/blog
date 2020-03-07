---
title: "构建云原生微服务网关系列-篇二：Zuul"
date: 2019-09-29
excerpt: "云原生微服务网关系列"
description: "这篇是云原生网关系列的第二篇，这次我们来看一下在不引入Spring Cloud技术栈的情况下使用zuul来实现云原生网关。"
gitalk: true
image: "https://lupeier.cn-sh2.ufileos.com/ancient-antique-arch-220580.jpg"
author: 陆培尔
tags:
    - Cloud Native
    - Api Gateway
categories: [ Tech ]
---

> 使用Spring Cloud的api网关组件Zuul结合Spring Cloud Kubernetes项目构建云原生网关

这篇是云原生网关系列的第二篇，这次我们来看一下在不引入Spring Cloud技术栈的情况下使用zuul来实现云原生网关。

### Zuul介绍

Zuul是大名鼎鼎的微服务框架Spring Cloud中的网关组件，由netflix公司开发，目前在微服务框架领域有着广泛的应用。Zuul有1.x和2.x两个版本，1.x是同步阻塞模型，2.x是异步非阻塞模型，理论上2.x版本能够同时处理更多的连接数，性能也会更好。但是我推荐中小型的公司，仍然使用1.x版本，理由是模型足够简单，且性能对于普通的应用场景已经足够使用。具体的对比可以参考杨波老师的这篇博客文章，分析的非常清楚了[http://blog.didispace.com/api-gateway-Zuul-1-zuul-2-how-to-choose/](http://blog.didispace.com/api-gateway-Zuul-1-zuul-2-how-to-choose/) 。Spring Cloud Gateway模型和Zuul 2.x非常类似，因为Zuul2难产，所以Spring Cloud 官方抛弃了Zuul2,自己搞了一个Spring Cloud Gateway，这里不展开了。以下未作特殊说明的话，zuul均指代zuul1.x版本。

### Zuul的优势

Zuul基于java开发，考虑到java现在庞大的群众基础，zuul天生对于大多数程序员友好。在实际业务中，网关一般会有很多定制化的需求，比如各类适配器/filter的开发，报文格式转换，认证/授权等等，需要进行大量的个性化开发。如果你是一个java（Spring Boot）程序员，那这种无缝的开发体验是你一定喜欢的。

### Zuul的劣势

主要还是出来的比较早，zuul出来的时候还没有云原生的概念，所以自然也不是按照云原生的理念设计的网关。主要表现为不可编程（各类行为都需要通过yml配置来进行操作，当然结合配置中心也可以实现部分动态配置的能力），网关本身不是CRD资源等等。性能方面倒其实不必太过担心，虽然zuul使用java开发，而且是同步阻塞模型，但应用绝大部分的场景已经绰绰有余了。

### Spring Cloud Kubernetes

zuul一般都是在Spring Cloud全家桶中配套使用，但是在现在的云原生大潮中，kubernetes、service mesh风生水起，为了使用一个网关产品而引入Spring Cloud的全套技术栈，未免会感觉有点重。所以接下来就是今天的重点，介绍如何在**脱离Spring Cloud的环境下在kubernetes中使用zuul网关**。这里就需要介绍一个项目，[Spring Cloud Kubernetes](https://spring.io/projects/spring-cloud-kubernetes)。这个项目是Spring Cloud的一个子项目，在Greenwich中已经正式毕业。作用是把kubernetes中的服务模型映射到Spring Cloud的服务模型中，以使用Spring Cloud的那些原生sdk在kubernetes中实现服务治理。具体来说，就是把k8s中的services对应到Spring Cloud中的services，k8s中的endpoints对应到Spring Cloud的instances。这样通过标准的Spring Cloud api就可以对接k8的服务治理体系。

老实说，个人认为这个项目的意义并不是很大，毕竟都上k8了，k8本身已经有了比较完善的微服务能力（有注册中心、配置中心、负载均衡能力），应用之间直接可以互相调用，应用完全无感知，你再通过sdk去调用，有点多此一举的感觉。而且现在强调的是语言非侵入，Spring Cloud一个很大的限制是只支持java语言（甚至比较老的j2ee应用都不支持，只支持Spring Boot应用）。所以我个人感觉，这个项目，在具体业务服务层面，使用的范围非常有限。但是如果放在网关上去用，我倒是觉得非常合适。首先网关本身就是和具体服务解耦的，网关的替换对于服务没有感知（今天你用的zuul，明天你用ambassador服务都不知道），这样的话升级就非常灵活。第二，由于zuul是基于ribbon做的客户端的负载均衡，这使得zuul获得了一个非常重要的，其他网关都不具备的能力，即**动态的感知集群中的服务列表**，换句话说，你新发布一个应用，zuul可以立即感知并正确路由，而其他的网关都是需要进行主动配置的（如果有其他网关也有这个能力，请指正）。原理其实也比较简单，Spring Cloud Kuberntes项目调用了一组fabric8的工具包，从pod内调用kubernetes的api server，获取services及对应的endpoints的列表，注册至ribbon中，后面就和普通的spring cloud的服务调用一样了。

借助于Spring Cloud Kubernetes项目，zuul具有了与k8体系融合的网关路由能力，并且无需借助任何spring cloud的其他组件，而这也是我认为可以称其为云原生网关的原因。

### 项目引用

想使用Spring Cloud Kubernetes项目，只要在pom文件中简单引用就好（Spring Cloud版本必须在Greenwich以上）。

```xml
<properties>
  <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
  <java.version>1.8</java.version>
  <spring-cloud.version>Greenwich.SR2</spring-cloud.version>
</properties>

<dependencies>
  <dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-zuul</artifactId>
  </dependency>
  <dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-kubernetes</artifactId>
  </dependency>
  <dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-kubernetes-ribbon</artifactId>
  </dependency>
</dependencies>
```

这时候你启动项目的话会报错

```bash
Caused by: java.net.ConnectException: Failed to connect to localhost/0:0:0:0:0:0:0:1:6445
```

这是因为fabric8试图寻找api server，当然你本地是找不到的了...，项目必须要部署在k8集群内才能正常启动。不过到了这里先别急，由于k8的rbac机制，默认的serviceaccount（default）是没有service和endpoints的操作权限的，我们需要先给网关应用创建账号，并添加合适的权限。

### 添加role及rolebinding

这边先介绍一下k8的rbac体系，简单说就是serviceaccount（服务账户）+role（可操作资源的角色）+rolebinding（服务账户与角色的绑定）：
![image.png](https://upload-images.jianshu.io/upload_images/14871146-48026ab985090218.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
要想在pod内调用k8s的api，则必须通过kubernetes这个service，api server会首先对pod的serviceaccount进行身份验证，然后根据rolebinding确定该账户拥有的权限（role），再根据role判断该角色可以执行的操作，最终得出该账户是否有权限操作该api的结论。需要注意的是，kubernetes会给每个pod默认注入一个default的sa，但是这个sa默认是啥权限没有的（否则就不安全了）。

这边我们先创建一个serviceaccount给api 网关使用

```bash
kubectl create sa api-gateway
```

创建role资源，注意实测services、pods、endpoints这几个资源访问都必须授权，否则启动时候会报错

```bash
apiVersion: v1
items:
- apiVersion: rbac.authorization.k8s.io/v1
  kind: Role
  metadata:
    creationTimestamp: "2019-09-25T08:40:54Z"
    name: api-gateway
    namespace: default
    resourceVersion: "2374635"
    selfLink: /apis/rbac.authorization.k8s.io/v1/namespaces/default/roles/api-gateway
    uid: 03b1e1c0-eff2-4e49-8bcd-6237dce7f4f7
  rules:
  - apiGroups:
    - ""
    resources:
    - services
    - pods
    - endpoints
    verbs:
    - get
    - watch
    - list
kind: List
metadata:
  resourceVersion: ""
  selfLink: ""
```

创建rolebinding绑定角色与账户

```bash
apiVersion: v1
items:
- apiVersion: rbac.authorization.k8s.io/v1
  kind: RoleBinding
  metadata:
    creationTimestamp: "2019-09-25T08:44:20Z"
    name: api-gateway
    namespace: default
    resourceVersion: "2373625"
    selfLink: /apis/rbac.authorization.k8s.io/v1/namespaces/default/rolebindings/api-gateway
    uid: 96f2bcc6-61e0-4d24-abdc-6f52f7ad2f54
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: Role
    name: api-gateway
  subjects:
  - kind: ServiceAccount
    name: api-gateway
kind: List
metadata:
  resourceVersion: ""
  selfLink: ""
```

在api-gateway里设置serviceaccount为api-gateway，这样在pod启动的时候会把对应的serviceaccount账户信息注入pod中去，这样zuul就可以正确获取k8的service列表和endpoint列表了（这里只展示了deploy的部分片段）

```bash
spec:
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      serviceAccount: api-gateway
      serviceAccountName: api-gateway
```

这样zuul的设置就完成了，配合namespace还可以做更加精细的控制，例如zuul只在某个特定的namespace域下进行路由，其他namespace下面的服务是看不到的(借助于k8的namespace机制)，从而有效的进行服务隔离。

### 总结

借助于Spring Cloud Kubernetes项目，zuul可以以一种无侵入的方式提供api网关的能力，应用完全不需要做任何改造，并且网关是可插拔的，将来可以用其他网关产品灵活替换，整体耦合程度非常低。得益于k8的service能力，zuul甚至支持异构应用的接入，这是Spring Cloud体系所不具备的。而本身基于java开发，使得java程序员可以方便的基于zuul开发各种功能复杂的filter，而不需要去学习go或者openresty这样不太熟悉的语言。如果公司内部以java技术栈为主，同时又在实施云原生的，建议可以尝试zuul with spring cloud kubernetes整合方案。
