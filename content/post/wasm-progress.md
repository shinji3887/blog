---
title: "一年之后的 Istio 和 Envoy WebAssembly 可扩展性"
date: 2021-03-05
excerpt: "一年之后的 Istio 和 Envoy WebAssembly 可扩展性"
description: "一年之后，让我们再来看看Istio 和 Envoy WebAssembly 可扩展性的发展现状"
gitalk: true
image: "https://lupeier.cn-sh2.ufileos.com/pexels-sails-611328.jpg"
author: Istio.io
tags:
    - Kubernetes
    - Istio
    - ServiceMesh
categories: [ Tech ]
---

> 译者注：去年3月份，Istio 社区重磅推出了以 Wasm 技术为核心的 Proxy-Wasm plugins 体系，可扩展性和遥测技术的发展都将以 Wasm 技术为基础，具体可以看我之前的《WebAssembly in Envoy》、《重新定义代理的扩展性：WebAssembly在Envoy与Istio中的应用》这两篇文章。社区同时也在大力发展规范体系，这其实也是谷歌的一贯打法，即标准先行，所谓一流企业定标准。具体来说做了两件事情，第一是制定代理无关的 WebAssembly for Proxies (ABI specification)，第二是扶持以 solo 为首的初创企业高调推出 webassemblyhub，大力建设插件生态。如今正好过去了一年，Wasm 生态发展得如何了呢？Wasm Proxy Spec 规范是否能一统代理扩展插件的天下？让我们来看看官方发布的博客。

