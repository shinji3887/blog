---
title: "使用runC创建容器"
date: 2019-01-11
excerpt: "runC工具创建容器实战"
description: "runC工具创建容器实战"
gitalk: true
image: "img/pexels-photo-1645635.jpeg"
author: L'
tags:
    - Docker
    - Kubernetes
categories: [ Tech ]
---


> 上一篇文章中写道了docker的底层是使用runC来管理镜像的创建，启动，监控及删除的，这次就来看一下如何使用runC工具来管理镜像的生命周期

runC的使用非常简单，首先去github下载已经编译好的二进制文件（写文章的时候版本是1.0-rc6），文件名一般为runc.amd64，直接拷贝进usr/bin目录即可。先执行一下runc命令，有如下显示
```bash
NAME:
   runc - Open Container Initiative runtime

runc is a command line client for running applications packaged according to
the Open Container Initiative (OCI) format and is a compliant implementation of the
Open Container Initiative specification.

runc integrates well with existing process supervisors to provide a production
container runtime environment for applications. It can be used with your
existing process monitoring tools and the container will be spawned as a
direct child of the process supervisor.

Containers are configured using bundles. A bundle for a container is a directory
that includes a specification file named "config.json" and a root filesystem.
The root filesystem contains the contents of the container.

To start a new instance of a container:

    # runc run [ -b bundle ] <container-id>

Where "<container-id>" is your name for the instance of the container that you
are starting. The name you provide for the container instance must be unique on
your host. Providing the bundle directory using "-b" is optional. The default
value for "bundle" is the current directory.

USAGE:
   runc [global options] command [command options] [arguments...]
   
VERSION:
   1.0.0-rc6
spec: 1.0.1-dev
   
COMMANDS:
     checkpoint  checkpoint a running container
     create      create a container
     delete      delete any resources held by the container often used with detached container
     events      display container events such as OOM notifications, cpu, memory, and IO usage statistics
     exec        execute new process inside the container
     init        initialize the namespaces and launch the process (do not call it outside of runc)
     kill        kill sends the specified signal (default: SIGTERM) to the container's init process
     list        lists containers started by runc with the given root
     pause       pause suspends all processes inside the container
     ps          ps displays the processes running inside a container
     restore     restore a container from a previous checkpoint
     resume      resumes all processes that have been previously paused
     run         create and run a container
     spec        create a new specification file
     start       executes the user defined process in a created container
     state       output the state of a container
     update      update container resource constraints
     help, h     Shows a list of commands or help for one command

GLOBAL OPTIONS:
   --debug             enable debug output for logging
   --log value         set the log file path where internal debug information is written (default: "/dev/null")
   --log-format value  set the format used by logs ('text' (default), or 'json') (default: "text")
   --root value        root directory for storage of container state (this should be located in tmpfs) (default: "/run/runc")
   --criu value        path to the criu binary used for checkpoint and restore (default: "criu")
   --systemd-cgroup    enable systemd cgroup support, expects cgroupsPath to be of form "slice:prefix:name" for e.g. "system.slice:runc:434234"
   --rootless value    ignore cgroup permission errors ('true', 'false', or 'auto') (default: "auto")
   --help, -h          show help
   --version, -v       print the version
```
简单的说，runC是一个命令行工具，用来运行按照OCI标准格式打包过的应用，容器使用bundle进行配置。bundle的概念，简单来说就是一个目录，目录里包含一个配置文件`config.son`和一个root文件系统（rootfs目录），使用命令
```
# runc run [ -b bundle ] <container-id>
```
来启动一个容器，其中`-b`是可选项，用来指定bundle的位置（默认为当前目录），注意`container-id`必须在host上唯一。

因为需要制作root filesystem，所以还需要安装好docker并设置好镜像仓库（这步不是必须的，理论上只要你制作出一个符合OCI规范的filesystem都可以，只是自己弄比较麻烦）

