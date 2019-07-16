---
title: "使用kubeadm快速搭建单机kubernetes 1.13集群"
date: 2019-01-12
excerpt: "kubernetes集群创建实战"
description: "kubernetes集群创建实战"
gitalk: true
image: "https://lupeier.cn-sh2.ufileos.com/architecture-bay-boat-326410.jpg"
author: L'
tags:
    - Kubernetes
categories: [ Tech ]
---

kubeadm可谓是快速搭建k8集群的神器，想当年有多少人倒在k8集群搭建的这道坎上，我自己去年也是通过二进制方式手动搭了一个k8 1.9的集群，安装大量的组件，各种证书配置，各种依赖。。。那酸爽真的不忍回忆，而且搭出来的集群还是有一些问题，证书一直有问题，dashboard也只能用老版本的。现在有了kubeadm，它帮助我们做了大量原来需要手动安装、配置、生成证书的事情，一杯咖啡的功夫集群就能搭建好了。

### 和minikube的区别

minikube基本上你可以认为是一个实验室工具，只能单机部署，里面整合了k8最主要的组件，无法搭建集群，且由于程序做死无法安装各种扩展插件（比如网络插件、dns插件、ingress插件等等），主要作用是给你了解k8用的。而kudeadm搭建出来是一个真正的k8集群，可用于生产环境（HA需要自己做），和二进制搭建出来的集群几乎没有区别。

### 环境要求

- 本次安装使用virtualbox虚拟机（macOs），分配2C2G内存
- 操作系统为centos 7.6，下述安装步骤均基于centos，注意centos版本最好是最新的，否则会有各种各样奇怪的坑（之前基于7.0被坑了不少）
- 虚拟机需要保持和宿主机的双向互通且可以访问公网，具体设置这边不展开，网上教程很多
- kubernetes安装的基线版本为1.13.1

### 设置yum源

首先去`/etc/yum.repos.d/`目录，删除该目录下所有repo文件（先做好备份）

下载centos基础yum源配置（这里用的是阿里云的镜像）

```bash
curl -o CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
```

下载docker的yum源配置

```bash
curl -o docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo
```

配置kubernetes的yum源

```bash
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
        http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

执行下列命令刷新yum源缓存

```bash
# yum clean all  
# yum makecache  
# yum repolist
```

得到这面这个列表，说明源配置正确

```bash
[root@MiWiFi-R1CM-srv yum.repos.d]# yum repolist
已加载插件：fastestmirror
Loading mirror speeds from cached hostfile
源标识                                                                               源名称                                                                                    状态
base/7/x86_64                                                                        CentOS-7 - Base - 163.com                                                                 10,019
docker-ce-stable/x86_64                                                              Docker CE Stable - x86_64                                                                     28
extras/7/x86_64                                                                      CentOS-7 - Extras - 163.com                                                                  321
kubernetes                                                                           Kubernetes                                                                                   299
updates/7/x86_64                                                                     CentOS-7 - Updates - 163.com                                                                 628
repolist: 11,295
```

### 安装docker

```bash
yum install -y docker-ce
```

我这边直接装的最新稳定版18.09，如果对于版本有要求，可以先执行

```bash
[root@MiWiFi-R1CM-srv yum.repos.d]# yum list docker-ce --showduplicates | sort -r
已加载插件：fastestmirror
已安装的软件包
可安装的软件包
Loading mirror speeds from cached hostfile
docker-ce.x86_64            3:18.09.1-3.el7                    docker-ce-stable 
docker-ce.x86_64            3:18.09.1-3.el7                    @docker-ce-stable
docker-ce.x86_64            3:18.09.0-3.el7                    docker-ce-stable 
docker-ce.x86_64            18.06.1.ce-3.el7                   docker-ce-stable 
docker-ce.x86_64            18.06.0.ce-3.el7                   docker-ce-stable 
docker-ce.x86_64            18.03.1.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            18.03.0.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.12.1.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.12.0.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.09.1.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.09.0.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.06.2.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.06.1.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.06.0.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.03.3.ce-1.el7                   docker-ce-stable 
docker-ce.x86_64            17.03.2.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.03.1.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.03.0.ce-1.el7.centos            docker-ce-stable 
```

列出所有版本，再执行

```bash
yum install -y docker-ce-<VERSION STRING>
```

安装指定版本
安装完成后，执行

```bash
[root@MiWiFi-R1CM-srv yum.repos.d]# systemctl start docker
[root@MiWiFi-R1CM-srv yum.repos.d]# systemctl enable docker
[root@MiWiFi-R1CM-srv yum.repos.d]# docker info
Containers: 24
 Running: 21
 Paused: 0
 Stopped: 3
