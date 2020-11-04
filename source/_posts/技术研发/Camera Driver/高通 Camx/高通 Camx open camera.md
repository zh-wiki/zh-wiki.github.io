---
title: 高通 Camx Camx open camera
toc: true
date: 2020-01-01 00:00:03
tags: 
---

# Open Camera 的流程简介

当用户打开了相机设备之后，便会发生如下过程：

1. APP调用CameraManager的openCamera方法，层层调用之后最终调用到Camera Service层中的CameraService::connectDevice方法
2. 然后通过ICameraDevice::open()这一个HIDL接口通知Camera Provider层
3. 在Camera Provider层内部又通过调用之前获取的camera_module_t中methods的open方法来获取一个Camera 设备，对应于HAL中的camera3_device_t结构体
4. 在Camera Provider层调用获取到的camera3_device_t的initialize方法进行初始化动作

代码大概流程走向

```c++
//APP 端 open Camera
CameraManager::openCamera() 
    //Camera Server
    CameraService::connectDevice()
    	//通过HIDL接口
    	ICameraDevice::open()
    		//camera provider
    		camera_module_t::methods::open()
    			//接下来就是进行一些初始化操作
    	 		camera3_device_t::initialize()
```

# APP Open Camera 流程

App端主要做了以下几点工作

1. 获取 CameraManager 服务

2. 打开指定的 Camera
   - 获取 Camera Server
   - 调用 cameraService.connectDevice() 去连接打开设备，并且将上层传下来的回调传入Camera Server
   - 返回Device给App端

```c++
//apk端获取CameraManager 服务
mCamManager = (CameraManager)getSystemService(Context.CAMERA_SERVICE);  
//打开指定camera
--> mCamManager.openCamera(mCameraId, mStateCallback, null);    
//frameworks/base/core/java/android/hardware/camera2/CameraManager.java
public void openCamera(@NonNull String cameraId, @NonNull @CallbackExecutor Executor executor, @NonNull final CameraDevice.StateCallback callback)
   |--> openCameraForUid(cameraId, callback, executor, USE_CALLING_UID)
   |   |--> openCameraDeviceUserAsync(cameraId, callback, executor, clientUid);
   |   |   |--> CameraDevice device = null; //初始化CameraDevice
   |   |   | //实例化　new android.hardware.camera2.impl.CameraDeviceImpl
   |   |   |--> android.hardware.camera2.impl.CameraDeviceImpl deviceImpl = new android.hardware.camera2.impl.CameraDeviceImpl(...) 
   |   |   |--> ICameraDeviceCallbacks callbacks = deviceImpl.getCallbacks();   //获取回调
   |   |   |--> ICameraService cameraService = CameraManagerGlobal.get().getCameraService();    //获取CameraService 服务
   |   |   |--> cameraUser = cameraService.connectDevice(callbacks, cameraId, mContext.getOpPackageName(), uid);    //连接打开camera
   |   |   |--> goto CONNECTDEVICE:    //跳转到下面CONNECTDEVICE处进行分析
   |   |   |--> deviceImpl.setRemoteDevice(cameraUser);
   |   |   |   |--> mRemoteDevice = new ICameraDeviceUserWrapper(remoteDevice);
   |   |   |   |--> mDeviceExecutor.execute(mCallOnOpened); //这里是一个线程池
   |   |   |   |   |--> sessionCallback = mSessionStateCallback;    //获取session cb
   |   |   |   |   |--> sessionCallback.onOpened(CameraDeviceImpl.this);    //通过session cb 返回device
   |   |   |   |   |--> mDeviceCallback.onOpened(CameraDeviceImpl.this);    //通过device cb 返回device,这里就是返回给apk端的CameraDevice了
```

# Camera Server Open 流程

对于打开相机设备动作,主要由connectDevice来实现，当CameraFramework通过调用ICameraService的connectDevice接口的时候,主要做了两件事情：

- 创建CameraDeviceClient。
- 对CameraDeviceClient进行初始化,并将其返回给Framework。

##  创建 CameraDevcieClient

