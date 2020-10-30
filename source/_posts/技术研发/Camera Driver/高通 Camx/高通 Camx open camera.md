---
title: 高通 Camx Camx open camera
toc: true
date: 2020-01-01 00:00:03
tags: 
---

# Open Camera 的流程简介

当用户打开了相机设备之后，便会发生如下过程：

1. APP调用CameraManager的openCamera方法，层层调用之后最终调用到Camera Service层中的CameraService::connectDevice方法
2. 过ICameraDevice::open()这一个HIDL接口通知Camera Provider层
3. 在Camera Provider层内部又通过调用之前获取的camera_module_t中methods的open方法来获取一个Camera 设备，对应于HAL中的camera3_device_t结构体
4. 在Camera Provider层调用获取到的camera3_device_t的initialize方法进行初始化动作

代码大概流程走向

```c++
//APP 端 open Camera
CameraManager::openCamera() 
    
```

