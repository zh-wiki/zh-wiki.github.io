---
title: ADB 常用命令
toc: true
date: 2020-01-01 00:00:00
tags:
---

## 高通平台 Camera 相关

### 高通 Camx 杀死 camera 进程

```bash
adb shell ps -A|grep camera |awk '{print $2}'|xargs adb shell kill -9
```

由命令引发的知识:

1. awk 命令的介绍

   ```bash
   awk '{print $2}'
   ```

   这个命令会把 **ps -A | grep camera** 得出的进程id 输出到终端 （$2 是第二字段也就是 进程id）

   <img src="ADB%20%E5%B8%B8%E7%94%A8%E5%91%BD%E4%BB%A4/image-20201016145122015.png" alt="例图" style="zoom:200%;" />    

2. xargs 命令介绍

   ```bash
   xargs adb shell kill -9
   ```

   这个命令会把 awk 获取到的线程id 当做参数传递给 **kill -9** 这个命令

### 高通 Camx dump metadata 

```bash
adb shell dumpsys media.camera >meta.log   
```

