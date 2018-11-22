---
title: "使用ThreadPoolTaskExecutor对任务进行异步阻塞处理"
date: 2018-11-19
excerpt: "java多线程处理"
description: "java多线程处理"
gitalk: true
author: L'
tags:
    - java
categories: [ Tips ]
---

最近项目中要用到多线程处理任务，自然就用到了ThreadPoolTaskExecutor这个对象，这个是spring对于Java的concurrent包下的ThreadPoolExecutor类的封装，对于超出等待队列大小的任务默认是使用RejectedExecutionHandler去处理拒绝的任务，而这个Handler的默认策略是AbortPolicy，直接抛出RejectedExecutionException异常，这个不符合我们的业务场景，我希望是对于超出的任务，主线程进行阻塞，直到有可用线程，简单的代码如下
```java
ThreadPoolTaskExecutor taskExecutor = new ThreadPoolTaskExecutor();
//默认线程池建立的线程数，当多余的线程处于空闲状态时，大于这个数字的线程会自动销毁
taskExecutor.setCorePoolSize(10);
//最大的线程数
taskExecutor.setMaxPoolSize(10);
//等待队列数，这里为了测试方便设置为0，实际可根据具体场景设置
taskExecutor.setQueueCapacity(0);
taskExecutor.setRejectedExecutionHandler(new RejectedExecutionHandler() {
    @Override
    public void rejectedExecution(Runnable r, ThreadPoolExecutor executor) {
        if (!executor.isShutdown()) {
            try {
                log.info("start get queue");
                executor.getQueue().put(r);
                log.info("end get queue");
            } catch (InterruptedException e) {
                log.error(e.toString(), e);
                Thread.currentThread().interrupt();
            }
        }
    }
}
);
taskExecutor.initialize();

for (int i = 0; i < 100; i++) {
    final int index = i;
    taskExecutor.execute(new Runnable() {
  
        @Override
        public void run() {
            try {
                log.info("thread start " + index);
                Thread.sleep(200000);
                log.info("thread end " + index);
            } catch (InterruptedException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }
        }
    });
}
```
结果输出：
```sh
INFO  2018-11-15 12:41:00,115 [scheduler-ssmQuartz_Worker-1] org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor: Initializing ExecutorService 
INFO  2018-11-15 12:41:00,116 [ThreadPoolTaskExecutor-1] com.bocsh.base.quartz.TimingCardUpdate: thread start 0
INFO  2018-11-15 12:41:00,116 [ThreadPoolTaskExecutor-2] com.bocsh.base.quartz.TimingCardUpdate: thread start 1
INFO  2018-11-15 12:41:00,116 [ThreadPoolTaskExecutor-3] com.bocsh.base.quartz.TimingCardUpdate: thread start 2
INFO  2018-11-15 12:41:00,116 [ThreadPoolTaskExecutor-4] com.bocsh.base.quartz.TimingCardUpdate: thread start 3
INFO  2018-11-15 12:41:00,116 [ThreadPoolTaskExecutor-5] com.bocsh.base.quartz.TimingCardUpdate: thread start 4
INFO  2018-11-15 12:41:00,117 [ThreadPoolTaskExecutor-6] com.bocsh.base.quartz.TimingCardUpdate: thread start 5
INFO  2018-11-15 12:41:00,117 [ThreadPoolTaskExecutor-7] com.bocsh.base.quartz.TimingCardUpdate: thread start 6
INFO  2018-11-15 12:41:00,117 [ThreadPoolTaskExecutor-9] com.bocsh.base.quartz.TimingCardUpdate: thread start 8
INFO  2018-11-15 12:41:00,117 [scheduler-ssmQuartz_Worker-1] com.bocsh.base.quartz.TimingCardUpdate: start get queue
INFO  2018-11-15 12:41:00,117 [ThreadPoolTaskExecutor-8] com.bocsh.base.quartz.TimingCardUpdate: thread start 7
INFO  2018-11-15 12:41:00,117 [ThreadPoolTaskExecutor-10] com.bocsh.base.quartz.TimingCardUpdate: thread start 9
INFO  2018-11-15 12:44:20,116 [ThreadPoolTaskExecutor-4] com.bocsh.base.quartz.TimingCardUpdate: thread end 3
INFO  2018-11-15 12:44:20,116 [ThreadPoolTaskExecutor-2] com.bocsh.base.quartz.TimingCardUpdate: thread end 1
INFO  2018-11-15 12:44:20,116 [ThreadPoolTaskExecutor-4] com.bocsh.base.quartz.TimingCardUpdate: thread start 10
INFO  2018-11-15 12:44:20,116 [ThreadPoolTaskExecutor-3] com.bocsh.base.quartz.TimingCardUpdate: thread end 2
INFO  2018-11-15 12:44:20,116 [ThreadPoolTaskExecutor-1] com.bocsh.base.quartz.TimingCardUpdate: thread end 0
INFO  2018-11-15 12:44:20,116 [scheduler-ssmQuartz_Worker-1] com.bocsh.base.quartz.TimingCardUpdate: end get queue
INFO  2018-11-15 12:44:20,117 [ThreadPoolTaskExecutor-1] com.bocsh.base.quartz.TimingCardUpdate: thread start 11
INFO  2018-11-15 12:44:20,117 [ThreadPoolTaskExecutor-6] com.bocsh.base.quartz.TimingCardUpdate: thread end 5
INFO  2018-11-15 12:44:20,117 [ThreadPoolTaskExecutor-5] com.bocsh.base.quartz.TimingCardUpdate: thread end 4
INFO  2018-11-15 12:44:20,117 [ThreadPoolTaskExecutor-7] com.bocsh.base.quartz.TimingCardUpdate: thread end 6
INFO  2018-11-15 12:44:20,117 [ThreadPoolTaskExecutor-9] com.bocsh.base.quartz.TimingCardUpdate: thread end 8
INFO  2018-11-15 12:44:20,117 [ThreadPoolTaskExecutor-10] com.bocsh.base.quartz.TimingCardUpdate: thread end 9
INFO  2018-11-15 12:44:20,117 [ThreadPoolTaskExecutor-8] com.bocsh.base.quartz.TimingCardUpdate: thread end 7
INFO  2018-11-15 12:44:20,117 [ThreadPoolTaskExecutor-3] com.bocsh.base.quartz.TimingCardUpdate: thread start 12
INFO  2018-11-15 12:44:20,117 [ThreadPoolTaskExecutor-2] com.bocsh.base.quartz.TimingCardUpdate: thread start 13
INFO  2018-11-15 12:44:20,117 [scheduler-ssmQuartz_Worker-1] com.bocsh.base.quartz.TimingCardUpdate: start get queue
INFO  2018-11-15 12:44:20,120 [scheduler-ssmQuartz_Worker-1] com.bocsh.base.quartz.TimingCardUpdate: end get queue
INFO  2018-11-15 12:44:20,120 [ThreadPoolTaskExecutor-8] com.bocsh.base.quartz.TimingCardUpdate: thread start 14
INFO  2018-11-15 12:44:20,120 [ThreadPoolTaskExecutor-10] com.bocsh.base.quartz.TimingCardUpdate: thread start 15
INFO  2018-11-15 12:44:20,120 [ThreadPoolTaskExecutor-5] com.bocsh.base.quartz.TimingCardUpdate: thread start 18
INFO  2018-11-15 12:44:20,120 [ThreadPoolTaskExecutor-7] com.bocsh.base.quartz.TimingCardUpdate: thread start 17
INFO  2018-11-15 12:44:20,120 [ThreadPoolTaskExecutor-9] com.bocsh.base.quartz.TimingCardUpdate: thread start 16
INFO  2018-11-15 12:44:20,120 [scheduler-ssmQuartz_Worker-1] com.bocsh.base.quartz.TimingCardUpdate: start get queue
INFO  2018-11-15 12:44:20,120 [ThreadPoolTaskExecutor-6] com.bocsh.base.quartz.TimingCardUpdate: thread start 19
```
可以看到，在任务超过线程池大小后，start get queue后会阻塞。
这里之所以能实现阻塞，是基于BlockingQueue的put方法来实现的，当阻塞队列满时，put方法会一直等待

参考文章： [让Java线程池实现任务阻塞执行的一种可行方案](https://www.cnblogs.com/chenpi/p/8987597.html)