Images: 11
Server Version: 18.09.1
Storage Driver: overlay2
 Backing Filesystem: xfs
 Supports d_type: true
 Native Overlay Diff: true
Logging Driver: json-file
Cgroup Driver: cgroupfs
Plugins:
 Volume: local
 Network: bridge host macvlan null overlay
 Log: awslogs fluentd gcplogs gelf journald json-file local logentries splunk syslog
Swarm: inactive
Runtimes: runc
Default Runtime: runc
Init Binary: docker-init
containerd version: 9754871865f7fe2f4e74d43e2fc7ccd237edcbce
runc version: 96ec2177ae841256168fcf76954f7177af9446eb
init version: fec3683
Security Options:
 seccomp
  Profile: default
Kernel Version: 3.10.0-957.1.3.el7.x86_64
Operating System: CentOS Linux 7 (Core)
OSType: linux
Architecture: x86_64
CPUs: 2
Total Memory: 1.795GiB
Name: MiWiFi-R1CM-srv
ID: DSTM:KH2I:Y4UV:SUPX:WIP4:ZV4C:WTNO:VMZR:4OKK:HM3G:3YFS:FXMY
Docker Root Dir: /var/lib/docker
Debug Mode (client): false
Debug Mode (server): false
Registry: https://index.docker.io/v1/
Labels:
Experimental: false
Insecure Registries:
 127.0.0.0/8
Live Restore Enabled: false
Product License: Community Engine

WARNING: bridge-nf-call-ip6tables is disabled
```

说明安装正确

### kubeadm安装k8s

可能大家对于kubeadm安装出来的kubernetes集群的稳定性还有疑虑，这边援引官方的说明文档
![kubeadm.png](kubeadm.png)
可以看到核心功能都已经GA了，可以放心用，大家比较关心的HA还是在alpha阶段，还得再等等，目前来说kubeadm搭建出来的k8集群master还是单节点的，要做高可用还需要自己手动搭建etcd集群。

由于之前已经设置好了kubernetes的yum源，我们只要执行

```bash
yum install -y kubeadm
```

系统就会帮我们自动安装最新版的kubeadm了（我安装的时候是1.13.1），一共会安装kubelet、kubeadm、kubectl、kubernetes-cni这四个程序。

- kubeadm：k8集群的一键部署工具，通过把k8的各类核心组件和插件以pod的方式部署来简化安装过程
- kubelet：运行在每个节点上的node agent，k8集群通过kubelet真正的去操作每个节点上的容器，由于需要直接操作宿主机的各类资源，所以没有放在pod里面，还是通过服务的形式装在系统里面
- kubectl：kubernetes的命令行工具，通过连接api-server完成对于k8的各类操作
- kubernetes-cni：k8的虚拟网络设备，通过在宿主机上虚拟一个cni0网桥，来完成pod之间的网络通讯，作用和docker0类似。

安装完后，执行

```bash
kubeadmin init --pod-network-cidr=10.244.0.0/16
```

开始master节点的初始化工作，注意这边的`--pod-network-cidr=10.244.0.0/16`，是k8的网络插件所需要用到的配置信息，用来给node分配子网段，我这边用到的网络插件是flannel，就是这么配，其他的插件也有相应的配法，官网上都有详细的说明，具体参考[这个网页](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)。

初始化的时候kubeadm会做一系列的校验，以检测你的服务器是否符合kubernetes的安装条件，检测结果分为`[WARNING]`和`[ERROR]`两种，类似如下的信息（一般第一次执行都会失败。。）

```bash
[root@MiWiFi-R1CM-srv ~]# kubeadm init
I0112 00:30:18.868179   13025 version.go:94] could not fetch a Kubernetes version from the internet: unable to get URL "https://dl.k8s.io/release/stable-1.txt": Get https://storage.googleapis.com/kubernetes-release/release/stable-1.txt: net/http: request canceled (Client.Timeout exceeded while awaiting headers)
I0112 00:30:18.868645   13025 version.go:95] falling back to the local client version: v1.13.1
[init] Using Kubernetes version: v1.13.1
[preflight] Running pre-flight checks
	[WARNING SystemVerification]: this Docker version is not on the list of validated versions: 18.09.1. Latest validated version: 18.06
	[WARNING Hostname]: hostname "miwifi-r1cm-srv" could not be reached
	[WARNING Hostname]: hostname "miwifi-r1cm-srv": lookup miwifi-r1cm-srv on 192.168.31.1:53: no such host
	[WARNING Service-Kubelet]: kubelet service is not enabled, please run 'systemctl enable kubelet.service'
