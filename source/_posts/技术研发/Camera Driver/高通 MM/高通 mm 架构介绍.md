---
title: 高通 mm 架构介绍
toc: true
date: 2020-00-00 00:00:00
tags: 高通 mm 
---

# Camera Buf 流转

------

## QCamera3 层数据流

1. 在 **configureStreamsPerfLocked** 的时候new了一系列的数据通道，用来管理stream.

2. 在 **processCaptureRequest** 的时候 ,主要做了3件事情：ChannelInit , ChannelStart, ChannelRequest

   - **`INIT Channel`**

     给数据通道进行 **add_stream** , 给下层传递两个重要的回调。

     将 **QCamera3Stream::dataNotifyCB()** 传递给mm层 ，mm层调用该回调将数据传递给 QCamera3Stream层

     将 **streamCbRoutine** 回调传递给 QcameraStream 层，用于将数据返回给 QCameraChannel 层

   - **`START Channel`**

     启动一个 线程函数 **QCamera3Stream::dataProcRoutine()** 监听CMD进行数据处理，调用 **mDataCB** (Channel层的 **streamRotation**)

3. 当mm层get到数据会调用 **dataNotifyCB()** ,该函数通过调用 **QCamera3Stream::processDataNotify()**  给 **dataProcRoutine()** 线程函数发送命令

## MM 层数据流

1. 在mm层主要是围绕两个线程进行流转

   **mm_camera_cmd_thread_launch()**

   **mm_camera_poll_thread_launch()**

2. 在QCamera3中，进行初始化的Channel的时候，会**add_stream**和**config_stream** , 在config的过程中 **mm_stream_config()** 会将上层传下来的回调进行映射。

3. **mm_camera_poll_thread_launch** 获取到 **MM_CAMERA_POLL_TYPE_DATA** 事件，会去判断是否有数据回调函数。(**mm_stream_data_notify**)

   在这个函数主要进行读数据，读完数据创建线程命令 **MM_CAMERA_CMD_TYPE_DATA_CB** ，最终调用 **mm_stream_dispatch_app_data()** 将数据上传。
   

# 高通camera daemon进程

------

## Media Controller 线程分析











------

> **博客推荐**
>
> https://www.jianshu.com/p/ecb1be82e6a8
>
> https://www.jianshu.com/p/1baad2a5281d
>
> https://wenku.baidu.com/view/3b408a6159fb770bf78a6529647d27284b733702.html