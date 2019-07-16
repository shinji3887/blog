---
title: "Richardson Maturity Model-迈向REST的顶点"
date: 2019-06-29
excerpt: "经典的评测REST成熟度模型"
description: "经典的评测REST成熟度模型"
gitalk: true
image: "https://lupeier.cn-sh2.ufileos.com/adventure-climb-daylight-1183986.jpg"
author: 陆培尔
tags:
    - Cloud Native
    - RESTful
categories: [ Tech ]
---

> 一个由Leonard Richardson开发的模型将REST架构的主要元素分解为三个层级。 分别是资源，http动词和超媒体控制。

最近我一直在阅读《Rest In Practice》的草稿：一本我的几位同事一直在研究的书。 他们的目的是解释如何使用Restful web services来处理企业面临的许多集成问题。 本书的核心是这样一种观念，即互联网是现实环境中大规模可扩展的分布式系统能够很好工作的有力证明，我们可以从中获取想法，更容易地构建集成系统。
![Figure 1: Steps toward REST](https://upload-images.jianshu.io/upload_images/14871146-37dbf7a0031242ad.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
为了帮助解释一个基于web风格系统的特定属性，作者使用了由[Leonard Richardson](http://www.crummy.com/)开发的一个RESTful成熟度模型，并在Qcon演讲中进行了解释。这个模型是考虑使用这些技术的好方法，所以我想用我自己的话解释一下。（这里的协议示例只是说明性的，我觉得对它们进行编码和测试并不值得，所以细节上可能有问题。）

### Level 0

该模型的出发点是使用HTTP作为远程交互的传输系统，但不使用Web的任何机制。 基本上你在这里做的是使用HTTP作为你自己的远程交互机制的隧道，通常基于远程过程调用（RPC）。
![Figure 2: An example interaction at Level 0](https://upload-images.jianshu.io/upload_images/14871146-f5278c4388d4221e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
现在假设我想预约我的医生。我的预约软件首先需要知道我的医生在某个指定日期有哪些开放时段，所以它向医院预约系统发出请求以获取这些信息。在level 0场景中，医院将在某个URI上公开服务端点。然后我将一个包含有详细请求信息的报文发送到该端点。

```xml
POST /appointmentService HTTP/1.1
[various other headers]

<openSlotRequest date = "2010-01-04" doctor = "mjones"/>
```

然后服务器将返回一个报文，向我提供下述信息

```xml
HTTP/1.1 200 OK
[various headers]

<openSlotList>
  <slot start = "1400" end = "1450">
    <doctor id = "mjones"/>
  </slot>
  <slot start = "1600" end = "1650">
    <doctor id = "mjones"/>
  </slot>
</openSlotList>
```

我在这里使用XML作为示例，但内容实际上可以是任何内容：JSON，YAML，键值对或任何自定义格式。

我的下一步是预约，我可以通过再次将报文发送到该端点进行预约。

```xml
POST /appointmentService HTTP/1.1
[various other headers]

<appointmentRequest>
  <slot doctor = "mjones" start = "1400" end = "1450"/>
  <patient id = "jsmith"/>
</appointmentRequest>
```

如果一切顺利，我会收到回复，说我的预约已被登记。

```xml
HTTP/1.1 200 OK
[various headers]

<appointment>
  <slot doctor = "mjones" start = "1400" end = "1450"/>
  <patient id = "jsmith"/>
</appointment>
```

如果有问题，比如说有人比我捷足先登，那么我会在回复体中收到某种错误消息。

```xml
HTTP/1.1 200 OK
[various headers]

<appointmentRequestFailure>
  <slot doctor = "mjones" start = "1400" end = "1450"/>
  <patient id = "jsmith"/>
  <reason>Slot not available</reason>
</appointmentRequestFailure>
```

到目前为止，这是一个简单的RPC风格系统。 这很简单，因为它只是在前后端传递原始的XML（POX）。 如果您使用SOAP或XML-RPC，它基本上是相同的机制，唯一的区别是您将XML消息包装在某种信封中。

### Level 1 - 资源

在RMM（Richardson Maturity Model）中迈向REST顶点的第一步是引入资源。 现在，我们开始讨论独立资源，而不是将所有请求发送到单一服务端点。
![Figure 3: Level 1 adds resources](https://upload-images.jianshu.io/upload_images/14871146-b7e64e43209bbfde.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
因此，对于我们的初次查询，我们可能会为给定的医生提供资源。

```xml
POST /doctors/mjones HTTP/1.1
[various other headers]

<openSlotRequest date = "2010-01-04"/>
```

回复携带有相同的基本信息，但每个时段现在都是可以单独寻址的资源。

```xml
HTTP/1.1 200 OK
[various headers]


<openSlotList>
  <slot id = "1234" doctor = "mjones" start = "1400" end = "1450"/>
  <slot id = "5678" doctor = "mjones" start = "1600" end = "1650"/>
</openSlotList>
```

使用指定资源进行预约登记意味着请求将发送到对应的时段。

```xml
POST /slots/1234 HTTP/1.1
[various other headers]

<appointmentRequest>
  <patient id = "jsmith"/>
</appointmentRequest>
```

如果一切顺利，我会得到一个和之前类似的回复。

```xml
HTTP/1.1 200 OK
[various headers]

<appointment>
  <slot id = "1234" doctor = "mjones" start = "1400" end = "1450"/>
  <patient id = "jsmith"/>
</appointment>
```

现在的区别在于，如果任何人需要对预约做任何操作，比如预订一些检查，他们首先得到预约资源，可能有一个像`http://royalhope.nhs.uk/slots/1234/appointment`这样的URI ，并发送请求到该资源。

对于像我这样的对象来说，这就像是对象身份的概念。我们不是在网络中调用某个函数并传递参数，而是在一个特定对象上调用一个方法，为其他信息提供参数。

### Level 2 - HTTP动词

我在`Level 0`和`Level 1`的所有交互中都使用了HTTP `POST`这个动词，但有些人使用`GET`代替或者在其他地方使用`GET`。 在上述级别中它没有太大区别，它们都被用作隧道机制，允许您通过HTTP隧道交互。 `Level 2`会避免这种情况，尽量使用HTTP动词从而使得它们接近HTTP原本的使用方式。
![Figure 4: Level 2 addes HTTP verbs](https://upload-images.jianshu.io/upload_images/14871146-a2747ef6e76c1010.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
对于我们的时段列表来说，这意味着我们想要使用`GET`。

```xml
GET /doctors/mjones/slots?date=20100104&status=open HTTP/1.1
Host: royalhope.nhs.uk
```

回复与使用`POST`方法是一样的。

```xml
HTTP/1.1 200 OK
[various headers]

<openSlotList>
  <slot id = "1234" doctor = "mjones" start = "1400" end = "1450"/>
  <slot id = "5678" doctor = "mjones" start = "1600" end = "1650"/>
</openSlotList>
```

在`Level 2`，对这样的请求使用`GET`是至关重要的。 HTTP将`GET`定义为安全操作，即它不会对任何状态进行重大更改。 这允许我们以任意顺序安全地多次调用`GET`，并且每次都获得相同的结果。 这样做的一个重要结果是，它允许任何路由请求的参与者使用缓存，这是使Web工作良好的关键因素。 HTTP包含了各种用于支持缓存的措施，可供通信中的所有参与者使用。 通过遵循HTTP规范，我们可以充分利用该能力。

要完成预约，我们需要一个可以改变状态的HTTP动词，比如`POST`或`PUT`。 我将使用与之前相同的`POST`。

```xml
POST /slots/1234 HTTP/1.1
[various other headers]

<appointmentRequest>
  <patient id = "jsmith"/>
</appointmentRequest>
```

在这里使用`POST`和`PUT`之间的权衡比我想象的要更多，也许我有一天会对它们做一个单独的文章。 但我想指出有些人错误地在POST / PUT和创建/更新之间建立对应关系。 他们之间的选择原则完全不是因为这个。

即使我使用与`Level 1`相同的请求，远程服务的响应方式也存在另一个显著差异。 如果一切顺利，服务将回复201的响应代码，以表明有一个新的资源在这个世界上诞生了。

```xml
HTTP/1.1 201 Created
Location: slots/1234/appointment
[various headers]

<appointment>
  <slot id = "1234" doctor = "mjones" start = "1400" end = "1450"/>
  <patient id = "jsmith"/>
</appointment>
```

201响应包括该URI的`Location`属性，客户端可以使用该URI来获取未来该资源的最新状态。 此处的响应还包括该资源的描述，以便为客户端节省一次额外的请求。

如果出现错误，例如其他人预订了该时段，则还会有另外一个区别。

```xml
HTTP/1.1 409 Conflict
[various headers]

<openSlotList>
  <slot id = "5678" doctor = "mjones" start = "1600" end = "1650"/>
</openSlotList>
```

此响应的重要部分是使用HTTP响应代码来指示出错的地方。 在这种情况下，409似乎是一个很好的选择，表明其他人已经以互斥的方式更新了资源。 在`Level 2`，我们明确使用某种类型的错误响应，而不是使用返回码200但包含错误响应。 通常由接口设计者决定使用哪些代码，但如果出现错误则应该有非2xx响应。 `Level 2`引入了使用HTTP动词和HTTP响应代码。

这里有一个不一致的地方。REST倡导者们在谈论使用所有HTTP动词。他们还说REST正试图从web的事实成功中学习经验，以此来证明他们的说法是正确的。但是，万维网在实践中并没有使用`PUT`或`DELETE`。使用`PUT`和`DELETE`有合理的理由，但是Web的存在并不是其中之一。

支持Web存在的关键要素是安全（例如`GET`）和非安全操作之间的强隔离，以及使用状态代码来帮助传达您遇到的各种错误。

### Level 3 - 超媒体控制

最后一个级别引入了一些您经常听到的与HATEOAS（超文本应用程序状态引擎）这样的丑陋缩写相关的内容。 它解决了如何从列表中获取时段以及知道如何预约的问题。
![Figure 5: Level 3 adds hypermedia controls](https://upload-images.jianshu.io/upload_images/14871146-eea589de3366b519.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
我们从一个与level 2一样的GET请求开始

```xml
GET /doctors/mjones/slots?date=20100104&status=open HTTP/1.1
Host: royalhope.nhs.uk
```

但是响应包含了一个新的元素

```xml
HTTP/1.1 200 OK
[various headers]

<openSlotList>
  <slot id = "1234" doctor = "mjones" start = "1400" end = "1450">
     <link rel = "/linkrels/slot/book" 
           uri = "/slots/1234"/>
  </slot>
  <slot id = "5678" doctor = "mjones" start = "1600" end = "1650">
     <link rel = "/linkrels/slot/book" 
           uri = "/slots/5678"/>
  </slot>
</openSlotList>
```

每个时段现在都有一个link元素，其中包含一个URI，告诉我们如何预约。

超媒体控制的要点是，它们告诉我们下一步可以做什么，以及我们需要操作的资源的URI。我们不必知道把我们的预约请求发送到哪里，响应中的超媒体控制告诉我们如何做。

`POST`请求仍然复制level 2

```xml
POST /slots/1234 HTTP/1.1
[various other headers]

<appointmentRequest>
  <patient id = "jsmith"/>
</appointmentRequest>
```

回复中包含了许多超媒体控制，用于下一步要做的不同事情。

```xml
HTTP/1.1 201 Created
Location: http://royalhope.nhs.uk/slots/1234/appointment
[various headers]

<appointment>
  <slot id = "1234" doctor = "mjones" start = "1400" end = "1450"/>
  <patient id = "jsmith"/>
  <link rel = "/linkrels/appointment/cancel"
        uri = "/slots/1234/appointment"/>
  <link rel = "/linkrels/appointment/addTest"
        uri = "/slots/1234/appointment/tests"/>
  <link rel = "self"
        uri = "/slots/1234/appointment"/>
  <link rel = "/linkrels/appointment/changeTime"
        uri = "/doctors/mjones/slots?date=20100104&status=open"/>
  <link rel = "/linkrels/appointment/updateContactInfo"
        uri = "/patients/jsmith/contactInfo"/>
  <link rel = "/linkrels/help"
        uri = "/help/appointment"/>
</appointment>
```

超媒体控制的一个明显好处是它允许服务端在不破坏客户端的情况下更改其URI方案。 只要客户端查找“addTest”链接URI，服务端团队就可以处理除初始入口点以外的所有URI。

另一个好处是它可以帮助客户端开发人员探索协议。 这些链接为客户端开发人员提供了下一步可能的提示。 它没有提供所有信息：“self”和“cancel”控件都指向同一个URI  - 他们需要弄清楚一个是GET而另一个是DELETE。 但至少它为他们提供了一个起点，可以考虑更多信息以及在协议文档中查找类似的URI。

同样，它允许服务端团队通过在响应中添加新链接来公布新功能。 如果客户端开发人员密切关注未知链接，这些链接可能会成为进一步探索的触发器。

对于如何描述超媒体控制没有绝对的标准。我在这里所做的是使用REST in Practice团队的当前建议，也就是遵循Atom（RFC 4287）规范。我使用一个带有目标URI的uri属性和rel属性的`<link>`元素来描述这种关系。一个众所周知的关系（例如引用元素本身的self）是空的，任何特定于该服务器的关系都是完全限定的URI。Atom指出，已知链接的定义是链接关系的注册表。当我写这些时，它们被限制在ATOM所做的事情上，ATOM通常被视为level 3 restfulness的领导者。

### 级别的意义

我应该强调，RMM虽然是思考REST要素的一种好方法，但它不是REST自身级别的定义。 Roy Fielding明确表示，3级RMM是REST的先决条件。 像软件中的许多术语一样，REST有很多定义，但自从Roy Fielding创造了这个术语以来，他的定义应该比大多数人更权威。

我觉得RMM有用的地方在于它提供了一个很好的step by step的方法来理解restful思想背后的基本理念。 因此，我将其视为帮助我们了解概念的工具，而不是在某种评估机制中应该使用的东西。 我认为我们还没有足够的例子来确定restful方法是整合系统的正确方法，但我确实认为这是一种非常有吸引力的方法，在大多数情况下我会推荐这种方法。

在和Ian Robinson讨论这个问题时，他强调，当Leonard Richardson第一次提出这个模型时，他发现这个模型很有吸引力，因为它与普通的设计技术有着密切的关系。

- Level 1 通过使用“分而治之”来解决处理复杂性问题，将大型服务端点分解为多个资源。
- Level 2 引入了一组标准的动词，以便我们以相同的方式处理类似的情况，去除不必要的变化。
- Level 3 引入了可发现性，提供了一种使协议更具自描述性的方法。

其结果是一个模型，帮助我们思考我们想要提供的HTTP服务的类型，并描绘出希望与其交互的人们的期望。

[原文链接](https://martinfowler.com/articles/richardsonMaturityModel.html)