error execution phase preflight: [preflight] Some fatal errors occurred:
	[ERROR FileContent--proc-sys-net-bridge-bridge-nf-call-iptables]: /proc/sys/net/bridge/bridge-nf-call-iptables contents are not set to 1
	[ERROR Swap]: running with swap on is not supported. Please disable swap
[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
```

`[WARNING]`的有比如docker服务没设置成自动启动啦，docker版本不符合兼容性要求啦，hostname设置不规范之类，这些一般问题不大，不影响安装，当然尽量你按照它提示的要求能改掉是最好。

`[ERROR]`的话就要重视，虽然可以通过`--ignore-preflight-errors`忽略错误强制安装，但为了不出各种奇怪的毛病，所以强烈建议error的问题一定要解决了再继续执行下去。比如系统资源不满足要求（master节点要求至少2C2G），swap没关等等（会影响kubelet的启动），swap的话可以通过设置`swapoff -a`来进行关闭，另外注意`/proc/sys/net/bridge/bridge-nf-call-iptables`这个参数，需要设置为1，否则kubeadm预检也会通不过，貌似网络插件会用到这个内核参数。

一顿修改后，预检全部通过，kubeadm就开始安装了，经过一阵等待，不出意外的话安装会失败-_-，原因自然是众所周知的原因，gcr.io无法访问（谷歌自己的容器镜像仓库），但是错误信息很有价值，我们来看一下

```bash
[root@MiWiFi-R1CM-srv ~]# kubeadm init
I0112 00:39:39.813145   13591 version.go:94] could not fetch a Kubernetes version from the internet: unable to get URL "https://dl.k8s.io/release/stable-1.txt": Get https://storage.googleapis.com/kubernetes-release/release/stable-1.txt: net/http: request canceled (Client.Timeout exceeded while awaiting headers)
I0112 00:39:39.813263   13591 version.go:95] falling back to the local client version: v1.13.1
[init] Using Kubernetes version: v1.13.1
[preflight] Running pre-flight checks
	[WARNING SystemVerification]: this Docker version is not on the list of validated versions: 18.09.1. Latest validated version: 18.06
	[WARNING Hostname]: hostname "miwifi-r1cm-srv" could not be reached
	[WARNING Hostname]: hostname "miwifi-r1cm-srv": lookup miwifi-r1cm-srv on 192.168.31.1:53: no such host
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
error execution phase preflight: [preflight] Some fatal errors occurred:
	[ERROR ImagePull]: failed to pull image k8s.gcr.io/kube-apiserver:v1.13.1: output: Error response from daemon: Get https://k8s.gcr.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
