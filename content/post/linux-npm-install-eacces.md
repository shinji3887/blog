---
title: "linux下使用npm install报EACCES的解决方法"
date: 2018-11-21
excerpt: "npm使用技巧"
description: "npm使用技巧"
gitalk: true
author: L'
tags:
    - npm
categories: [ Tips ]
---

前端项目需要进行CI/CD集成，CI服务器是linux版本的，所以需要在服务器上安装npm环境，记录一下安装过程以及碰到的坑。安装很简单，直接下载官网的[linux二进制包](https://nodejs.org/dist/v10.13.0/node-v10.13.0-linux-x64.tar.xz)，并将bin目录设置在环境变量中就ok了，执行

```bash
[root@localhost dist]# npm -version
6.4.1
```

说明安装成功了，接下来在执行项目的初始化（基于vue-cli）npm install时，却反复提示权限不足

```bash
[root@localhost bocsh-vue-admin]# npm install

> nodent-runtime@3.2.1 install /home/gitlab-runner/builds/0444212d/0/7310754/bocsh-vue-admin/node_modules/nodent-runtime
> node build.js

fs.js:115
    throw err;
    ^

Error: EACCES: permission denied, open '/home/gitlab-runner/builds/0444212d/0/7310754/bocsh-vue-admin/node_modules/nodent-runtime/dist/index.js'
    at Object.openSync (fs.js:436:3)
    at Object.writeFileSync (fs.js:1187:35)
    at Object.<anonymous> (/home/gitlab-runner/builds/0444212d/0/7310754/bocsh-vue-admin/node_modules/nodent-runtime/build.js:5:4)
    at Module._compile (internal/modules/cjs/loader.js:688:30)
    at Object.Module._extensions..js (internal/modules/cjs/loader.js:699:10)
    at Module.load (internal/modules/cjs/loader.js:598:32)
    at tryModuleLoad (internal/modules/cjs/loader.js:537:12)
    at Function.Module._load (internal/modules/cjs/loader.js:529:3)
    at Function.Module.runMain (internal/modules/cjs/loader.js:741:12)
    at startup (internal/bootstrap/node.js:285:19)
npm WARN ajv-errors@1.0.0 requires a peer of ajv@>=5.0.0 but none is installed. You must install peer dependencies yourself.
npm WARN ajv-keywords@2.1.1 requires a peer of ajv@^5.0.0 but none is installed. You must install peer dependencies yourself.
npm WARN eslint-config-standard@12.0.0-alpha.0 requires a peer of eslint@>=5.0.0-alpha.2 but none is installed. You must install peer dependencies yourself.
npm WARN bocsh-vue-admin@2.1.0 No repository field.
npm WARN bocsh-vue-admin@2.1.0 No license field.
npm WARN optional SKIPPING OPTIONAL DEPENDENCY: fsevents@1.2.4 (node_modules/fsevents):
npm WARN notsup SKIPPING OPTIONAL DEPENDENCY: Unsupported platform for fsevents@1.2.4: wanted {"os":"darwin","arch":"any"} (current: {"os":"linux","arch":"x64"})

npm ERR! code ELIFECYCLE
npm ERR! errno 1
npm ERR! nodent-runtime@3.2.1 install: `node build.js`
npm ERR! Exit status 1
npm ERR!
npm ERR! Failed at the nodent-runtime@3.2.1 install script.
npm ERR! This is probably not a problem with npm. There is likely additional logging output above.
```

这里百思不得其解，谷歌了半天，还是官网的一篇文章解决问题，就是更换npm的默认存储库（至于为什么换了就好了，也不明白，我是root用户啊。。），步骤如下：

1. Back up your computer.

1. On the command line, in your home directory, create a directory for global installations:
  ```bash
mkdir ~/.npm-global
```

1. Configure npm to use the new directory path:
  ```bash
 npm config set prefix '~/.npm-global'
```

1. In your preferred text editor, open or create a ~/.profile file and add this line:
  ```bash
export PATH=~/.npm-global/bin:$PATH
```

1. On the command line, update your system variables:
  ```bash
 source ~/.profile
```

1. To test your new configuration, install a package globally without using sudo:
  ```bash
npm install -g jshint
```

重新安装package顺利下载。
总结：其实也没啥好总结的，碰到问题多看官网多看英文文档（能谷歌最好），一般都比较靠谱。

[官网文章链接](https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally)
