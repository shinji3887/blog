---
title: "CKA考试经验总结"
date: 2019-12-07
excerpt: "CKA考试经验总结"
description: "CKA考试经验总结"
gitalk: true
image: "https://lupeier.cn-sh2.ufileos.com/business-college-composition-desk-419635.jpg"
author: 陆培尔
tags:
    - Kubernetes
categories: [ Tips ]
---

> CKA考试相关说明及经验总结

### 什么是CKA考试？

CKA全称是Certified Kubernetes Administrator，即Kubernetes认证管理员，由CNCF官方组织考试并颁发证书，应该来说还是比较权威的,还有一个是CKAD考试，对于报考人员的要求更高，主要是基于kubernetes做开发的（比如operator之类），这边我们主要说说CKA考试。
![cka.png](https://lupeier.cn-sh2.ufileos.com/cka.png)

### CKA证书的含金量如何？

前两年K8没现在这么火，加上考试费不便宜，考试又很麻烦（需要连国外服务器），这个证书拿的人不多，这两年K8大火，有越来越多的各种xx云和培训机构都在做这个培训，应该说拿证书的难度是大大降低了（培训费很贵）。当然一张证书无法体现一个人的全部能力（其实所有的各种认证证书都是一样的问题），但是有CKA至少说明了你对kubernetes的各种组件、原理、常规操作、简单排障是没有问题了，我觉得是相当于一个入门砖吧，对于工作不久并且有志于从事云原生相关工作的人，还是有积极意义的。而对于企业来说，如果想招聘K8集群管理员，那看这个证书无疑是最方便的，省去了很多能力考察的精力。

### 考试难度

考试整体难度不算很高，全部是实操类题目，共24题，没有选择题、判断题，考察的是你对于k8的实际应用和操作能力，并不会涉及非常深的底层原理、架构设计思想等。但是题目涉及的范围比较广，相对时间会比较紧张，所以要通过这个考试需要你对于k8的整体功能有一个非常全面的认识。

### 考试报名

有个好消息是，今年linux基金会的开源软件大学终于落地中国，这样中国的考生就可以方便的在线下考点考试了，从而避免啃爹的网络问题和各种报名、考试环境、摄像头的准备，考官也是中国人，交流非常方便。个人建议如果不是住特别偏远的交通不便，参加线下考试是最佳选择。考试费用是2165元。

线下考点列表：[https://training.linuxfoundation.cn/faq#13](https://training.linuxfoundation.cn/faq#13)

报名网址：[https://training.linuxfoundation.cn/certificate/details/1](https://training.linuxfoundation.cn/certificate/details/1)

考纲及考试小贴士：[https://training.linuxfoundation.cn/faq#15](https://training.linuxfoundation.cn/faq#15)

注意考纲是全英文的，一般以最新的release的k8版本为基础，不过核心的组件和功能最近的版本中变化不大。

### 考前复习

现在有各种培训机构和云计算公司会针对CKA有专门的培训课程，价格很贵（考试+培训一般都要1万出头），时间其实也就2到3天左右。个人认为除非是你对于k8毫无概念，或者是公司报销费用，否则没有必要去参加这些培训，根据官方考纲复习+看官方文档足够你通过考试了，复习的时候搭建一个简单的k8集群供进行实操，minikube，docker自带的k8，或者像katacoda这样的线上kubernetes playground都是很好的选择。考试的时候是可以查看kubernetes的官方文档网站的，所以对于很多命令、操作不需要死记硬背，只需要知道大致的位置就可以。

目前的考试政策，如果你报名考试没通过（考到75分通过），还会有一次retake的机会，还是比较人性化的，所以我相信只要认真复习通过的问题不会很大。证书有效期为2年，续不续看你们公司的实际需求（CNCF也要赚钱啊），我觉得除非K8架构发生了非常大的改动，或者公司对于资格认定这块有要求，否则也没必要特意去续，能考出来已经证明了你的能力了。

### 真题解析

这里要感谢简书作者桶装酱油王，下面的题目主要出自他考试过后的整理，原文在这里[https://www.jianshu.com/p/135c1d618a79](https://www.jianshu.com/p/135c1d618a79)

1.列出环境内所有的pv 并以 name字段排序（使用kubectl自带排序功能）

```bash
kubectl get pv --sort-by=.metadata.name
```

考点：kubectl命令熟悉程度

2.列出指定pod的日志中状态为Error的行，并记录在指定的文件上

```bash
kubectl logs <podname> | grep bash > /opt/KUCC000xxx/KUCC000xxx.txt
```

考点：Monitor, Log, and Debug

3.列出k8s可用的节点，不包含不可调度的 和 NoReachable的节点，并把数字写入到文件里

```bash
#笨方法，人工数
kubectl get nodes

#CheatSheet方法，应该还能优化JSONPATH
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' \
 && kubectl get nodes -o jsonpath="$JSONPATH" | grep "Ready=True"
```

考点：kubectl命令熟悉程度(cheatsheet非常重要，最好能熟练掌握)

参考：[kubectl cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

4.创建一个pod名称为nginx，并将其调度到节点为 disk=stat上

```bash
#我的操作,实际上从文档复制更快
kubectl run nginx --image=nginx --restart=Never --dry-run > 4.yaml
#增加对应参数
vi 4.yaml
kubectl apply -f 4.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  nodeSelector:
    disktype: ssd
```

考点：pod的调度。

参考：[assign-pod-node](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/)

5.提供一个pod的yaml，要求添加Init Container，Init Container的作用是创建一个空文件，pod的Containers判断文件是否存在，不存在则退出

```bash
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: apline
    image: nginx
    command: ['sh', '-c', 'if [ ! -e "/opt/myfile" ];then exit; fi;']
###增加init Container####
initContainers:
 - name: init
    image: busybox
    command: ['sh', '-c', 'touch /目录/work;']
```

考点：init Container。一开始审题不仔细，以为要用到livenessProbes

参考：[init-containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)

6.指定在命名空间内创建一个pod名称为test，内含四个指定的镜像nginx、redis、memcached、busybox

```bash
kubectl run test --image=nginx --image=redis --image=memcached --image=buxybox --restart=Never -n <namespace>
```

考点：kubectl命令熟悉程度、多个容器的pod的创建

参考：[kubectl cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

7.创建一个pod名称为test，镜像为nginx，Volume名称cache-volume为挂在在/data目录下，且Volume是non-Persistent的

```bash
apiVersion: v1
kind: Pod
metadata:
  name: test
spec:
  containers:
  - image: nginx
    name: test-container
    volumeMounts:
    - mountPath: /cache
      name: cache-volume
  volumes:
  - name: cache-volume
    emptyDir: {}
```

考点：Volume、emptdir

参考：[Volumes](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)

8.列出Service名为test下的pod 并找出使用CPU使用率最高的一个，将pod名称写入文件中

```bash
#使用-o wide 获取service test的SELECTOR
kubectl get svc test -o wide
##获取结果我就随便造了
NAME              TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE       SELECTOR
test   ClusterIP   None         <none>        3306/TCP   50d       app=wordpress,tier=mysql

#获取对应SELECTOR的pod使用率，找到最大那个写入文件中
kubectl top pod -l 'app=wordpress,tier=mysql'
```

考点：获取service selector，kubectl top监控pod资源

参考：[Tools for Monitoring Resources](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/)

9.创建一个Pod名称为nginx-app，镜像为nginx，并根据pod创建名为nginx-app的Service，type为NodePort

```bash
kubectl run nginx-app --image=nginx --restart=Never --port=80
kubectl create svc nodeport nginx-app --tcp=80:80 --dry-run -o yaml > 9.yaml
#修改yaml，保证selector name=nginx-app
vi 9.yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: nginx-app
  name: nginx-app
spec:
  ports:
  - name: 80-80
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
#注意要和pod对应  
    name: nginx-app
  type: NodePort
```

考点：Service

参考：[publishing-services-service-types](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types)

10.创建一个nginx的Workload，保证其在每个节点上运行，注意不要覆盖节点原有的Tolerations

```bash
这道题直接复制文档的yaml太长了，由于damonSet的格式和Deployment格式差不多，我用旁门左道的方法 先创建Deploy，再修改，这样速度会快一点

#先创建一个deployment的yaml模板
kubectl run nginx --image=nginx --dry-run -o yaml > 10.yaml
#将yaml改成DaemonSet
vi 10.yaml
```

```bash
#修改apiVersion和kind
#apiVersion: extensions/v1beta1
#kind: Deployment
apiVersion:apps/v1
kind: DaemonSet
metadata:
  creationTimestamp: null
  labels:
    run: nginx
  name: nginx
spec:
#去掉replicas
# replicas: 1
  selector:
    matchLabels:
      run: nginx
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        run: nginx
    spec:
      containers:
      - image: nginx
        name: nginx
        resources: {}
status: {}
```

考点：DaemonSet

参考：[DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)

11.将deployment为nginx-app的副本数从1变成4。

```bash
#方法1
kubectl scale  --replicas=4 deployment nginx-app
#方法2，使用edit命令将replicas改成4
kubectl edit deploy nginx-app
```

考点：deployment的Scaling，搜索Scaling

参考：[Scaling the application by increasing the replica count](https://kubernetes.io/docs/tasks/run-application/run-stateless-application-deployment/#scaling-the-application-by-increasing-the-replica-count)

12.创建nginx-app的deployment ，使用镜像为nginx:1.11.0-alpine ,修改镜像为1.11.3-alpine，并记录升级，再使用回滚，将镜像回滚至nginx:1.11.0-alpine

```bash
kubectl run nginx-app --image=nginx:1.11.0-alpine
kubectl set image deployment nginx-app --image=nginx:1.11.3-alpine
kubectl rollout undo deployment nginx-app
kubectl rollout status -w deployment nginx-app
```

考点：资源的更新

参考：[Kubectl Cheat Sheet:Updating Resources](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#updating-resources)

13.根据已有的一个nginx的pod、创建名为nginx的svc、并使用nslookup查找出service dns记录，pod的dns记录并分别写入到指定的文件中

```bash
#创建一个服务
kubectl create svc nodeport nginx --tcp=80:80
#创建一个指定版本的busybox，用于执行nslookup
kubectl create -f https://k8s.io/examples/admin/dns/busybox.yaml
#将svc的dns记录写入文件中
kubectl exec -ti busybox -- nslookup nginx > 指定文件
#获取pod的ip地址
kubectl get pod nginx -o yaml
#将获取的pod ip地址使用nslookup查找dns记录
kubectl exec -ti busybox -- nslookup <Pod ip>
```

考点：网络相关，DNS解析

参考：[Debugging DNS Resolution](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/)

14.创建Secret 名为mysecret，内含有password字段，值为bob，然后 在pod1里 使用ENV进行调用，Pod2里使用Volume挂载在/data 下

```bash
#将密码值使用base64加密,记录在Notepad里
echo -n 'bob' | base64
```

secret.yaml

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
data:
  password: Ym9i
```

pod1.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod1
spec:
  containers:
  - name: mypod
    image: nginx
    volumeMounts:
    - name: mysecret
      mountPath: "/data"
      readOnly: true
  volumes:
  - name: mysecret
    secret:
      secretName: mysecret
```

pod2.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod2
spec:
  containers:
  - name: mycontainer
    image: redis
    env:
      - name: SECRET_PASSWORD
        valueFrom:
          secretKeyRef:
            name: mysecret
            key: password
```

考点: Secret

参考：[Secret](https://kubernetes.io/docs/concepts/configuration/secret/)

15.使node1节点不可调度，并重新分配该节点上的pod

```bash
#直接drain会出错，需要添加--ignore-daemonsets --delete-local-data参数
kubectl drain node node1  --ignore-daemonsets --delete-local-data
```

考点：节点调度、维护

参考：[Safely Drain a Node while Respecting Application SLOs](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)

16.使用etcd 备份功能备份etcd（提供enpoints，ca、cert、key）

```bash
ETCDCTL_API=3 etcdctl --endpoints https://127.0.0.1:2379 \
--cacert=ca.pem --cert=cert.pem --key=key.pem \
snapshot save snapshotdb
```

考点：etcd的集群的备份与恢复

参考：[backing up an etcd cluster](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster)

17.给出一个失联节点的集群，排查节点故障，要保证改动是永久的。

```bash
#查看集群状态
kubectl get nodes
#查看故障节点信息
kubectl describe node node1

#Message显示kubelet无法访问（记不清了）
#进入故障节点
ssh node1

#查看节点中的kubelet进程
ps -aux | grep kubelete
#没找到kubelet进程，查看kubelet服务状态
systemctl status kubelet.service 
#kubelet服务没启动，启动服务并观察
systemctl start kubelet.service 
#启动正常，enable服务
systemctl enable kubelet.service 

#回到考试节点并查看状态
exit

kubectl get nodes #正常
```

考点：故障排查

参考：[Troubleshoot Clusters](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/)

18.给出一个集群，排查出集群的故障

这道题没空做完。kubectl get node显示connection refuse，估计是apiserver的故障。

考点：故障排查

参考：[Troubleshoot Clusters](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/)

19.给出一个节点，完善kubelet配置文件，要求使用systemd配置kubelet

这道题没空做完，

考点我知道，doc没找到··在哪 逃~ε=ε=ε=┏(゜ロ゜;)┛

20.给出一个集群，将节点node1添加到集群中，并使用TLS bootstrapping

这道题没空做完，花费时间比较长，可惜了。

考点：TLS Bootstrapping

参考：[TLS Bootstrapping](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/)

21.创建一个pv，类型是hostPath，位于/data中，大小1G，模式ReadOnlyMany

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv
spec:
  capacity:
    storage: 1Gi  
  accessModes:
    - ReadOnlyMany
  hostPath:
    path: /data
```

考点：创建PV

参考：[persistent volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
