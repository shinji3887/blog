---
title: "docker与kubernetes常用命令集合"
date: 2018-11-20
excerpt: "常用命令说明"
description: "常用命令说明"
gitalk: true
author: L'
tags:
    - Docker
    - Kubernetes
categories: [ Tips ]
---
> docker与kubernetes常用命令行集合，做个整理，妈妈再也不用担心我记不住命令了。只根据需要记录了主要的命令和参数，应该足够用了，全量的命令列表请参考官方文档

## docker命令

```bash
docker images
```

列出当前本地的所有镜像

```bash
docker ps
```

查看当前所有正在运行的容器进程

* -a：查看所有容器（包含不在运行的）

```bash
docker pull nginx:latest
```

拉取指定名称及版本的镜像,不指定tag名称时默认拉取latest

```bash
docker tag nginx:latest 22.196.66.62:5000/nginx:latest
```

标记本地镜像，将其归入某一仓库(比如内网私有仓库)，也会用来给墙外的一些镜像改名（ex:gcr.io）。

```bash
docker push 22.196.66.62:5000/nginx:latest
```

将镜像推送入dockerhub或者私有仓库

```bash
docker run -p 8080:80 --name mynginx -d nginx:latest
```

运行docker镜像

* -d: 后台运行容器，并返回容器ID；
* -i: 以交互模式运行容器，通常与 -t 同时使用；
* -p: 端口映射，格式为：主机(宿主)端口:容器端口
* -t: 为容器重新分配一个伪输入终端，通常与 -i 同时使用；
* --name="mynginx": 为容器指定一个名称；
* --cpuset="0-2" or --cpuset="0,1,2": 绑定容器到指定CPU运行；
* -m :设置容器使用内存最大值；
* --net="bridge": 指定容器的网络连接类型，支持 bridge/host/none/container: 四种类型,默认为桥接模式

```bash
docker exec -it  mynginx /bin/bash
```

以bash方式在容器mynginx中开启一个交互模式的终端

```bash
docker rm mynginx
```

删除容器，需要该容器此时是stop状态

```bash
docker rmi nginx:latest
```

删除镜像，需要此时没有该镜像创建的关联容器

```bash
docker logs --since="2016-07-01" --tail=10 mynginx
```

查看容器日志logs

* -f : 跟踪日志输出
* --since :显示某个开始时间的所有日志
* -t : 显示时间戳
* --tail :仅列出最新N条容器日志

```bash
docker build -t myapp:v0.1 .
```

构建镜像，需要在当前目录下有Dockerfile文件，.代表为当前路径

* --tag, -t: 镜像的名字及标签，通常 name:tag 或者 name 格式；可以在一次构建中为一个镜像设置多个标签
* -f :指定要使用的Dockerfile路径

```bash
docker save -o mynginx.tar nginx:latest
```

将镜像nginx:latest 生成mynginx.tar归档文件

```bash
docker load -i mynginx.tar
```

从mynginx.tar归档中载入镜像

```bash
docker cp /www/runoob 96f7f14e99ab:/www/
```

将宿主机/www/runoob目录拷贝到容器96f7f14e99ab的/www目录下

## kubectl命令

```bash
kubectl cluster-info
```

显示集群信息

k8s中一切皆为对象，对于资源对象操作的关键词分别有get、create、edit、delete等等（传说中的CRUD），下面简单列举一下

```bash
kubectl get pods -o wide
```

get关键词，获取默认namespace下的所有pods信息，pods可替换为k8中其他可以操作的对象，对象太多，这边捡主要的说说，下边其他的操作需要操作资源对象都是一样的

* all  列出全部对象
* clusters (valid only for federation apiservers)
* configmaps (aka 'cm') 
* deployments (aka 'deploy')
* ingresses (aka 'ing')
* jobs
* namespaces (aka 'ns')
* nodes (aka 'no')
* persistentvolumeclaims (aka 'pvc')
* persistentvolumes (aka 'pv')
* pods (aka 'po')
* replicasets (aka 'rs')
* replicationcontrollers (aka 'rc')
* roles
* secrets
* serviceaccounts (aka 'sa')
* services (aka 'svc')
* statefulsets

常用附加的参数有：

* -o yaml  以yaml格式输出
* -o json   以json格式输出
* -o wide  列表输出详细信息
* --name-space=kube-system 展示kube-system命名空间下的pods
* --all-namespaces  展示全部命名空间下的pods

```bash
kubectl run nginx --image=nginx --replicas=5 --port=80
```

这条命令执行完后会创建一个deployment，里面包含5个副本（pods），暴露容器的80端口，可以使用`kubectl get deploy`查看刚才创建的deployment

```bash
kubectl expose deploy nginx --port=8080 --target-port=80
```

为刚才创建的deployment对象创建service代理，并通过Service的8080端口转发至容器的80端口上。可代理的资源有pod（po），service（svc），replication controller（rc），deployment（deploy），replica set（rs）

* --type  有三种，ClusterIP, NodePort, or LoadBalancer. 默认是ClusterIP，这种模式的service只能给集群内的pod访问，若需要外部访问集群内pod，则需要设置为NodePort模式。

```bash
kubectl create -f docker-registry.yaml
```

从一个yaml文件中创建资源，资源类型由yaml文件定义，也可以后面加资源类型直接创建相关对象，比如

* role
* configmap
* quota
* namespace
* secret

```bash
kubectl edit deploy nginx
```

编辑nginx这个deployment的配置文件

```bash
kubectl delete deploy,svc nginx
```

删除标签为nginx的deployment及service对象

```bash
kubectl scale --replicas=3 deploy nginx
```

K8S当中的重头功能，对pods数量进行水平的扩容或者收缩，该命令将nginx这个deployment的副本数设置为3

```bash
kubectl patch deploy nginx -p '{"spec":{"unschedulable":true}}'
```

更新nginx这个deployment中的指定字段

```bash
kubectl set image deployment nginx nginx=nginx:1.9.1
```

将nginx这个deployment的镜像更新为nginx:1.9.1，这个操作会触发deployment的滚动更新，通常用于应用更新

```bash
kubectl describe pod podid
```

输出指定资源的详细描述，支持的资源包括但不限于（大小写不限）：pods (po)、services (svc)、 replicationcontrollers (rc)、nodes (no)、events (ev)、componentstatuses (cs)、 limitranges (limits)、persistentvolumes (pv)、persistentvolumeclaims (pvc)、 resourcequotas (quota)和secrets

```bash
kubectl logs -f --tail=20 nginx
```

仅输出pod nginx中最近的20条日志

```bash
kubectl exec -it 123456-7890 /bin/sh
```

进入pod 123456-7890并分配一个交互终端

```bash
kubectl apply -f FILENAME
```

通过文件名或控制台输入，对资源进行配置。apply命令的使用方式同replace相同，不同的是，apply不会删除原有resource，然后创建新的。apply直接在原有resource的基础上进行更新。同时kubectl apply还会resource中添加一条注释，标记当前的apply。类似于git操作。