一年前的今天，在 1.5 版本中，我们向 Istio 引入了[基于 WebAssembly 的可扩展性](https://istio.io/latest/zh/blog/2020/wasm-announce/)。在这一年中，Istio，Envoy 和 Proxy-Wasm 社区一直在共同努力，以使 WebAssembly（Wasm）的扩展性稳定、可靠且易于采用。 让我们逐一介绍 Istio 1.9 版本中 Wasm 支持的更新以及我们的未来计划。

### WebAssembly支持在上游 Envoy 中被合并

自从在 Istio fork 的 Envoy 分支中添加了对 Wasm 和 WebAssembly for Proxies（Proxy-Wasm）ABI 的实验性支持之后，我们从早期采用者社区中收集了一些宝贵的反馈意见。这与开发核心 Istio Wasm 扩展所获得的经验相结合，帮助我们成熟并稳定了运行时。所有的这些工作，使得 Wasm 支持在2020年10月顺利的合并到 Envoy 上游，使其成为 Envoy 所有正式版本的一部分。 这是一个重要的里程碑，因为它表明：

- 运行时已为广泛采用做好了准备。
- ABI/API 的编程、扩展配置 API 和运行时行为正在变得稳定。
- 您可以期待更大范围的采用和社区支持。

### wasm-extensions Ecosystem 仓库

作为 Envoy Wasm 运行时的早期采用者，Istio 扩展和遥测工作组在开发扩展方面积累了很多经验。我们构建了几个一流的扩展，包括[元数据交换](https://istio.io/latest/docs/reference/config/proxy_extensions/metadata_exchange/)，[Prometheus统计信息](https://istio.io/latest/docs/reference/config/proxy_extensions/stats/)和[属性生成](https://istio.io/latest/docs/reference/config/proxy_extensions/attributegen/)。为了更广泛地分享我们的知识，我们在 **istio-ecosystem** 组织中创建了[ wasm-extensions 存储库](https://github.com/istio-ecosystem/wasm-extensions)。 该存储库有两个用途：

- 它提供了规范的示例扩展，涵盖了一些非常需要的功能（例如[基础身份验证](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth)）。
- 它为 Wasm 扩展的开发、测试和发布提供了指南。该指南基于 Istio 可扩展性团队正在使用、维护和测试的相同的构建工具链和测试框架。

该指南目前涵盖使用 C++ 进行 [WebAssembly 扩展开发](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md)和[单元测试](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-cpp-unit-test.md)，以及使用 Go 测试框架进行[集成测试](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-integration-test.md)，该框架通过使用 Istio 代理二进制文件运行 Wasm 模块来模拟实际运行时。将来，我们还将添加更多规范的扩展，例如与 Open Policy Agent 的集成以及基于 JWT 令牌的标头处理。

### 通过 Istio Agent 分发 Wasm 模块

在 Istio 1.9 之前，需要 [Envoy 远程数据源](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/base.proto#config-core-v3-remotedatasource)才能将远程 Wasm 模块分发到代理。在[此示例](https://gist.github.com/bianpengyuan/8377898190e8052ffa36e88a16911910)中，您可以看到定义了两个 `EnvoyFilter` 资源：一个用于添加远程获取 Envoy 集群，另一个用于将 Wasm 过滤器注入到 HTTP 过滤器链中。这种方法有一个缺点：如果由于配置错误或瞬时错误而导致远程获取失败，Envoy 将被错误的配置阻塞。如果将 Wasm 扩展配置为[失败后关闭](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/wasm/v3/wasm.proto#extensions-wasm-v3-pluginconfig)，则错误的远程提取将停止 Envoy 的服务。若要解决此问题，需要对Envoy xDS 协议进行[根本性的修改](https://github.com/envoyproxy/envoy/issues/9447)，以使其允许异步 xDS 响应。

Istio 1.9 通过利用 istio-agent 内的 xDS 代理和 Envoy 的[扩展配置发现服务](https://www.envoyproxy.io/docs/envoy/latest/configuration/overview/extension)（ECDS），提供了一种现成的可靠分发机制。

istio-agent 从 istiod 拦截扩展配置资源更新，从中读取远程获取提示，下载 Wasm 模块，并使用下载的 Wasm 模块的路径重写 ECDS 配置。如果下载失败，istio-agent 将拒绝 ECDS 更新，并阻止错误的配置到达Envoy。有关更多详细信息，请参阅[有关 Wasm 模块分发的文档](https://istio.io/latest/docs/ops/configuration/extensibility/wasm-module-distribution/)。

![Remote Wasm module fetch flow](https://istio.io/latest/blog/2021/wasm-progress/architecture-istio-agent-downloading-wasm-module.svg)

### Istio Wasm SIG 和未来的工作

尽管我们在 Wasm 可扩展性方面取得了许多进展，但该项目仍有许多方面有待完成。为了巩固各方的努力并更好地应对未来的挑战，我们成立了 [Istio WebAssembly SIG](https://discuss.istio.io/t/introducing-wasm-sig/9930)，旨在为 Istio 提供一种标准且可靠的方式来使用 Wasm 扩展。以下是我们正在从事的一些工作：

- **第一等的扩展 API** ：目前需要通过 Istio 的 `EnvoyFilter` API 注入 Wasm 扩展。第一等的扩展 API 将使 Wasm 与 Istio 的使用更加容易，我们希望在 Istio 1.10 中引入它。
- **制品分发的互操作性**：标准的 Wasm 制品格式建立在 Solo.io 的 [WebAssembly OCI 镜像规范工作](https://www.solo.io/blog/announcing-the-webassembly-wasm-oci-image-spec/)的基础上，可以轻松地构建、提取、发布和执行。
- **基于容器存储接口（CSI）的制品分发**：使用 istio-agent 分发模块很容易被采用，但可能效率不高，因为每个代理都将保留 Wasm 模块的副本。作为更有效的解决方案，使用 [Ephemeral CSI](https://kubernetes-csi.github.io/docs/ephemeral-local-volumes.html)，将提供一个 DaemonSet，它可以配置 Pod 的存储。CSI 驱动程序的工作方式类似于 CNI 插件，将在 pod 启动时从 xDS 流中带外提取 Wasm 模块，并将其安装在`rootfs`中。

如果您想加入我们，小组将每两周星期二下午2点（太平洋标准时间）开会。 您可以在 [Istio 工作组日历](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings)上找到会议。

我们期待看到您将如何使用 Wasm 扩展 Istio！

原文：[Istio and Envoy WebAssembly Extensibility, One Year On](https://istio.io/latest/blog/2021/wasm-progress/#webassembly-support-merged-in-upstream-envoy)
