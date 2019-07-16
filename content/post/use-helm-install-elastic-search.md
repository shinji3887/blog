---
title: "使用helm charts安装elasticsearch集群"
date: 2019-04-28
excerpt: "使用heml charts方式安装一个高可用的es集群"
description: "使用heml charts方式安装一个高可用的es集群"
gitalk: true
image: "https://lupeier.cn-sh2.ufileos.com/adult-beach-boat-1121797.jpg"
author: L'
tags:
    - Kubernetes
    - helm
categories: [ Tech ]
---

>helm是kubernetes的包管理器，可以管理k8s的各种资源，并利用charts描述文件做非常复杂的编排功能，可以说是各种有状态发行软件的安装利器。现在各大厂商都出了自身产品的helm安装包，本文尝试使用helm进行es集群的搭建

前提条件：一个可用的kuberenetes集群（1.10以上版本）

### 安装helm

#### 方式一：使用官方脚本一键安装

```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh
$ chmod 700 get_helm.sh
$ ./get_helm.sh
```

#### 方式二：手动下载安装(这里安装目前最新的2.13.1版本)

```bash
#从官网下载最新版本的二进制安装包到本地：https://github.com/kubernetes/helm/releases
# 解压压缩包
tar -zxvf helm-2.13.1.tar.gz 
# 把 helm 指令放到bin目录下
mv helm-2.13.1/helm /usr/local/bin/helm
helm help # 验证
```

#### 安装Tiller

注意：先在 K8S 集群上每个节点安装 socat 软件(yum install -y socat )，不然会报错，如果当初使用的kubeadm安装的k8s，socat是自动安装好的

Tiller 是以 Deployment 方式部署在 Kubernetes 集群中的，只需使用以下指令便可简单的完成安装。

```bash
$ helm init
```

由于 Helm 默认会去 storage.googleapis.com 拉取镜像，很可能访问不了。可以直接去阿里云下载镜像，并打tag，镜像地址为`registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.13.1`

#### Tiller授权

k8s1.6版本以后默认使用RBAC授权模式，需要添加账号及角色才能使tiller正常访问api-server
创建 Kubernetes 的服务帐号(tiller)和绑定角色(这里赋予cluster-admin角色)

```bash
$ kubectl create serviceaccount --namespace kube-system tiller
$ kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
```

为 Tiller 这个deploy设置刚才创建的帐号

```bash
# 使用 kubectl patch 更新 API 对象
$ kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
deployment.extensions "tiller-deploy" patched
```

验证tiller是否安装成功

```bash
[root@MiWiFi-R1CM-srv _state]# kubectl get po -n kube-system|grep tiller
tiller-deploy-7cb87ddf7d-274ph            1/1     Running   1          2d1h
[root@MiWiFi-R1CM-srv _state]# helm version
Client: &version.Version{SemVer:"v2.13.1", GitCommit:"618447cbf203d147601b4b9bd7f8c37a5d39fbb4", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.13.1", GitCommit:"618447cbf203d147601b4b9bd7f8c37a5d39fbb4", GitTreeState:"clean"}
```

#### 更换仓库

默认的charts仓库在googleapi网站上，速度比较慢，这里我们更换为阿里云的charts仓库

```bash
# 先移除原先的仓库
helm repo remove stable
# 添加新的仓库地址
helm repo add stable https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
# 更新仓库
helm repo update
```

执行`helm search`看一下目前可用的charts，现在还不多，但很多大名鼎鼎的中间件，比如`rabbit mq`、`mysql`、`redis`、`mangodb`等等都针对helm charts出了高可用版本，要知道这些中间件的集群搭建可是非常麻烦的，使用helm可以非常方便的一键搭建集群，并且还可以一键删除（为啥不早五年出来。。。），以后有机会尝试一下，这次我们要试验的是elasticsearch集群的搭建。

### 搭建ES集群

es集群的具体介绍我这里就不展开了，简单说是一个基于lucene的高效的分布式全文搜索引擎，在搜索领域有着十分广泛的应用。之前弄好了helm环境，这边的操作就十分简单了，登陆es的官方helm charts仓库[https://github.com/elastic/helm-charts](https://github.com/elastic/helm-charts)
按照里面的说明，添加repo源

```bash
helm repo add elastic https://helm.elastic.co
```

安装

```bash
helm install --name elasticsearch elastic/elasticsearch --version 7.0.0-alpha1
```

执行`helm inspect`可查看各种helm的安装参数，每个参数都有详细说明，根据需要选择即可

由于es的helm安装的是statefulset（有状态副本），里面用到了pvc，所以还需要添加pv信息，否则pod是起不来的，因为我这边只有一个虚拟机，所以使用的是hostpath方式的pv，实际生产还是要用`Local Persistent Volume`或者挂载ceph、nfs这样的外置存储，pv文件如下

```bash
apiVersion: "v1"
kind: "PersistentVolume"
metadata:
  name: "elasticsearch-master-elasticsearch-master-0"
spec:
  capacity:
    storage: "30Gi"
  accessModes:
    - "ReadWriteOnce"
  persistentVolumeReclaimPolicy: Recycle
  hostPath:
    path: /root/esdata
```

这样就声明了一个name为`elasticsearch-master-elasticsearch-master-0`的pv，容量为30G，挂载在本地的`/root/esdata`目录下
执行

```bash
kubectl create -f local-pv.yaml
```

创建pv，完成后执行

```bash
[root@MiWiFi-R1CM-srv ~]# kubectl get pv
NAME                                          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                                                 STORAGECLASS   REASON   AGE
elasticsearch-master-elasticsearch-master-0   30Gi       RWO            Recycle          Bound       default/elasticsearch-master-elasticsearch-master-0                           4d1h
```

可以看到状态为`BOUND`，绑定成功，这里是因为name相同，自动绑定到helm创建的同名pvc上去了。
这时候再执行

```bash
[root@MiWiFi-R1CM-srv ~]# kubectl get po
NAME                             READY   STATUS    RESTARTS   AGE
elasticsearch-master-0           1/1     Running   0          89m
```

可以看到状态都ok了，单节点的es集群搭建完成
>这里面有一个问题，发现单节点的情况下，一旦往集群内写入数据后，再删除该pod，sts会重新分配一个pod起来，名字还是叫elasticsearch-master-0，挂载目录也不变，但是就无法加入集群，不知道是否和es集群脑裂有关系，有懂的高人请指点一下

#### kibana安装

kibana是es官配的ui图形界面，功能十分强大，这边安装也十分简单，直接执行

```bash
helm install --name kibana elastic/kibana --version 7.0.0-alpha1
```

即可，集群默认会找`http://elasticsearch-master:9200`的es集群，之前装es的时候已经设置过（通过k8s的service以及dns服务发现），修改一下kibana的service默认配置，改成nodeport模式，就可以通过浏览器直接访问了
![kibana.png](https://upload-images.jianshu.io/upload_images/14871146-030f321267b15f6a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
