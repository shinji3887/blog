---
title: "protobuf协议介绍及性能实测"
date: 2018-12-03
excerpt: "针对谷歌开源序列化框架protobuf的协议介绍及性能实测"
description: "针对谷歌开源序列化框架protobuf的协议介绍及性能实测"
gitalk: true
image: "https://lupeier.cn-sh2.ufileos.com/bandwidth-close-up-connection-1148820.jpg"
author: L'
tags:
    - Microservice
    - protobuf
categories: [ Tech ]
---
>protobuf是谷歌开源的一款高性能序列化框架，特点是性能优异，数据结构设计优秀并具有良好的可扩展性，并且配合官方的java、python、go、c++的sdk，可以轻松做到跨语言。本文给出protobuf协议的简单介绍以及与其他框架对比的性能测试结果。

### 协议简介

Protocol Buffers 是一种轻便高效的结构化数据存储格式，可以用于结构化数据串行化，或者说序列化。它很适合做数据存储或数据交换格式。可用于通讯协议、数据存储等领域的语言无关、平台无关、可扩展的序列化结构数据格式。你可以理解为另外一种形式的xml，当然protobuf为了追求性能，可读性没有xml或者json那么好，换来的是编码后的报文容量大大缩小以及序列化速度的提高。
要使用使用protobuf，首先需要定义一个.proto格式的文件，格式类似下面这样

```proto
syntax = "proto3";
message Person {
  required string name = 1;
  required int32 id = 2;
  optional string email = 3;

  enum PhoneType {
    MOBILE = 0;
    HOME = 1;
    WORK = 2;
  }
  message PhoneNumber {
    required string number = 1;
    optional PhoneType type = 2 [default = HOME];
  }
  repeated PhoneNumber phone = 4;
}
```

目前有v2和v3两种版本，api会略有不同。
修饰符：

- required : 　不可以增加或删除的字段，必须初始化；
- optional : 　 可选字段，可删除，可以不初始化；
- repeated : 　可重复字段， 对应到java文件里，生成的是List。

更多介绍可参考官网。
执行

```bash
protoc ./message.proto --java_out=./
```

