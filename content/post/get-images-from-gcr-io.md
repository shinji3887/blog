---
title: "通过阿里云快速获取gcr.io上的镜像文件"
date: 2019-06-02
excerpt: "通过阿里云快速获取gcr.io上的镜像文件"
description: "通过阿里云快速获取gcr.io上的镜像文件"
gitalk: true
image: "https://lupeier.cn-sh2.ufileos.com/agfa-antiquarian-camera-46794.jpg"
author: L'
tags:
    - Kubernetes
    - Docker
categories: [ Tips ]
---

> gcr.io是谷歌家的镜像仓库，我们在学习k8或者其他的云原生项目的时候不可避免的会用到上面的镜像。因为某些原因该站点无法访问，本文讲述如何通过阿里云获取gcr.io上面的镜像文件。

### 注册阿里云账号

首先需要注册一个阿里云账号，登陆后选择[容器镜像服务](https://cr.console.aliyun.com/cn-hangzhou/instances/repositories)
，这个服务可以方便快速的帮助你从本地构建镜像或者直接从github代码仓库拉取代码构建镜像
![aliyun.png](https://upload-images.jianshu.io/upload_images/14871146-ffd4543b59629cf1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 创建镜像

点击创建镜像仓库，填写好镜像的相关信息，进入下一步，这时候需要绑定一个github账号（没有的话就创建一个），并选择github中对应的仓库地址，注意下面的**海外机器构建**一定要选上，这样阿里云就会使用海外的服务器进行源镜像的拉取，以此获取gcr.io的镜像。
![2019-06-02 10.24.56.png](https://upload-images.jianshu.io/upload_images/14871146-02d09f03610e15b1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![2019-06-02 10.25.59.png](https://upload-images.jianshu.io/upload_images/14871146-fe6dee4ed3090c99.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
github 仓库的设置其实非常简单，只需要在根目录下面设置一个Dockerfile，里面设置好你需要拉取的源镜像地址就ok了
![2019-06-02 10.32.49.png](https://upload-images.jianshu.io/upload_images/14871146-5d891ca6f8d5396c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 构建镜像

创建完镜像之后，有一条默认的构建规则，需要你打一个tag，会自动触发构建，我们这里选择手动构建，添加一条构建规则，按提示输入相关信息，版本可以自己定义，为了清楚起见建议最好和源镜像的版本保持一致
![2019-06-02 10.36.15.png](https://upload-images.jianshu.io/upload_images/14871146-b17f6296dfb2e93f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
设置好构建规则之后点击立即构建按钮，下面就会开始构建了，看到构建状态为成功说明构建成功了
![2019-06-02 10.37.15.png](https://upload-images.jianshu.io/upload_images/14871146-d4135eceabd86eee.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
这时候点击基本信息，里面会显示镜像的地址，以及pull、push等一些基本操作。如果想把这个镜像提供给大家使用，选择仓库为**公共**就ok了。