, error: exit status 1
	[ERROR ImagePull]: failed to pull image k8s.gcr.io/kube-controller-manager:v1.13.1: output: Error response from daemon: Get https://k8s.gcr.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
, error: exit status 1
	[ERROR ImagePull]: failed to pull image k8s.gcr.io/kube-scheduler:v1.13.1: output: Error response from daemon: Get https://k8s.gcr.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
, error: exit status 1
	[ERROR ImagePull]: failed to pull image k8s.gcr.io/kube-proxy:v1.13.1: output: Error response from daemon: Get https://k8s.gcr.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
, error: exit status 1
	[ERROR ImagePull]: failed to pull image k8s.gcr.io/pause:3.1: output: Error response from daemon: Get https://k8s.gcr.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
, error: exit status 1
	[ERROR ImagePull]: failed to pull image k8s.gcr.io/etcd:3.2.24: output: Error response from daemon: Get https://k8s.gcr.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
, error: exit status 1
	[ERROR ImagePull]: failed to pull image k8s.gcr.io/coredns:1.2.6: output: Error response from daemon: Get https://k8s.gcr.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
, error: exit status 1
```

这里面明确列出了安装需要用到的镜像名称和tag，那么我们只需要提前把这些镜像pull下来，再安装就ok了。你也可以通过`kubeadm config images pull`预先下载好镜像，再执行`kubeadm init`。

知道名字就好办了，这点小问题难不倒我们。目前国内的各大云计算厂商都提供了kubernetes的镜像服务，比如阿里云，我可以通过

```bash
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.2.24
```

来拉取etcd的镜像，再通过

```bash
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.2.24 k8s.gcr.io/etcd:3.2.24
```

来改成kudeadm安装时候需要的镜像名称，其他的镜像也是如法炮制。注意所需的镜像和版本号，可能和我这边列出的不一样，kubernetes项目更新很快，具体还是要以你当时执行的时候列出的出错信息里面的为准，但是处理方式都是一样的。（其实不改名，kubeadm还可以通过yaml文件申明安装所需的镜像名称，这部分就留给你自己去研究啦）。

注：由于阿里云用别人的仓库，也没法保障所有的镜像都有，所以这次再提供一种可以方便的自制gcr.io上面镜像的方法[]

镜像都搞定之后，再次执行

```bash
[root@MiWiFi-R1CM-srv ~]# kubeadm init --pod-network-cidr=10.244.0.0/16
I0112 01:35:38.758110    4544 version.go:94] could not fetch a Kubernetes version from the internet: unable to get URL "https://dl.k8s.io/release/stable-1.txt": Get https://dl.k8s.io/release/stable-1.txt: x509: certificate has expired or is not yet valid
I0112 01:35:38.758428    4544 version.go:95] falling back to the local client version: v1.13.1
[init] Using Kubernetes version: v1.13.1
[preflight] Running pre-flight checks
	[WARNING SystemVerification]: this Docker version is not on the list of validated versions: 18.09.1. Latest validated version: 18.06
	[WARNING Hostname]: hostname "miwifi-r1cm-srv" could not be reached
	[WARNING Hostname]: hostname "miwifi-r1cm-srv": lookup miwifi-r1cm-srv on 192.168.31.1:53: no such host
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Activating the kubelet service
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [miwifi-r1cm-srv localhost] and IPs [192.168.31.175 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [miwifi-r1cm-srv localhost] and IPs [192.168.31.175 127.0.0.1 ::1]
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [miwifi-r1cm-srv kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 192.168.31.175]
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[apiclient] All control plane components are healthy after 29.508735 seconds
[uploadconfig] storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.13" in namespace kube-system with the configuration for the kubelets in the cluster
[patchnode] Uploading the CRI Socket information "/var/run/dockershim.sock" to the Node API object "miwifi-r1cm-srv" as an annotation
[mark-control-plane] Marking the node miwifi-r1cm-srv as control-plane by adding the label "node-role.kubernetes.io/master=''"
[mark-control-plane] Marking the node miwifi-r1cm-srv as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: wde86i.tmjaf7d18v26zg03
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstraptoken] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstraptoken] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstraptoken] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstraptoken] creating the "cluster-info" ConfigMap in the "kube-public" namespace
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join 192.168.31.175:6443 --token wde86i.tmjaf7d18v26zg03 --discovery-token-ca-cert-hash sha256:b05fa53d8f8c10fa4159ca499eb91cf11fbb9b27801b7ea9eb7d5066d86ae366
```

可以看到终于安装成功了，kudeadm帮你做了大量的工作，包括kubelet配置、各类证书配置、kubeconfig配置、插件安装等等（这些东西自己搞不知道要搞多久，反正估计用过kubeadm没人会再愿意手工安装了）。注意最后一行，kubeadm提示你，其他节点需要加入集群的话，只需要执行这条命令就行了，里面包含了加入集群所需要的token。同时kubeadm还提醒你，要完成全部安装，还需要安装一个网络插件`kubectl apply -f [podnetwork].yaml`，并且连如何安装网络插件的网址都提供给你了（很贴心啊有木有）。同时也提示你，需要执行

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

把相关配置信息拷贝入.kube的目录，这个是用来配置kubectl和api-server之间的认证，其他node节点的话需要将此配置信息拷贝入node节点的对应目录。此时我们执行一下

```bash
[root@MiWiFi-R1CM-srv yum.repos.d]# kubectl get node
NAME              STATUS   ROLES    AGE     VERSION
miwifi-r1cm-srv   NotReady    master   4h56m   v1.13.1
```

显示目前节点是`notready`状态，先不要急，我们先来看一下kudeadm帮我们安装了哪些东西：

#### 核心组件

前面介绍过，kudeadm的思路，是通过把k8主要的组件容器化，来简化安装过程。这时候你可能就有一个疑问，这时候k8集群还没起来，如何来部署pod？难道直接执行docker run？当然是没有那么low，其实在kubelet的运行规则中，有一种特殊的启动方法叫做“静态pod”（static pod），只要把pod定义的yaml文件放在指定目录下，当这个节点的kubelet启动时，就会自动启动yaml文件中定义的pod。从这个机制你也可以发现，为什么叫做static pod，因为这些pod是不能调度的，只能在这个节点上启动，并且pod的ip地址直接就是宿主机的地址。在k8中，放这些预先定义yaml文件的位置是`/etc/kubernetes/manifests`，我们来看一下

```bash
[root@MiWiFi-R1CM-srv manifests]# ls -l
总用量 16
-rw-------. 1 root root 1999 1月  12 01:35 etcd.yaml
-rw-------. 1 root root 2674 1月  12 01:35 kube-apiserver.yaml
-rw-------. 1 root root 2547 1月  12 01:35 kube-controller-manager.yaml
-rw-------. 1 root root 1051 1月  12 01:35 kube-scheduler.yaml
```

这四个就是k8的核心组件了，以静态pod的方式运行在当前节点上

- etcd：k8s的数据库，所有的集群配置信息、密钥、证书等等都是放在这个里面，所以生产上面一般都会做集群，挂了不是开玩笑的
- kube-apiserver: k8的restful api入口，所有其他的组件都是通过api-server来操作kubernetes的各类资源，可以说是k8最底层的组件
- kube-controller-manager: 负责管理容器pod的生命周期
- kube-scheduler: 负责pod在集群中的调度
![image](kubecomponent.png)

具体操作来说，在之前的文章中已经介绍过，docker架构调整后，已经拆分出containerd组件，所以现在是kubelet直接通过cri-containerd来调用containerd进行容器的创建（不走docker daemon了），从进程信息里面可以看出

```bash
[root@MiWiFi-R1CM-srv manifests]# ps -ef|grep containerd
root      3075     1  0 00:29 ?        00:00:55 /usr/bin/containerd
root      4740  3075  0 01:35 ?        00:00:01 containerd-shim -namespace moby -workdir /var/lib/containerd/io.containerd.runtime.v1.linux/moby/ec93247aeb737218908557f825344b33dd58f0c098bd750c71da1bc0ec9a49b0 -address /run/containerd/containerd.sock -containerd-binary /usr/bin/containerd -runtime-root /var/run/docker/runtime-runc
root      4754  3075  0 01:35 ?        00:00:01 containerd-shim -namespace moby -workdir /var/lib/containerd/io.containerd.runtime.v1.linux/moby/f738d56f65b9191a63243a1b239bac9c3924b5a2c7c98e725414c247fcffbb8f -address /run/containerd/containerd.sock -containerd-binary /usr/bin/containerd -runtime-root /var/run/docker/runtime-runc
root      4757  3
```

其中`3075`这个进程就是由docker服务启动时带起来的containerd daemon，`4740`和`4754`是由`containerd`进程创建的`cotainerd-shim`子进程，用来真正的管理容器进程。多说一句，之前的docker版本这几个进程名字分别叫`docker-containerd`，`docker-cotainerd-shim`，`docker-runc`,现在的进程名字里面已经完全看不到docker的影子了，去docker化越来越明显了。

#### 插件addon

- CoreDNS: cncf项目，主要是用来做服务发现，目前已经取代kube-dns作为k8默认的服务发现组件
- kube-proxy: 基于iptables来做的负载均衡，service会用到，这个性能不咋地，知道一下就好

我们执行一下

```bash
[root@MiWiFi-R1CM-srv ~]# kubectl get pods -n kube-system
NAME                                      READY   STATUS    RESTARTS   AGE
coredns-86c58d9df4-gbgzx                  0/1     Pending   0          5m28s
coredns-86c58d9df4-kzljk                  0/1     Pending   0          5m28s
etcd-miwifi-r1cm-srv                      1/1     Running   0          4m40s
kube-apiserver-miwifi-r1cm-srv            1/1     Running   0          4m52s
kube-controller-manager-miwifi-r1cm-srv   1/1     Running   0          5m3s
kube-proxy-9c8cs                          1/1     Running   0          5m28s
kube-scheduler-miwifi-r1cm-srv            1/1     Running   0          4m45s
```

可以看到kubeadm帮我们安装的，就是我上面提到的那些组件，并且都是以pod的形式安装。同时你也应该注意到了，coredns的两个pod都是`pending`状态，这是因为网络插件还没有安装。我们根据前面提到的官方页面的说明安装网络插件，这边我用到的是flannel，安装方式也很简单，标准的k8式的安装

```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml
```

安装完之后我们再看一下pod的状态

```bash
[root@MiWiFi-R1CM-srv ~]# kubectl get pods -n kube-system
NAME                                      READY   STATUS    RESTARTS   AGE
coredns-86c58d9df4-gbgzx                  1/1     Running   0          11m
coredns-86c58d9df4-kzljk                  1/1     Running   0          11m
etcd-miwifi-r1cm-srv                      1/1     Running   0          11m
kube-apiserver-miwifi-r1cm-srv            1/1     Running   0          11m
kube-controller-manager-miwifi-r1cm-srv   1/1     Running   0          11m
kube-flannel-ds-amd64-kwx59               1/1     Running   0          57s
kube-proxy-9c8cs                          1/1     Running   0          11m
kube-scheduler-miwifi-r1cm-srv            1/1     Running   0          11m
```

可以看到coredns的两个pod都已经启动，同时还多了一个`kube-flannel-ds-amd64-kwx59`，这正是我们刚才安装的网络插件flannel。

这时候我们再来看一下核心组件的状态

```bash
[root@MiWiFi-R1CM-srv yum.repos.d]# kubectl get componentstatus
NAME                 STATUS    MESSAGE              ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-0               Healthy   {"health": "true"}
```

可以看到组件的状态都已经ok了，我们再看看node的状态

```bash
[root@MiWiFi-R1CM-srv yum.repos.d]# kubectl get node
NAME              STATUS   ROLES    AGE     VERSION
miwifi-r1cm-srv   Ready    master   4h56m   v1.13.1
```

node的状态是`Ready`，说明我们的master安装成功，至此大功告成！
默认的master节点是不能调度应用pod的，所以我们还需要给master节点打一个污点标记

```bash
kubectl taint nodes --all node-role.kubernetes.io/master-
```

### 安装DashBoard

k8项目提供了一个官方的dashboard，虽然平时还是命令行用的多，但是有个UI总是好的，我们来看看怎么安装。安装其实也是非常简单，标准的k8声明式安装

```bash
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml
```

安装完后查看pod信息

```bash
[root@MiWiFi-R1CM-srv yum.repos.d]# kubectl get po -n kube-system
NAME                                      READY   STATUS    RESTARTS   AGE
coredns-86c58d9df4-gbgzx                  1/1     Running   0          4h45m
coredns-86c58d9df4-kzljk                  1/1     Running   0          4h45m
etcd-miwifi-r1cm-srv                      1/1     Running   0          4h44m
kube-apiserver-miwifi-r1cm-srv            1/1     Running   0          4h44m
kube-controller-manager-miwifi-r1cm-srv   1/1     Running   0          4h44m
kube-flannel-ds-amd64-kwx59               1/1     Running   0          4h34m
kube-proxy-9c8cs                          1/1     Running   0          4h45m
kube-scheduler-miwifi-r1cm-srv            1/1     Running   0          4h44m
kubernetes-dashboard-57df4db6b-bn5vn      1/1     Running   0          4h8m
```

可以看到多了一个`kubernetes-dashboard-57df4db6b-bn5vn`，并且已经正常启动。但出于安全性考虑，dashboard是不提供外部访问的，所以我们这边需要添加一个service，并且指定为NodePort类型，以供外部访问，service配置如下

```yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: "2019-01-11T18:12:43Z"
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system
  resourceVersion: "6015"
  selfLink: /api/v1/namespaces/kube-system/services/kubernetes-dashboard
  uid: 7dd0deb6-15cc-11e9-bb65-08002726d64d
