---
title: 高通 Camx camera provider
toc: true
date: 2020-01-01 00:00:01
tags: Camx
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

**camera provider init 函数详解**

```c++
// hardware/interfaces/camera/provider/2.4/default/LegacyCameraProviderImpl_2_4.cpp
bool LegacyCameraProviderImpl_2_4::initialize() {
	camera_module_t *rawModule;
	 
	//获取 camera.qcom.so 可以理解为和 camxhal3entry.cpp 建立联系
	int err = hw_get_module(CAMERA_HARDWARE_MODULE_ID, (const hw_module_t **)&rawModule); 		
	 
	//将 camera.qcom.so 获取的句柄保存在 mModule 对象中 ，该函数定义在 CameraModule.cpp 
	mModule = new CameraModule(rawModule);
	    
	//我们可以跟进去看看 init() 非常明显 实际就是进行 camx 的初始化，camxhal3entry.cpp  { CAMX:: init()} 
    //int CameraModule::init() 这个函数将会调用 getNumberOfCameras() 
    //就此 camx-chi 的一系列初始化操作 拉开序幕
	err = mModule->init(); 
	    
	// 设置回调函数，用于接受camx-chi的数据和事件
	err = mModule->setCallbacks(this);
	   
	mNumberOfLegacyCameras = mModule->getNumberOfCameras();
	return false; // mInitFailed
}
```

init 函数结束之后，Camera Provider进程便一直便存在于系统中,监听着来自Camera Service的调用。

#### camera provider 和 camera hal3 的联系

HAL硬件抽象层(Hardware Abstraction Layer),是谷歌开发的用于屏蔽底层硬件抽象出来的一个软件层，该层定义了自己的一套通用标准接口,平台厂商务必按照以下规则定义自己的Module

- 每一个硬件都通过hw_module_t来描述,具有固定的名字HMI
- 每一个硬件都必须实现hw_module_t里面的open方法,用于打开硬件设备,并返回对应的操作接口集合
- 硬件的操作接口集合使用hw_device_t 来描述,并可以通过自定义一个更大的包含hw_device_t的结构体来拓展硬件操作集合

##### HAL3 结构体介绍

<details>
<summary>hw_module_t</summary>

```c++
typedef struct hw_module_t {
    uint32_t tag;
    uint16_t module_api_version;
#define version_major module_api_version
    uint16_t hal_api_version;
#define version_minor hal_api_version
    const char *id;
    const char *name;
    const char *author;
    struct hw_module_methods_t* methods;
    void* dso;
#ifdef __LP64__
    uint64_t reserved[32-7];
#else
    uint32_t reserved[32-7];
#endif
} hw_module_t;
```
</details>

<details>
<summary>hw_module_methods_t</summary>

```c++
typedef struct hw_module_methods_t {
    /** Open a specific device */
    int (*open)(const struct hw_module_t* module, const char* id,
            struct hw_device_t** device);
} hw_module_methods_t;
```

</details>

<details>
<summary>hw_device_t</summary>

```c++
typedef struct hw_device_t {
    uint32_t tag;
    uint32_t version;
    struct hw_module_t* module;

#ifdef __LP64__
    uint64_t reserved[12];
#else
    uint32_t reserved[12];
#endif
    int (*close)(struct hw_device_t* device);
    
} hw_device_t;
```

</details>

从上面的定义可以看出

- hw_module_t 代表了模块，通过其open方法用来打开一个设备

- 设备是用hw_device_t来表示，其中除了用来关闭设备的close方法外,并无其它方法

- 由此可见谷歌定义的HAL接口,并不能满足绝大部分HAL模块的需要,所以谷歌想出了一个比较好的解决方式,那便是将这两个基本结构嵌入到更大的结构体内部,同时在更大的结构内部定义了各自模块特有的方法,用于实现模块的功能,这样,一来对上保持了HAL的统一规范,二来也扩展了模块的功能

##### 高通 camx HAL3 结构体

<details>
<summary>camera_module_t</summary>


```c++
typedef struct camera_module {
    hw_module_t common;
    int (*get_number_of_cameras)(void);
    int (*get_camera_info)(int camera_id, struct camera_info *info);
    int (*set_callbacks)(const camera_module_callbacks_t *callbacks);
    void (*get_vendor_tag_ops)(vendor_tag_ops_t* ops);
    int (*open_legacy)(const struct hw_module_t* module, const char* id, uint32_t halVersion, struct hw_device_t** device);
    int (*set_torch_mode)(const char* camera_id, bool enabled);
    int (*init)();
    int (*get_physical_camera_info)(int physical_camera_id,  camera_metadata_t **static_metadata);
    int (*is_stream_combination_supported)(int camera_id, const camera_stream_combination_t *streams);
    void (*notify_device_state_change)(uint64_t deviceState);
    int (*get_camera_device_version)(int camera_id, uint32_t *version);
    void* reserved[1];
} camera_module_t;
```

</details>


<details>
<summary>camera3_device_t</summary>

```c++
typedef struct camera3_device {
    hw_device_t common;
    camera3_device_ops_t *ops;
    void *priv;
} camera3_device_t;
```

</details>

- camera_module_t包含了hw_module_t，主要用于表示Camera模块，其中定义了诸如get_number_of_cameras以及set_callbacks等扩展方法
- camera3_device_t包含了hw_device_t,主要用来表示Camera设备,其中定义了camera3_device_ops操作方法集合,用来实现正常获取图像数据以及控制Camera的功能

##### Camera HAL3 的实现

```c++
CAMX_VISIBILITY_PUBLIC camera_module_t HAL_MODULE_INFO_SYM =
{
    .common =
    {
        .tag                = HARDWARE_MODULE_TAG,
        .module_api_version = CAMERA_MODULE_API_VERSION_CURRENT,
        .hal_api_version    = HARDWARE_HAL_API_VERSION,
        .id                 = CAMERA_HARDWARE_MODULE_ID,
        .name               = "QTI Camera HAL",
        .author             = "Qualcomm Technologies, Inc.",
        .methods            = &CamX::g_hwModuleMethods
    },
    .get_number_of_cameras  = CamX::get_number_of_cameras,
    .get_camera_info        = CamX::get_camera_info,
    .set_callbacks          = CamX::set_callbacks,
    .get_vendor_tag_ops     = CamX::get_vendor_tag_ops,
    .open_legacy            = NULL,
    .set_torch_mode         = CamX::set_torch_mode,
    .init                   = CamX::init
};
```

没错高通 camx hal3 的入口就是这个，在遵循HAL3规范的前提下，实例化各个接口。Provider 将会调用 hw_get_module() 来获取该入口。

各个接口映射到 camxhal3.cpp

```c++
static Dispatch g_dispatchHAL3(&g_jumpTableHAL3);
```

```c++
JumpTableHAL3 g_jumpTableHAL3 =
{
    open,
    get_number_of_cameras,
    get_camera_info,
    set_callbacks,
    get_vendor_tag_ops,
    open_legacy,
    set_torch_mode,
    init,
    get_tag_count,
    get_all_tags,
    get_section_name,
    get_tag_name,
    get_tag_type,
    close,
    initialize,
    configure_streams,
    construct_default_request_settings,
    process_capture_request,
    dump,
    flush,
    camera_device_status_change,
    torch_mode_status_change,
    process_capture_result,
    notify
};
```

</details>