准备工作都完成后，接下来就可以开始测试了
```bash
# create the top most bundle directory
mkdir /mycontainer
cd /mycontainer

# create the rootfs directory
mkdir rootfs

# export busybox via Docker into the rootfs directory
docker export $(docker create busybox) | tar -C rootfs -xvf -
```
这几步是先创建容器目录，再创建一个名字叫rootfs的目录，之后使用一个docker的镜像busybox（一个轻量级的linux工具集）来制作root filesystem(docker镜像都是符合OCI格式规范的)。完成后rootfs目录下会有如下文件
 ```bash
[root@localhost rootfs]# ls -l
总用量 16
drwxr-xr-x. 2 root      root      12288 1月   1 02:16 bin
drwxr-xr-x. 4 root      root         43 1月  11 09:20 dev
drwxr-xr-x. 3 root      root        139 1月  11 09:20 etc
drwxr-xr-x. 2 nfsnobody nfsnobody     6 1月   1 02:16 home
drwxr-xr-x. 2 root      root          6 1月  11 09:20 proc
drwx------. 2 root      root          6 1月   1 02:16 root
drwxr-xr-x. 2 root      root          6 1月  11 09:20 sys
drwxrwxrwt. 2 root      root          6 1月   1 02:16 tmp
drwxr-xr-x. 3 root      root         18 1月   1 02:16 usr
drwxr-xr-x. 4 root      root         30 1月   1 02:16 var
```
有了rootfs之后，我们就可以执行如下命令
```
runc spec
```
来创建一个`config.json`文件，这个文件是一个标准的OCI格式的文件，内容如下
```json
{
	"ociVersion": "1.0.1-dev",
	"process": {
		"terminal": true,
		"user": {
			"uid": 0,
			"gid": 0
		},
		"args": [
			"sh"
		],
		"env": [
			"PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
			"TERM=xterm"
		],
		"cwd": "/",
		"capabilities": {
			"bounding": [
				"CAP_AUDIT_WRITE",
				"CAP_KILL",
				"CAP_NET_BIND_SERVICE"
			],
			"effective": [
				"CAP_AUDIT_WRITE",
				"CAP_KILL",
				"CAP_NET_BIND_SERVICE"
			],
			"inheritable": [
				"CAP_AUDIT_WRITE",
				"CAP_KILL",
				"CAP_NET_BIND_SERVICE"
			],
			"permitted": [
				"CAP_AUDIT_WRITE",
				"CAP_KILL",
				"CAP_NET_BIND_SERVICE"
			],
			"ambient": [
				"CAP_AUDIT_WRITE",
				"CAP_KILL",
				"CAP_NET_BIND_SERVICE"
			]
		},
		"rlimits": [
			{
				"type": "RLIMIT_NOFILE",
				"hard": 1024,
				"soft": 1024
			}
		],
		"noNewPrivileges": true
	},
	"root": {
		"path": "rootfs",
		"readonly": true
	},
	"hostname": "runc",
	"mounts": [
		{
			"destination": "/proc",
			"type": "proc",
			"source": "proc"
		},
		{
			"destination": "/dev",
			"type": "tmpfs",
			"source": "tmpfs",
			"options": [
				"nosuid",
				"strictatime",
				"mode=755",
				"size=65536k"
			]
		},
		{
			"destination": "/dev/pts",
			"type": "devpts",
			"source": "devpts",
			"options": [
				"nosuid",
				"noexec",
				"newinstance",
				"ptmxmode=0666",
				"mode=0620",
				"gid=5"
			]
		},
		{
			"destination": "/dev/shm",
			"type": "tmpfs",
			"source": "shm",
			"options": [
				"nosuid",
				"noexec",
				"nodev",
				"mode=1777",
				"size=65536k"
			]
		},
		{
			"destination": "/dev/mqueue",
			"type": "mqueue",
			"source": "mqueue",
			"options": [
				"nosuid",
				"noexec",
				"nodev"
			]
		},
		{
			"destination": "/sys",
			"type": "sysfs",
			"source": "sysfs",
			"options": [
				"nosuid",
				"noexec",
				"nodev",
				"ro"
			]
		},
		{
			"destination": "/sys/fs/cgroup",
			"type": "cgroup",
			"source": "cgroup",
			"options": [
				"nosuid",
				"noexec",
				"nodev",
				"relatime",
				"ro"
			]
		}
	],
	"linux": {
		"resources": {
			"devices": [
				{
					"allow": false,
					"access": "rwm"
				}
			]
		},
		"namespaces": [
			{
				"type": "pid"
			},
			{
				"type": "network"
			},
			{
				"type": "ipc"
			},
			{
				"type": "uts"
			},
			{
				"type": "mount"
			}
		],
		"maskedPaths": [
			"/proc/kcore",
			"/proc/latency_stats",
			"/proc/timer_list",
			"/proc/timer_stats",
			"/proc/sched_debug",
			"/sys/firmware",
			"/proc/scsi"
		],
		"readonlyPaths": [
			"/proc/asound",
			"/proc/bus",
			"/proc/fs",
			"/proc/irq",
			"/proc/sys",
			"/proc/sysrq-trigger"
		]
	}
}
```
这边再说一下OCI规范，援引一段OCI官网的说明

> Established in June 2015 by Docker and other leaders in the container industry, the OCI currently contains two specifications: the Runtime Specification ([runtime-spec](http://www.github.com/opencontainers/runtime-spec)) and the Image Specification ([image-spec](http://www.github.com/opencontainers/image-spec)). The Runtime Specification outlines how to run a “[filesystem bundle](https://github.com/opencontainers/runtime-spec/blob/master/bundle.md)” that is unpacked on disk. At a high-level an OCI implementation would download an OCI Image then unpack that image into an OCI Runtime filesystem bundle. At this point the OCI Runtime Bundle would be run by an OCI Runtime.

简单的说，OCI有两个规范，一个是容器运行时规范`runtime-spec`，一个是镜像格式规范`image-spec`。一个镜像，简单来说就是一个打包好的符合OCI规范的`filesystem bundule`。而bundile的话，前面介绍过，包含一个配置文件`config.json`和一个rootfs目录。

现在`rootfs`和`config.json`都有了，我们可以创建容器了，执行
```
runc run mycontainerid
```
创建容器，成功后会自动进入容器
这时候我们执行`ps`一下，可以看到
```
/ # ps
PID   USER     TIME  COMMAND
    1 root      0:00 sh
    7 root      0:00 ps
```
可以看到这个容器里面的1号进程就是sh那个进程，看不到其他进程，容器启动试验成功。

现在我们可以做容器的整个生命周期管理了
```
# run as root
cd /mycontainer
runc create mycontainerid

# view the container is created and in the "created" state
runc list

# start the process inside the container
runc start mycontainerid

# after 5 seconds view that the container has exited and is now in the stopped state
runc list

# now delete the container
runc delete mycontainerid
```
注意在执行`runc create mycontainerid`命令时，会报错
```
cannot allocate tty if runc will detach without setting console socket
```
这是由于在`config.json`文件中的配置`"terminal": true`，这个默认是true，即以终端方式启动，需要改成false。