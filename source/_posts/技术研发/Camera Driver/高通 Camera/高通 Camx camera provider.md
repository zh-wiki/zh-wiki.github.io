---
title: 高通 Camx camera provider
toc: true
date: 2020-01-01 00:00:01
tags: 
---

### Camera Provider

#### 概览

<img src="%E9%AB%98%E9%80%9A%20Camx%20camera%20provider/image-20201021102734471.png" alt="camera provider" style="zoom:80%;" />

通过图片可以看出Camera Provider 分为两部分

- 通过 **HIDL** 与Camera Service 跨进程通信
- 通过 **dlopen** 方式加载一系列动态库 （Camera HAL3结构的so），在高通Camera 是指 camx-chi 架构

#### Provider init 代码流程

![init 代码流程](%E9%AB%98%E9%80%9A%20Camx%20camera%20provider/image-20201021143242020.png)

在系统初始化的时候，系统会去运行"android.hardware.camera.provider@2.4-service_64"程序启动Provider进程，并加入HW Service Manager中接受统一管理。在改过程中实例化一个 LegacyCameraProviderImpl_2_4 对象，通过 hw_get_module 标准方法 获取HAL 模块。这边指的是 **camera.qcom.so** 。

1. LegacyCameraProviderImpl_2_4::initialize() 函数详解

	<details>
	<summary>LegacyCameraProviderImpl_2_4::initialize()</summary>

    ```c++
    // hardware/interfaces/camera/provider/2.4/default/LegacyCameraProviderImpl_2_4.cpp
   bool LegacyCameraProviderImpl_2_4::initialize() {
       camera_module_t *rawModule;
    
    	//获取 camera.qcom.so 可以理解为和 camxhal3entry.cpp 建立联系
       int err = hw_get_module(CAMERA_HARDWARE_MODULE_ID, (const hw_module_t **)&rawModule); 		
    
       //将 camera.qcom.so 获取的句柄保存在 mModule 对象中 ，该函数定义在 CameraModule.cpp 
       mModule = new CameraModule(rawModule);
       
       //我们可以跟进去看看 init() 非常明显 实际就是进行 camx 的初始化，camxhal3entry.cpp  { CAMX:: init()} 
    err = mModule->init();
       
       // 设置回调函数，用于接受camx-chi的数据和事件
    err = mModule->setCallbacks(this);
       
       mNumberOfLegacyCameras = mModule->getNumberOfCameras();
       return false; // mInitFailed
   }
    ```
   
    </details>
   
   init 函数结束之后，Camera Provider进程便一直便存在于系统中,监听着来自Camera Service的调用。