可在当前目录下生成对应对应语言的对象描述代码，这边对应的是java的class文件，再把文件拷贝到项目工程目录内，就可以使用了。（需要下载对应语言的protoc二进制程序）。
这边是一个简单的proto报文生成过程
![timg.jpg](http://lupeier.cn-sh2.ufileos.com/proto.jpg)

大家如果之前用过web service的话，应该会有似曾相识的感觉。这个proto文件，我理解为类似于SOAP的wsdl描述文件，即是一份用来描述数据结构的标准文档说明，各语言的sdk可根据该语言的proto文件生成标准的类文件（是不是想起来了wsdl2java），从而达到跨语言的远程调用（RPC调用）。
然而实际使用中，基于这种模式使用还是比较麻烦，如果对象多了要写一堆proto定义文件，另外生成出来的java对象可读性也比较差，和平时用的pojo有很大不同。本文介绍一种更加方便的使用protobuf的方法，就是protostuff。利用这个框架，可以跳过编写proto文件的步骤，直接生成protobuf格式的报文，接收端也可以直接使用该框架将二进制反序列化为Object对象，用到的就是我们平时使用的普通的java对象。利用Protostuff-Runtime模块可以不需要静态编译protoc，只要在runtime的时候传入schema就可以了。下面就来实操一下
首先引入maven依赖

```xml
<dependency>
       <groupId>io.protostuff</groupId>
       <artifactId>protostuff-core</artifactId>
       <version>1.6.0</version>
</dependency>
<dependency>
       <groupId>io.protostuff</groupId>
       <artifactId>protostuff-runtime</artifactId>
       <version>1.6.0</version>
</dependency>
```

编写java对象，这边为了测试写了一个比较复杂的属性带一个循环列表的对象

```java
package com.bocsh.proto;

import java.util.List;

public class User {

	private String id;

    private String name;

    private Integer age;

    private String desc;
    
    private List<Role> roleList;

   //setter getter  略..
	@Override
    public String toString() {
        return "name=" + name + ",id=" + id + ",age=" + age + 
        		",role1=" + roleList.get(0).getId() + 
        		",role2=" + roleList.get(1).getId();
    }

}
```

```java
package com.bocsh.proto;

public class Role {
	
    private String id;

    private String name;

    private String desc;

    //setter getter  略..

}
```

编写测试类进行测试

```java
public class ProtoBufUtilTest {
	 
    public static void main(String[] args) throws Exception {
 
        User user = new User();
        user.setAge(300);
        user.setDesc("备注");
        user.setName("张三");
        user.setId("HO123");
        
        List<Role> list = new ArrayList<Role>();
        for(int i=1;i<=2;i++) {
        	Role role = new Role();
            role.setId("R" + Integer.toString(i));
            role.setName("经办");
            list.add(role);
        }
        
        user.setRoleList(list);
        
        //protobuf序列化
        long proto1 = (new Date()).getTime();
        LinkedBuffer buffer = LinkedBuffer.allocate(LinkedBuffer.DEFAULT_BUFFER_SIZE);
        Schema<User> schema = RuntimeSchema.getSchema(User.class);
        ProtobufIOUtil.toByteArray(user, schema, buffer);
        byte[] serializerResult = ProtoBufUtil.serializer(user);
 
        System.out.println("protobuf序列化二进制:" + bytes2hex(serializerResult));
        System.out.println("protobuf序列化ascii:" + new String(serializerResult));
        System.out.println("protobuf序列化字节长度:" + serializerResult.length);
        User protouser = new User();
        ProtobufIOUtil.mergeFrom(serializerResult, protouser, schema);
 
        long proto2 = (new Date()).getTime();
        System.out.println("protobuf反序列化结果:" + protouser);
        System.out.println("protobuf序列化耗时:" + (proto2 - proto1));
        
    }
 
}
```

运行后结果如下

```bash
protobuf序列化二进制:0A 05 48 4F 31 32 33 12 06 E5 BC A0 E4 B8 89 18 AC 02 22 06 E5 A4 87 E6 B3 A8 2A 0C 0A 02 52 31 12 06 E7 BB 8F E5 8A 9E 2A 0C 0A 02 52 32 12 06 E7 BB 8F E5 8A 9E 
protobuf序列化ascii:
HO123张三�"备注*
R1经办*
R2经办
protobuf序列化字节长度:54
protobuf反序列化结果:name=张三,id=HO123,age=300,role1=R1,role2=R2
protobuf序列化耗时:185
```

protobuf报文在实际传输中是以二进制方式传输的，这里为了方便分析，我把它专成了ascii字符。可以看到，protobuf的压缩效率非常高，除了基本的字段内容之外，其他的标签之类的全部都压缩了，以二进制方式存储，所以它的报文格式会比xml小非常多，当然代价就是可读性没有那么友好，这也是为什么谷歌要定义proto文件的原因。在没有这个文件的情况下，你几乎不可能看懂这个报文所表示的数据结构。

### 性能测试

说了那么多，现在来看看实际protobuf能为我们带来多少传输报文的性能提升。这里我选取了目前日常使用最普遍的XML以及json格式，这两个是文本形式的序列化框架，以及hessian2，这个是老牌的二进制序列化框架，也是dubbo里默认的序列化方案。几种格式都可以做到跨语言，现在我们来看看他们的性能差距到底有多少。

#### 测试基准环境：

- 硬件资源：macbook pro 笔记本(2012 late,core i5 2.5GHz,8G内存）
- java版本：jdk1.8
- protobuf序列化框架：protostuff
- xml序列化框架：jdk原生jaxb
- json序列化框架：fastjson
- hessian序列化框架：hessian

#### 测试方法

将`List<Role>`循环多次，模拟不同的报文size大小，以此测试序列化框架的性能。

Round 1:`size=10`

```bash
protobuf序列化字节长度:167
protobuf反序列化结果:name=张三,id=HO123,age=300,role1=R1,role2=R2
protobuf序列化耗时:196

xml序列化字节长度:645
xml反序列化结果:name=张三,id=HO123,age=300,role1=R1,role2=R2
xml序列化耗时:149

json序列化字节长度:350
json反序列化结果:name=张三,id=HO123,age=300,role1=R1,role2=R2
json序列化耗时:223

hessian2序列化字节长度:690
hessian2反序列化结果:name=张三,id=HO123,age=300,role1=R1,role2=R2
hessian2序列化耗时:63
```

可以看出在数据量很小的情况，几个框架的性能差别不大，hessian2最好，xml甚至比protobuf还要高一些。但是有一个地方需要注意，就是序列化后的字节长度，json是xml的大概1/2多一点，而protobuf只有xml的1/4，而hessian甚至比xml还要长。这在存储敏感或者带宽敏感的场景下是至关重要的。之后的所有测试存储所占空间的比例基本都是一样。

Roune2:`size=1000`

```bash
protobuf序列化字节长度:15919
protobuf反序列化结果:name=张三,id=HO123,age=300,role1=R1,role2=R2
protobuf序列化耗时:211

xml序列化字节长度:53027
xml反序列化结果:name=张三,id=HO123,age=300,role1=R1,role2=R2
xml序列化耗时:256

json序列化字节长度:29962
json反序列化结果:name=张三,id=HO123,age=300,role1=R1,role2=R2
json序列化耗时:249

hessian2序列化字节长度:60992
hessian2反序列化结果:name=张三,id=HO123,age=300,role1=R1,role2=R2
hessian2序列化耗时:114
```

当数据量来到1000这个量级，仍然是hessian一马当先，可以看到protobuf已经反超xml了，这时候json的性能也已经超过xml，xml的劣势开始渐渐显现。

Round3:`size=100000`

```bash
protobuf序列化字节长度:1788921
protobuf反序列化结果:name=张三,id=HO123,age=300,role1=R1,role2=R2
protobuf序列化耗时:333

xml序列化字节长度:5489029
xml反序列化结果:name=张三,id=HO123,age=300,role1=R1,role2=R2
xml序列化耗时:1059

json序列化字节长度:3188964
json反序列化结果:name=张三,id=HO123,age=300,role1=R1,role2=R2
json序列化耗时:726

hessian2序列化字节长度:6288994
hessian2反序列化结果:name=张三,id=HO123,age=300,role1=R1,role2=R2
hessian2序列化耗时:785

```

来到10万这个量级，protobuf反超！而且优势非常明显，几乎是xml性能的3倍，hessian的2倍，序列化后的字节大小为1.7M左右，xml的1/4

Round4:`size=1000000`

```bash
protobuf序列化字节长度:18888922
protobuf反序列化结果:name=张三,id=HO123,age=300,role1=R1,role2=R2
protobuf序列化耗时:2405

xml序列化字节长度:55889030
xml反序列化结果:name=张三,id=HO123,age=300,role1=R1,role2=R2
xml序列化耗时:4087

json序列化字节长度:32888965
json反序列化结果:name=张三,id=HO123,age=300,role1=R1,role2=R2
json序列化耗时:3063

hessian2序列化字节长度:63888995
hessian2反序列化结果:name=张三,id=HO123,age=300,role1=R1,role2=R2
hessian2序列化耗时:4747
```

数据量为100万条，此时protobuf的报文数据大小为18M，xml已经达到了55M，json也有33M，hessian更是到了64M，protobuf的速度仍然是xml的差不多两倍。这里比较诡异的是json在好几次测试中耗时只有1000多ms，但多测几次又会变回3000多ms，从生成的字节码来看，3000ms是比较合理的结果，不知道是做了什么样子的优化。

### 结论

在报文数据量很小的情况，几种格式差别不是很大，建议都可以选择。如果对于报文解析性能要求很高，报文体积小的情况下可以选择hessian，体积大选protobuf。如果需要文本格式，选择json。如果对于存储或者带宽敏感，建议选择protobuf，体积比其他几种格式小太多，传输或者存储都很方便。

### 补充说明

看了protobuf的官方文档，感觉protobuf的性能还有提高的空间，就用原生的protobuf测试了一下，静态编译了`user.proto`文件，测试结果如下

```bash
数据量大小:10
原生protobuf序列化字节长度:167
原生protobuf序列化耗时:54

数据量大小:1000
原生protobuf序列化字节长度:15919
原生protobuf序列化耗时:86

数据量大小:100000
原生protobuf序列化字节长度:1788921
原生protobuf序列化耗时:289

数据量大小:1000000
原生protobuf序列化字节长度:18888922
原生protobuf序列化耗时:2371
```

可以看出性能有了很大的提高，在各阶段的测试中都是最快的。对比编码后的字节数，和protostuff是完全一致的，说明两种框架最终出来的结果是一样的，但是原生的protobuf要快了很多，看来果然鱼和熊掌不可兼得，运行时的编译对于性能相比静态编译还是有相当的损耗的。在小于1000的数据量级，两者的性能差距差不多有3倍。对于极致追求性能的场景，还是建议使用原生的protobuf。当然本次测试结果还没有达到官方宣称的比xml要快20～100倍这个数量级，这个估计需要C++或者go的环境下才能实现，留给其他同学进行测试了。

[测试用到的github代码地址](https://github.com/shinji3887/protobuftest)