spec:
  clusterIP: 10.102.157.202
  externalTrafficPolicy: Cluster
  ports:
  - nodePort: 30443
    port: 443
    protocol: TCP
    targetPort: 8443
  selector:
    k8s-app: kubernetes-dashboard
  sessionAffinity: None
  type: NodePort
status:
  loadBalancer: {}
```

dashboard应用的默认端口是8443，这边我们指定一个30443端口进行映射，提供外部访问入口。这时候我们就可以通过`https://ip:8443`来访问dashboard了，注意用官方的yaml创建出来的servcieaccount登陆的话，是啥权限都没有的，全部是forbidden，因为官方的给了一个minimal的role。。。我们这边为了测试方便，直接创建一个超级管理员的账号，配置如下

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dashboard
  namespace: kube-system
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: dashboard
subjects:
  - kind: ServiceAccount
    name: dashboard
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
```

创建完了之后，系统会自动创建该用户的secret，通过如下命令获取secret

```bash
[root@MiWiFi-R1CM-srv yum.repos.d]# kubectl describe secret dashboard -n kube-system
Name:         dashboard-token-s9hqc
Namespace:    kube-system
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: dashboard
              kubernetes.io/service-account.uid: 63c43e1e-15d6-11e9-bb65-08002726d64d

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1025 bytes
namespace:  11 bytes
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJkYXNoYm9hcmQtdG9rZW4tczlocWMiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiZGFzaGJvYXJkIiwia3Vi
```

将该token填入登陆界面中的token位置，即可登陆，并具有全部权限。
![dashboard.png](https://upload-images.jianshu.io/upload_images/14871146-8ca67573deb59483.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1000/format/webp)
至此一个完整的单节点k8集群安装完毕！