CameraDeviceClient 该类在打开设备的时候被实例化，一次打开设备的操作对应一个该类对象，它实现了ICameraDeviceUser接口，以AIDL方式暴露接口给Camera Framework进行调用，于此同时,该类在打开设备的过程中，获取了来自Camera Framework对于ICameraDeviceCallback接口的实现代理，通过该代理可以将结果上传至Camera Framewor中。我个人的理解其实这个类就是 framework 与 Camera 的通信入口。

代码流程如下：

- 首先实例化一个CameraDeviceClient
- 将来自Framework针对ICameraDeviceCallback的实现存入CameraDeviceClient中，一旦有结果产生便可以将结果通过这个回调回传给Framework

```c++
//frameworks/av/services/camera/libcameraservice/CameraService.cpp
Status CameraService::connectDevice(const sp<hardware::camera2::ICameraDeviceCallbacks>& cameraCb, const String16& cameraId, const String16& clientPackageName, int clientUid, sp<hardware::camera2::ICameraDeviceUser>* device) //最后一个参数是返回值
   |--> connectHelper<hardware::camera2::ICameraDeviceCallbacks,CameraDeviceClient>(...) //模板，CALLBACK 为hardware::camera2::ICameraDeviceCallbacks， CLIENT： CameraDeviceClient
   |   |--> validateConnectLocked(...) //关于一些权限的判断，如果没有权限或者非法访问这里会直接退出
   |   |--> int deviceVersion = getDeviceVersion(cameraId, /*out*/&facing) //获取device version, 为之后的实例化哪一个client 做准备
   |   |--> makeClient(..., deviceVersion, effectiveApiLevel, ...) //这里主要是这两个参数决定了实例化哪一个client，
   |   |--> *client = new CameraDeviceClient(cameraService, tmp, packageName, cameraId,facing, clientPid, clientUid, servicePid) //这里是实例化了CameraDeviceClient
   |   |--> client = static_cast<CLIENT*>(tmp.get()); //取得makeClient中实例化好的client
   |   |--> client->initialize(mCameraProviderManager, mMonitorTags); //开始初始化
```

## 初始化 CameraDevcieClient

CameraDeviceClient的初始化工作流程：

- 调用父类Camera2ClientBase的initialize方法进行初始化
- 实例化FrameProcessorBase对象并且将内部的Camera3Device对象传入其中,这样就建立了和Camera3Device的联系,之后将内部线程运行起来,等待来自Camera3Device的结果
- 将CameraDeviceClient注册到内部,这样就建立了与CameraDeviceClient的联系

关键结构体的介绍

1. **Camera3Device** 
   - 主要实现了对Camera Provider 的ICameraDeviceCallbacks会调接口的实现，通过该接口接收来自Provider的结果上传进而传给CameraDeviceClient
   - Camera3Device会将事件通过notify方法给到CameraDeviceClient
   - Camera3Device中RequestThread主要用于处理Request的接收与下发工作
2. **FrameProcessBase**
   - meta data以及image data 会给到 FrameProcessBase
   - FrameProcessBase主要用于metadata以及image data的中转处理

```c++
//file : frameworks/av/services/camera/libcameraservice/api2/CameraDeviceClient.cpp
status_t CameraDeviceClient::initialize(sp<CameraProviderManager> manager, const String8& monitorTags)
   |--> initializeImpl(manager, monitorTags)
   |--> mFrameProcessor = new FrameProcessorBase(mDevice); //实例化FrameProcessorBase对象
   |   |--> Camera2ClientBase::initialize(providerPtr, monitorTags)
   //file:  frameworks/av/services/camera/libcameraservice/common/Camera2ClientBase.cpp
   |   |--> status_t Camera2ClientBase<TClientBase>::initialize(sp<CameraProviderManager> manager, const String8& monitorTags)
   |   |   |--> initializeImpl(manager, monitorTags)
   |   |   |   |--> mDevice->initialize(providerPtr, monitorTags)   //这里的mDevice 是在 Camera2ClientBase初始化的时候传入的  mDevice(new Camera3Device(cameraId))
```

