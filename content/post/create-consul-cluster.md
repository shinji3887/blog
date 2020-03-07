---
title: "consul集群搭建及spring cloud集成"
date: 2019-09-16
excerpt: "consul集群搭建及spring cloud集成"
description: "consul概念解析，集群搭建及作为配置中心与spring cloud集成"
gitalk: true
image: "https://lupeier.cn-sh2.ufileos.com/beautiful-beautiful-flowers-bloom-1018432.jpg"
author: 陆培尔
tags:
    - Spring Cloud
    - Microservices
categories: [ Tech ]
---

> consul概念解析，集群搭建及作为配置中心与spring cloud集成

### Consul是什么?

Consul 官方站点：[https://www.consul.io/](https://www.consul.io/)

官方介绍是：Consul 是一种服务网格的解决方案，在 Consul 中，提供了服务发现、配置、分段等控制管理平台，Consul 中的每项功能都可以单独使用，也可以一起使用来构建完整的服务网格；在 Consul 内部，有一个简单的代理服务，所以在安装 Consul 后，马上就可以开始使用 Consul ；当然，Consul 也支持集成第三方代理，比如 Envoy。

Consul 是一个服务组件，在用户下载 Consul 的安装包后，可以立即运行它，或者通过其它托管程序运行它，Consul 只有一个程序包，无需另行安装；当运行 Consul 的时候，需要为其指定一些必须的参数，以供 Consul 在运行时使用；（比如参数 -data-dir 表示指定 Consul 存放数据的目录）。

我们不整那些服务网格之类的概念，简单说，Consul在整个微服务架构体系里面就是起了注册中心和配置中心的作用。

### Consul功能概述

#### 服务注册

Consul 内部侦听 8500 端口，提供给 Consul 的客户端注册服务，比如张三开发了一个购物车程序，该购物车程序包含了“加入购物车”、“清空购物车” 两个接口，张三在开发购物车程序的时候，使用了 Consul 的客户端包组件，在程序运行起来以后，购物车程序就自动的连接到 Consul 的 8500 端口，注册了一个服务，该服务被命名为“购物车程序”，此时，Consul 并不知道 “购物车程序”有多少个接口，Consul 只知道 “购物车程序”的服务地址、端口。

#### 服务发现

在“购物车程序”注册到 Consul 后，Consul 也仅仅知道有这么一个服务注册进来了，并且还配置了健康检查， Consul 会定时的去连接 “购物车程序”，确保其还处于可提供服务的状态，任何人（程序）都可以通过 Consul 的外部地址访问 Consul 内部的已注册的服务列表，从而获得真实的服务地址，然后调用该真实地址，获得结果。

#### 键值存储

在 Consul 内部，提供了简单的数据存储，也就是 key/value 系统，kv 系统非常强大，它的作用包括允许节点动态修改配置、执行 leader 选举、服务发现、集成健康检查、或者其它你想要存储到 Consul 中的内容

### Consul部署架构

#### 集群

Consul 是一个分布式的解决方案，可以部署多个 Consul 实例，确保数据中心的持续稳定，在 Consul 集群中，内部采用投票的方式选举出 leader，然后才开始运行整个集群，只有正确选举出 leader 后，集群才开始工作，当一个服务注册到 Consul 后，集群将该服务进行同步，确保 Consul 集群内的每个节点都存储了该服务的信息；然后，Consul 集群将对该服务进行健康检查和投票，超过半数通过，即认为该服务为正常（或者异常）；一旦被投票认定为异常的服务，该服务将不会被外部发现（不可访问），在此过程中，Consul 将持续的对该异常的服务进行检查，一旦服务恢复，Consul 即刻将其加入正常服务。

#### 服务器和客户端

Consul 支持两种运行的方式，即 server 和 client 模式，当一个 Consul 节点以 server 模式运行的时候，就表示该 Consul 节点会存储服务和配置等相关信息，并且参与到健康检查、leader 选举等服务器事务中，与之相反的是，client 模式不会存储服务信息。

#### 数据中心

每个 Consul 节点都需要加入一个命名的数据中心（DataCenter），一个节点上，可以运行多个数据中心，数据中心的作用在于应用隔离，相当于服务分组。可以简单理解为，一个数据中心域为一个二层联通的子网。

下图为consul的官方架构图：
![consul.png](https://upload-images.jianshu.io/upload_images/14871146-f93f234dafbdebbc.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### Consul能做什么?

简单来说，consul是一个分布式的服务管理平台，应用可以利用consul来进行分布式服务的服务注册、服务发现、配置管理、分布式事务协调等功能。借助于raft共识算法，可以轻松搭建出一个高可用的分布式集群，各节点所存储的数据通过raft算法可以保证最终一致性，而不需要依赖于任何的外部数据库。（这点非常重要，要知道搭建一个高可用的mysql数据库本身成本就非常高，nacos的数据存储目前只支持mysql，现在貌似也有规划转分布式算法）。通过上面的介绍，相信你也看出来了，consul做的事情本质上和zookeeper、etcd这些分布式服务组件都差不多，只是zookeeper用的一致性算法是zab（基于paxos），向来以难以理解著称，而etcd也是raft算法，相对容易理解很多，但是不带ui管理界面，易用性方面consul会好一点

### 集群搭建

#### 下载安装

consul安装非常简单，直接在官网下载对应操作系统编译好的二进制文件就行，网址为[https://www.consul.io/downloads.html](https://www.consul.io/downloads.html)。整个压缩包就一个二进制文件consul，拷贝至系统的`/usr/bin`就ok了。执行consul，看到如下输出，说明安装成功：

```bash
[consul@localhost ~]$ consul
Usage: consul [--version] [--help] <command> [<args>]

Available commands are:
    acl            Interact with Consul's ACLs
    agent          Runs a Consul agent
    catalog        Interact with the catalog
    config         Interact with Consul's Centralized Configurations
    connect        Interact with Consul Connect
    debug          Records a debugging archive for operators
    event          Fire a new event
    exec           Executes a command on Consul nodes
    force-leave    Forces a member of the cluster to enter the "left" state
    info           Provides debugging information for operators.
    intention      Interact with Connect service intentions
    join           Tell Consul agent to join cluster
    keygen         Generates a new encryption key
    keyring        Manages gossip layer encryption keys
    kv             Interact with the key-value store
    leave          Gracefully leaves the Consul cluster and shuts down
    lock           Execute a command holding a lock
    login          Login to Consul using an auth method
    logout         Destroy a Consul token created with login
    maint          Controls node or service maintenance mode
    members        Lists the members of a Consul cluster
    monitor        Stream logs from a Consul agent
    operator       Provides cluster-level tools for Consul operators
    reload         Triggers the agent to reload configuration files
    rtt            Estimates network round trip time between nodes
    services       Interact with services
    snapshot       Saves, restores and inspects snapshots of Consul server state
    tls            Builtin helpers for creating CAs and certificates
    validate       Validate config files/directories
    version        Prints the Consul version
    watch          Watch for changes in Consul
```

##### consul参数说明

- agent：是consul的核心指令，它运行agent来维护成员的重要信息、运行检查、服务宣布、查询处理等等。
- event：提供了一种机制，用来fire自定义的用户事件，这些事件对consul来说是不透明的，但它们可以用来构建自动部署、重启服务或者其他行动的脚本。
- exec：提供了一种远程执行机制，比如你要在所有的机器上执行uptime命令，远程执行的工作通过job来指定，存储在KV中。agent使用event系统可以快速的知道有新的job产生，消息是通过gossip协议来传递的，因此消息传递是最佳的，但是并不保证命令的执行。事件通过gossip来驱动，远程执行依赖KV存储系统(就像消息代理一样)。
- force-leave：可以强制consul集群中的成员进入left状态(空闲状态)，记住，即使一个成员处于活跃状态，它仍旧可以再次加入集群中，这个方法的真实目的是强制移除failed的节点。如果failed的节点还是网络的一部分，则consul会周期性的重新链接failed的节点，如果经过一段时间后(默认是72小时)，consul则会宣布停止尝试链接failed的节点。force-leave指令可以快速的把failed节点转换到left状态。
- info：提供了各种操作时可以用到的debug信息，对于client和server，info有返回不同的子系统信息，目前有以下几个KV信息：agent(提供agent信息)，consul(提供consul库的信息)，raft(提供raft库的信息)，serf_lan(提供LAN gossip pool),serf_wan(提供WAN gossip pool)。
- join：告诉consul agent加入一个已经存在的集群中，一个新的consul agent必须加入一个已经有至少一个成员的集群中，这样它才能加入已经存在的集群中，如果你不加入一个已经存在的集群，则agent是它自身集群的一部分，其他agent则可以加入进来。agent可以加入其他agent多次。如果你想加入多个集群，则可以写多个地址，consul会加入所有的地址。
- keygen：生成加密的密钥，可以用在consul agent通讯加密。
leave指令触发一个优雅的离开动作并关闭agent，节点离开后不会尝试重新加入集群中。运行在server状态的节点，节点会被优雅的删除，这是很严重的，在某些情况下一个不优雅的离开会影响到集群的可用性。
- members：输出consul agent目前所知道的所有的成员以及它们的状态，节点的状态只有alive、left、failed三种状态。
- monitor：用来链接运行的agent，并显示日志。monitor会显示最近的日志，并持续的显示日志流，不会自动退出，除非你手动或者远程agent自己退出。
- reload：可以重新加载agent的配置文件。SIGHUP指令在重新加载配置文件时使用，任何重新加载的错误都会写在agent的log文件中，并不会打印到屏幕。
- version：打印consul的版本
- watch：提供了一个机制，用来监视实际数据视图的改变(节点列表、成员服务、KV)，如果没有指定进程，当前值会被dump出来。

##### agent参数说明

核心对象的agent，我们来看一下它的启动参数

```bash
[consul@localhost ~]$ consul agent --help
Usage: consul agent [options]

  Starts the Consul agent and runs until an interrupt is received. The
  agent represents a single node in a cluster.

HTTP API Options

  -datacenter=<value>
     Datacenter of the agent.

Command Options

  -advertise=<value>
     Sets the advertise address to use.

  -advertise-wan=<value>
     Sets address to advertise on WAN instead of -advertise address.

  -allow-write-http-from=<value>
     Only allow write endpoint calls from given network. CIDR format,
     can be specified multiple times.

  -alt-domain=<value>
     Alternate domain to use for DNS interface.

  -bind=<value>
     Sets the bind address for cluster communication.

  -bootstrap
     Sets server to bootstrap mode.

  -bootstrap-expect=<value>
     Sets server to expect bootstrap mode.

  -check_output_max_size=<value>
     Sets the maximum output size for checks on this agent

  -client=<value>
     Sets the address to bind for client access. This includes RPC, DNS,
     HTTP, HTTPS and gRPC (if configured).

  -config-dir=<value>
     Path to a directory to read configuration files from. This
     will read every file ending in '.json' as configuration in this
     directory in alphabetical order. Can be specified multiple times.

  -config-file=<value>
     Path to a file in JSON or HCL format with a matching file
     extension. Can be specified multiple times.

  -config-format=<value>
     Config files are in this format irrespective of their extension.
     Must be 'hcl' or 'json'

  -data-dir=<value>
     Path to a data directory to store agent state.

  -dev
     Starts the agent in development mode.

  -disable-host-node-id
     Setting this to true will prevent Consul from using information
     from the host to generate a node ID, and will cause Consul to
     generate a random node ID instead.

  -disable-keyring-file
     Disables the backing up of the keyring to a file.

  -dns-port=<value>
     DNS port to use.

  -domain=<value>
     Domain to use for DNS interface.

  -enable-local-script-checks
     Enables health check scripts from configuration file.

  -enable-script-checks
     Enables health check scripts.

  -encrypt=<value>
     Provides the gossip encryption key.

  -grpc-port=<value>
     Sets the gRPC API port to listen on (currently needed for Envoy xDS
     only).

  -hcl=<value>
     hcl config fragment. Can be specified multiple times.

  -http-port=<value>
     Sets the HTTP API port to listen on.

  -join=<value>
     Address of an agent to join at start time. Can be specified
     multiple times.

  -join-wan=<value>
     Address of an agent to join -wan at start time. Can be specified
     multiple times.

  -log-file=<value>
     Path to the file the logs get written to

  -log-level=<value>
     Log level of the agent.

  -log-rotate-bytes=<value>
     Maximum number of bytes that should be written to a log file

  -log-rotate-duration=<value>
     Time after which log rotation needs to be performed

  -log-rotate-max-files=<value>
     Maximum number of log file archives to keep

  -node=<value>
     Name of this node. Must be unique in the cluster.

  -node-id=<value>
     A unique ID for this node across space and time. Defaults to a
     randomly-generated ID that persists in the data-dir.

  -node-meta=<key:value>
     An arbitrary metadata key/value pair for this node, of the format
     `key:value`. Can be specified multiple times.

  -non-voting-server
     (Enterprise-only) This flag is used to make the server not
     participate in the Raft quorum, and have it only receive the data
     replication stream. This can be used to add read scalability to
     a cluster in cases where a high volume of reads to servers are
     needed.

  -pid-file=<value>
     Path to file to store agent PID.

  -protocol=<value>
     Sets the protocol version. Defaults to latest.

  -raft-protocol=<value>
     Sets the Raft protocol version. Defaults to latest.

  -recursor=<value>
     Address of an upstream DNS server. Can be specified multiple times.

  -rejoin
     Ignores a previous leave and attempts to rejoin the cluster.

  -retry-interval=<value>
     Time to wait between join attempts.

  -retry-interval-wan=<value>
     Time to wait between join -wan attempts.

  -retry-join=<value>
     Address of an agent to join at start time with retries enabled. Can
     be specified multiple times.

  -retry-join-wan=<value>
     Address of an agent to join -wan at start time with retries
     enabled. Can be specified multiple times.

  -retry-max=<value>
     Maximum number of join attempts. Defaults to 0, which will retry
     indefinitely.

  -retry-max-wan=<value>
     Maximum number of join -wan attempts. Defaults to 0, which will
     retry indefinitely.

  -segment=<value>
     (Enterprise-only) Sets the network segment to join.

  -serf-lan-bind=<value>
     Address to bind Serf LAN listeners to.

  -serf-lan-port=<value>
     Sets the Serf LAN port to listen on.

  -serf-wan-bind=<value>
     Address to bind Serf WAN listeners to.

  -serf-wan-port=<value>
     Sets the Serf WAN port to listen on.

  -server
     Switches agent to server mode.

  -server-port=<value>
     Sets the server port to listen on.

  -syslog
     Enables logging to syslog.

  -ui
     Enables the built-in static web UI server.

  -ui-content-path=<value>
     Sets the external UI path to a string. Defaults to: /ui/

  -ui-dir=<value>
     Path to directory containing the web UI resources.
```

- -advertise：通知展现地址用来改变我们给集群中的其他节点展现的地址，一般情况下-bind地址就是展现地址
- -bootstrap：用来控制一个server是否在bootstrap模式，在一个datacenter中只能有一个server处于bootstrap模式，当一个server处于bootstrap模式时，可以自己选举为raft leader。
- -bootstrap-expect：在一个datacenter中期望提供的server节点数目，当该值提供的时候，consul一直等到达到指定sever数目的时候才会引导整个集群，该标记不能和bootstrap公用。
- -bind：该地址用来在集群内部的通讯，集群内的所有节点到地址都必须是可达的，默认是0.0.0.0。
- -client：consul绑定在哪个client地址上，这个地址提供HTTP、DNS、RPC等服务，默认是127.0.0.1。
- -config-file：明确的指定要加载哪个配置文件
- -config-dir：配置文件目录，里面所有以.json结尾的文件都会被加载
- -data-dir：提供一个目录用来存放agent的状态，所有的agent都需要该目录，该目录必须是稳定的，系统重启后都继续存在。
- -dc：该标记控制agent的datacenter的名称，默认是dc1。
- -encrypt：指定secret key，使consul在通讯时进行加密，key可以通过consul keygen生成，同一个集群中的节点必须使用相同的key。
- -join：加入一个已经启动的agent的ip地址，可以多次指定多个agent的地址。如果consul不能加入任何指定的地址中，则agent会启动失败。默认agent启动时不会加入任何节点。
- -retry-join：和join类似，但是允许你在第一次失败后进行尝试。
- -retry-interval：两次join之间的时间间隔，默认是30s。
- -retry-max：尝试重复join的次数，默认是0，也就是无限次尝试。
- -log-level：consul agent启动后显示的日志信息级别。默认是info，可选：trace、debug、info、warn、err。
- -node：节点在集群中的名称，在一个集群中必须是唯一的，默认是该节点的主机名。
- -protocol：consul使用的协议版本。
- -rejoin：使consul忽略先前的离开，在再次启动后仍旧尝试加入集群中。
- -server：定义agent运行在server模式，每个集群至少有一个server，建议每个集群的server不要超过5个。
- -syslog：开启系统日志功能，只在linux/osx上生效。
- -ui-dir:提供存放web ui资源的路径，该目录必须是可读的。
- -pid-file:提供一个路径来存放pid文件，可以使用该文件进行SIGINT/SIGHUP(关闭/更新)agent。

#### 启动节点

了解了参数之后，我们就可以来启动集群了。这次我们规划了三个节点（一般建议为奇数节点），启动命令如下：

```bash
// 22.196.248.71
consul agent -server -ui -bootstrap -data-dir=/data/consul -node=agent-1 -client=0.0.0.0 -bind=22.196.248.71 -datacenter=dc1

// 22.196.248.73
consul agent -server -ui -data-dir=/data/consul -node=agent-2 -client=0.0.0.0 -bind=22.196.248.73 -datacenter=dc1 -join 22.196.248.71

// 22.196.248.74
consul agent -server -ui -data-dir=/data/consul -node=agent-3 -client=0.0.0.0 -bind=22.196.248.74 -datacenter=dc1 -join 22.196.248.71
```

解释一下上面的指令，简单来说，就是指定当前主机客户端侦听地址为`-client=0.0.0.0`（这个参数指定了客户端允许接入的地址，0.0.0.0为任意地址可以接入，默认为127.0.0.1，即只有本机能接入），绑定了当前主机的IP地址（-bind，多网卡的话必须要设置，让consul知道使用哪个ip作为节点的ip），指定了一个数据中心的名称（-datacenter=dc1），后两台服务器在启动的时候加入第一台代理服务器（-join 22.196.248.71），同时指定了启用每台服务器的内置 WebUI 服务器组件（-ui），当三台服务器都正确运行起来以后，Consul 集群将自动选举 leader，自动进行集群事务，无需干预。
> 这里需要注意一点，理论上consul节点起来之后可以通过raft算法自动选举leader出来，但是我这边没有成功，日志提示选举失败，需要通过设置-bootstrap参数先启动某个节点，这个节点会自动把自己设置为leader，后面启动的节点就可以正常加入了。具体原因未知，有高手知道的请指点一下

此时访问任意一台服务器的http://ip:8500，都可以看到ui界面
![image.png](https://upload-images.jianshu.io/upload_images/14871146-6d97de0329dc014c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
看到这个界面说明三个节点都正常启动了，我们在key/value插入一些数据，可以看到在三个节点都能正确查询到，集群bootstrap成功。

### Spring Cloud 集成

#### 配置中心

这边我们看看如何与spring cloud集成，使用consul作为应用的配置中心。为简单起见我们使用zuul网关作为示例，只使用了配置中心功能，没用注册中心功能
在zuul的pom文件中添加如下依赖：

```xml
<dependencies>
  <dependency>
  <groupId>org.springframework.cloud</groupId>
  <artifactId>spring-cloud-starter-consul-config</artifactId>
  </dependency>
</dependencies>
```

修改配置文件（注意要使用bootstrap.yml进行配置，不要用application.yml，否则配置不会起作用）

```yml
spring:
  application:
    name: bocsh-gateway
  cloud:
    consul:
      host: 22.196.248.71
      port: 8500
      config:
        enabled: true
        format: yaml
        #data-key表示consul上面的KEY值(或者说文件的名字) ,默认是data
        #prefix设置配置值的基本文件夹，默认为config
        #defaultContext设置所有应用程序使用的文件夹名称，默认为spring的应用名称
        #profileSeparator设置用于使用配置文件在属性源中分隔配置文件名称的分隔符的值,默认为逗号
server:
  port: 30080
```

注意`data-key`,`prefix`,`defaultContext`,`profileSeparator`这几个配置都是可选项，定义了我们的配置文件在consul中存储的目录结构，spring boot 在启动时会在这个路径下获取配置文件信息，如果都是使用默认值得话，在consul中存储的数据结构如下（默认读取的是default配置）：
![image.png](https://upload-images.jianshu.io/upload_images/14871146-a5ce8d1a0a69d055.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
key为`config/bocsh-gateway/data`

#### 动态配置更新

首先，spring cloud consul组件是有动态更新配置能力的，官方称之为Config Watch。原理是consul客户端定时向consul服务端发起一个http请求，以检测服务端的配置是否有更新（类似于在actuator端点执行/refresh操作，但consul是自动的，不需要专门触发），相关配置如下：

```yaml
spring:
  cloud:
    consul:
      config:
        watch: 
          enable: #default true
          wait-time: #default 55
          delay: #default 1000
```

可以看到配置更新能力默认是开启的，不想动态更新的话可以通过设置`spring.cloud.consul.config.watch.enabled=false`关闭Config Watch功能。

有了上面的知识，我们就可以来配置动态路由了，首先在启动主类下加入如下配置：

```java
@EnableZuulProxy
@SpringBootApplication
public class BaseApplication {

    public static void main(String[] args) {

        SpringApplication.run(BaseApplication.class, args);
    }

    @RefreshScope
    @ConfigurationProperties("zuul")
    public ZuulProperties zuulProperties(){
        return new ZuulProperties();
    }

}
```

在配置文件中打开actuator的routes端点，使我们可以观察routes变化的情况

```yaml
management:
  endpoints:
    web:
      exposure:
        include: routes
```

修改consul中的key/value值，通过访问`http://ip:port/actuator/routes`可以看到zuul目前的最新路由表，配置实时更新，实现了动态配置功能。
> 这里需要注意一点，如果你改的是zuul路由表中的`path`部分，则原有的路由信息不会消息，会新增一条你修改后的路由信息，修改`url`部分则可以实时生效。

### 参考资料

1.[https://www.cnblogs.com/linjiqin/p/9718223.html](https://www.cnblogs.com/linjiqin/p/9718223.html)
2.[https://blog.csdn.net/it_lihongmin/article/details/91357445](https://blog.csdn.net/it_lihongmin/article/details/91357445)
3.[https://consul.io](https://consul.io)
4.[https://cloud.spring.io/spring-cloud-static/spring-cloud-consul/2.1.3.RELEASE/single/spring-cloud-consul.html](https://cloud.spring.io/spring-cloud-static/spring-cloud-consul/2.1.3.RELEASE/single/spring-cloud-consul.html)
