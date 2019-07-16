---
title: "Git的代码分支策略实践"
date: 2018-11-26
excerpt: "基于git的工作流方案实践"
description: "基于git的工作流方案实践"
gitalk: true
image: "https://lupeier.cn-sh2.ufileos.com/blur-brainstorming-chatting-1881333.jpg"
author: L'
tags:
    - Git
    - DevOps
categories: [ Tech ]
---

>目前主流的git工作流模式有git flow、github flow、gitlab flow这几种，采用不同的代码分支策略，意味着实施不同的代码集成与上线流程，这会影响整个研发团队每日的协作方式，因此研发团队通常需要认真的选择适合自己的分支策略。

对于Git flow的工作流程，可以参考下面这篇（我个人比较推崇阮老师的博客，里面干货很多）
[Git工作流程-阮一峰的博客](http://www.ruanyifeng.com/blog/2015/12/git-workflow.html)

这篇是gitlab的CEO Sytse Sijbrandij写的一篇关于gitlab flow的blog，里面其实三种策略都有写到，并总结了优缺点，官方推荐
[GitLab Flow](https://about.gitlab.com/2014/09/29/gitlab-flow/)

这篇是上面那篇gitlab flow博客的中文翻译，翻的很不错，英文不好的可以直接看这篇
[GitLab Flow的使用](http://www.15yan.com/topic/yi-dong-kai-fa-na-dian-shi/6yueHxcgD9Z/)

代码管理策略主要有主干开发和功能分支开发这两种，功能分支开发又分为以下几种主流模型，几种模型各有所长，下面简述一下

* git flow：出现时间最早，基于git的workflow的开山鼻祖，可以说给出了一个git flow的最佳实践，缺点是流程比较复杂，release branch和hotfix branch几乎没人使用，另外需要长期维护master和dev两个分支，在规模不大的场景下维护成本比较高
* github flow：相当精简，只有master主干和feature branch这两种，结构相当清晰，缺点是master默认为当前上线的最新版本，在对于版本管理要求比较复杂的场景下灵活性不足
* gitlab flow：出现的最晚，可以说集合了前两家的长处，既保证只有一个长期主干，结构清晰，同时也定义了不同场景下的branch，增强了灵活性。

像谷歌、脸书这样的互联网大咖，现在采用的都是主干开发模式，即只有一个master主干，所有的代码合并都在主干上完成，优点是结构清晰，特别适合快速的CI/CD流程，但是对于团队的技术能力要求非常高。目前国内的互联网公司，一般都采用功能分支（feature branch）的开发模式，在开发人员能力良莠不齐的情况下，相对来说对于代码的掌控能力比较好。
对于几种模式的使用场景，如下表所列：（列表来源：极客时间王潇俊的持续交付专题）
| 序号 | 情况 | 适合的分支策略 |
| ------ | ------ | ------ |
| 1 | 开发团队能力很强，需要快速的CI/CD能力 | 主干开发 |
| 2 | 有预定的发布周期，需要执行严格的发布流程 | Git Flow |
| 3 | 随时集成随时发布，分支merge后经过评审就可以自动发布 | Github Flow |
| 4 | 无法控制准确的发布时间，但又要求不停集成 | Gitlab Flow（带生产分支） |
| 5 | 需要逐个通过各个测试环境验证 | Gitlab Flow（带环境分支） |
| 6 | 需要对外发布和维护不同版本 | Git Flow（带版本分支） |

其实不管是选择哪种分支策略，都是基于Feature Driven Development（FDD）原则进行项目管理，既先要有issue（需求）输入，建立对应的功能分支（feature branch）再进行代码开发，完成之后合入主干，同时删除该功能分支。
个人认为对于中小型的团队来说，github flow已经足够完成需求，并且由于微服务架构的流行，一般工程都已经按照服务进行拆分，每个服务一个repo，需要同时进行复杂版本管理的场景不是很多。而现在一般在内网部署都是采取gitlab，所以下面就来说说怎么在gitlab里实施github flow（听起来有点绕口-__-）

1.repo的maintainer在issue上创建问题（新功能或者bug fix），指定issue的接收人或者由团队成员自己认领，并创建对应的feature branch，这点gitlab比较强大，可以自动创建issue对应的功能分支，github好像没有这个功能，需要开发人员手工创建并关联到issue
![git.png](https://upload-images.jianshu.io/upload_images/14871146-5b602ddf4e2af565.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

2.负责处理的issue的同事Bob checkout这个特性分支（首次开发的话也可以clone这个仓库并切换到该功能分支）,注意本地的分支名字需要和远程保持一致，否则push的时候会有问题

```bash
I:\msaworkspace\bocsh-service-base>git checkout -b 1-test-issue origin/1-test-issue
Switched to a new branch '1-test-issue'
Branch '1-test-issue' set up to track remote branch '1-test-issue' from 'origin'.
```

使用`git branch`查看，发现已经checkout成功并切换到`1-test-issue`这个分支上了,并且本地的`1-test-issue`和远程仓库的`1-test-issue`分支已经建立了追踪关系

```bash
I:\msaworkspace\bocsh-service-base>git branch
* 1/test/issue
  master
```

3.Bob在特性分支上进行工作，并每日push代码

```bash
I:\msaworkspace\bocsh-service-base>git commit -am "test issue track"
[1-test-issue 08972ca] test issue track
 1 file changed, 1 insertion(+)

I:\msaworkspace\bocsh-service-base>git push
Enumerating objects: 17, done.
Counting objects: 100% (17/17), done.
Delta compression using up to 4 threads
Compressing objects: 100% (6/6), done.
Writing objects: 100% (9/9), 632 bytes | 316.00 KiB/s, done.
Total 9 (delta 3), reused 0 (delta 0)
remote:
remote: To create a merge request for 1-test-issue, visit:
remote:   http://22.196.66.28/7310754/bocsh-service-base/merge_requests/new?merge_request%5Bsource_branch%5D=1-test-issue
remote:
To http://22.196.66.28/7310754/bocsh-service-base.git
   498d77f..08972ca  1-test-issue -> 1-test-issue
```

这边注意Bob直接使用了git commit -am参数
这个相当于

```bash
git add .
git commit -m
```

同时因为指定了跟踪关系，所以可以直接用`git push`命令进行推送，git会自动把当前的活动分支的代码push到远程的对应分支上去（还记得前面说的建立对应跟踪关系吗），同时git提示我们可以create a merge request去申请把1-test-issue分支合并入master主干
同时项目管理人员（一般是这个repo的owner或者maintainer）还可以通过点击issue页面对应的分支，查看该分支是否被认领，以及该分支的工作进度（Bob，你有木有每天认真干活啊）
![git2.png](https://upload-images.jianshu.io/upload_images/14871146-6b35c7f6fe3ee892.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![git3.png](https://upload-images.jianshu.io/upload_images/14871146-eab127d1b97e7421.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

4.Bob认为功能完成并本地测试通过，在gitlab页面上提交一个merge request
![git4.png](https://upload-images.jianshu.io/upload_images/14871146-47dc489b9013fea6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
title这边填写本次MR的标题，description这边填写主要提交的内容，注意必须要包含Closes #1关键字，这样在merge成功后会自动关系关联的issue（gitlab真的很方便，github里面这些都是要自己手写的）

![git5.png](https://upload-images.jianshu.io/upload_images/14871146-b45ae2f86db166fb.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
这里的选项可以指定审核人，给MR打标签等等操作，注意有两个选项

* Remove source branch when merge request is accepted.
这个会在合并成功后自动删除对应的功能分支
* Squash commits when merge request is accepted.

在合并后自动创建一个commit节点，因为git的合并有两种模式，快进模式只会直接改变HEAD指针的位置，不会创建commit id，这边为了流程清晰还是建议创建一个commit id
4.maintainer审查代码，确认ok后将合并入master，同时删除该特性分支，并根据#close这样的关键字自动关闭issue
![git6.png](https://upload-images.jianshu.io/upload_images/14871146-836f7827a5da2da4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
如果项目集成了gitlab ci的话，这边还能看到持续集成的结果，从上面的页面看到持续集成pipeline的测试和构建也都通过了，点击change选项卡可以查看改动的地方，审核无误后点击merge按钮就可以合并入master了
![git7.png](https://upload-images.jianshu.io/upload_images/14871146-3a8df01e059ac82d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
这边看到已经成功合并入主干，同时这个特性分支也自动删除，并且自动关闭了关联的issue

5.如果是准备上线的版本，那在合并成功后还需要打tag，以便于版本的追踪，我们这边设置为1.0版本
![git8.png](https://upload-images.jianshu.io/upload_images/14871146-d73935f9933b7dc0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
版本打成功后，在tag页面可以看到历史版本记录以及对应的commit id
![git9.png](https://upload-images.jianshu.io/upload_images/14871146-a4ebf3e430acc942.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

总结：基于issue的项目管理（FDD），非常便于项目的跟踪和代码审核、版本历史检索等，中小型团队建议实施github flow工作流模型。
