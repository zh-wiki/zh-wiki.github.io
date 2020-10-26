---
title: 高通 Camx init 流程
toc: true
date: 2020-01-01 00:00:02
tags: 
---

### 概览

#### Camx-CHI 整体框架如下

<img src="%E9%AB%98%E9%80%9A%20Camx%20init%20%E6%B5%81%E7%A8%8B/image-20201026114544241.png" alt="CAMX-CHI" style="zoom: 67%;" />

其中 camx 代表了通用功能性接口的代码实现集合，chi-cdk代表了可定制化需求的代码实现集合，从图中不难看出camx部分对上作为HAL3接口的实现,对下通过v4l2框架与Kernel保持通讯,中间通过互相dlopen so库并获取对方操作接口的方式保持着与CHI的交互。

camx/中有如下几个主要目录:

- core/ : 用于存放camx的核心实现模块,其中还包含了主要用于实现hal3接口的hal/目录,以及负责与CHI进行交互的chi/目录
- csl/: 用于存放主要负责camx与camera driver的通讯模块,为camx提供了统一的Camera driver控制接口
- hwl/: 用于存放自身具有独立运算能力的硬件node,该部分node受csl管理
- swl/: 用于存放自身并不具有独立运算能力,必须依靠CPU才能实现的node

chi-cdk/中有如下几个主要目录:

- chioverride/: 用于存放CHI实现的核心模块,负责与camx进行交互并且实现了CHI的总体框架以及具体的业务处理。
- bin/: 用于存放平台相关的配置项
- topology/: 用于存放用户自定的Usecase xml配置文件
- node/: 用于存放用户自定义功能的node
- module/: 用于存放不同sensor的配置文件,该部分在初始化sensor的时候需要用到
- tuning/: 用于存放不同场景下的效果参数的配置文件
- sensor/: 用于存放不同sensor的自有信息以及寄存器配置参数
- actuator/: 用于存放不同对焦模块的配置信息
- ois/: 用于存放防抖模块的配置信息
- flash/: 存放着闪光灯模块的配置信息
- eeprom/: 存放着eeprom外部存储模块的配置信息
- fd/: 存放了人脸识别模块的配置信息

### Camx Init 总体概览

通过分析 Camera Provider ，已经知道了上层是如何调到底层的Camera Init 流程，大概框架如下

![Provider INIT](%E9%AB%98%E9%80%9A%20Camx%20init%20%E6%B5%81%E7%A8%8B/image-20201026113612765.png)

接下来我们将按照模块化分析camx的内部初始化流程

![CAMX INIT](%E9%AB%98%E9%80%9A%20Camx%20init%20%E6%B5%81%E7%A8%8B/image-20201026130250068.png)