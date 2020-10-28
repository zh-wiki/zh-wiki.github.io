---
title: 高通 Camx camera provider
toc: true
date: 2020-01-01 00:00:01
tags: 
---

# 概览

<img src="%E9%AB%98%E9%80%9A%20Camx%20camera%20provider/image-20201021102734471.png" alt="camera provider" style="zoom:80%;" />

通过图片可以看出Camera Provider 分为两部分

- 通过 **HIDL** 与Camera Service 跨进程通信
- 通过 **dlopen** 方式加载一系列动态库 （Camera HAL3结构的so），在高通Camera 是指 camx-chi 架构

# camera provider 和 camera hal3 的联系

HAL硬件抽象层(Hardware Abstraction Layer),是谷歌开发的用于屏蔽底层硬件抽象出来的一个软件层，该层定义了自己的一套通用标准接口,平台厂商务必按照以下规则定义自己的Module

- 每一个硬件都通过hw_module_t来描述,具有固定的名字HMI
- 每一个硬件都必须实现hw_module_t里面的open方法,用于打开硬件设备,并返回对应的操作接口集合
- 硬件的操作接口集合使用hw_device_t 来描述,并可以通过自定义一个更大的包含hw_device_t的结构体来拓展硬件操作集合

## HAL3 结构体介绍

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

## 高通 camx HAL3 结构体

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

## Camera HAL3 的实现

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

# Provider init 代码流程

![init 代码流程](%E9%AB%98%E9%80%9A%20Camx%20camera%20provider/image-20201021143242020.png)

在系统初始化的时候，系统会去运行"android.hardware.camera.provider@2.4-service_64"程序启动Provider进程，并加入HW Service Manager中接受统一管理。在改过程中实例化一个 LegacyCameraProviderImpl_2_4 对象，通过 hw_get_module 标准方法 获取HAL 模块。这边指的是 **camera.qcom.so** 。

## Camera Provider Init 函数总括

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

## Camera Provider Init 分解

通过上面的总括可以理解为 **Provider** 最终目的获取 **Camx-Chi** 的 **setting** 以及 **HW** 资源。然后保存起来返回给上层，供后面使用。

二话不说先上一张大图

![](%E9%AB%98%E9%80%9A%20Camx%20camera%20provider/image-20201026113612765.png)

### get_number_of_cameras 函数介绍

这个函数是一切美好的开始，她的最先调用就是上面介绍的provide init 函数的 **CameraModule::init()** 


```c++
//hardware/interfaces/camera/common/1.0/default/CameraModule.cpp
int CameraModule::init() {
    ATRACE_CALL();
    int res = OK;
    if (getModuleApiVersion() >= CAMERA_MODULE_API_VERSION_2_4 &&
            mModule->init != NULL) {
        ATRACE_BEGIN("camera_module->init");
        res = mModule->init();
        ATRACE_END();
    }
    //将会走到 vendor/proprietary/camx/src/coer/hal/camxhal3.cpp中
    mNumberOfCameras = getNumberOfCameras();
    mCameraInfoMap.setCapacity(mNumberOfCameras);
    return res;
}
```

**CameraModule::init()** ，这个函数调用 **getNumberOfCameras()** 。最终调用到 **get_number_of_cameras()** 这个函数已经是干到camx了。


```c++
//vendor/proprietary/camx/src/coer/hal/camxhal3.cpp
static int get_number_of_cameras(void)
{
    ......
    INT numCameras;
    //将会走到 vendor/proprietary/camx/src/coer/hal/camxhal3module.cpp中
    //会调用到 HAL3Module的构造函数
    numCameras = static_cast<int>(HAL3Module::GetInstance()->GetNumCameras());
    ......
    return numCameras;
}
```

这个函数主要有两个作用：

- 是通过 **HAL3Module** 类的构造函数会获取 CAMX-CHI 的信息
- 加载 **com.qti.chi.override.so**  模块，映射 CAMX-CHI 之间的接口


```c++
//vendor/proprietary/camx/src/coer/hal/camxhal3module.cpp
HAL3Module::HAL3Module()
{
    CamxResult result = CamxResultSuccess;
    CSLCameraPlatform CSLPlatform = {};

    CAMX_LOG_CONFIG(CamxLogGroupHAL, "***************************************************");
    CAMX_LOG_CONFIG(CamxLogGroupHAL, "SHA1:     %s", CAMX_SHA1);
    CAMX_LOG_CONFIG(CamxLogGroupHAL, "COMMITID: %s", CAMX_COMMITID);
    CAMX_LOG_CONFIG(CamxLogGroupHAL, "BUILD TS: %s", CAMX_BUILD_TS);
    CAMX_LOG_CONFIG(CamxLogGroupHAL, "***************************************************");
    ......
    //到了这个位置已经是很亲切了，干到camx了
    m_pStaticSettings = HwEnvironment::GetInstance()->GetStaticSettings();
    ......
}
```

### HwEnvironment::Initialize() 函数介绍

通过 **HAL3Module** 构造函数会调用 **HwEnvironment** 类的构造，主体功能在 **HwEnvironment::Initialize()** 中实现

<details>
<summary>HwEnvironment::Initialize()</summary>

```c++
//vendor/proprietary/camx/src/coer/camxhwenvironment.cpp
CamxResult HwEnvironment::Initialize()
{
    CamxResult              result                  = CamxResultSuccess;
    CSLInitializeParams     params                  = { 0 };
    SettingsManager*        pStaticSettingsManager  = SettingsManager::Create(NULL);
    ExternalComponentInfo*  pExternalComponent      = GetExternalComponent();

    if (NULL != pStaticSettingsManager)
    {
        const StaticSettings* pStaticSettings = pStaticSettingsManager->GetStaticSettings();

        if (NULL != pStaticSettings)
        {
            params.mode                                           = pStaticSettings->CSLMode;
            params.emulatedSensorParams.enableSensorSimulation    = pStaticSettings->enableSensorEmulation;
            params.emulatedSensorParams.dumpSensorEmulationOutput = pStaticSettings->dumpSensorEmulationOutput;

            OsUtils::StrLCpy(params.emulatedSensorParams.sensorEmulatorPath,
                             pStaticSettings->sensorEmulatorPath,
                             sizeof(pStaticSettings->sensorEmulatorPath));

            OsUtils::StrLCpy(params.emulatedSensorParams.sensorEmulator,
                             pStaticSettings->sensorEmulator,
                             sizeof(pStaticSettings->sensorEmulator));

            result = CSLInitialize(&params);

            if (CamxResultSuccess == result)
            {
                // Query the camera platform
                result = QueryHwContextStaticEntryMethods();
            }

            if (CamxResultSuccess == result)
            {
                m_pHwFactory = m_staticEntryMethods.CreateHwFactory();

                if (NULL == m_pHwFactory)
                {
                    CAMX_ASSERT_ALWAYS_MESSAGE("Failed to create the HW factory");
                    result = CamxResultEFailed;
                }
            }

            if (CamxResultSuccess == result)
            {
                m_pSettingsManager = m_pHwFactory->CreateSettingsManager();

                if (NULL == m_pSettingsManager)
                {
                    CAMX_ASSERT_ALWAYS_MESSAGE("Failed to create the HW settings manager");
                    result = CamxResultEFailed;
                }
            }

            if (CamxResultSuccess == result)
            {
                m_staticEntryMethods.GetHWBugWorkarounds(&m_workarounds);
            }
        }

        pStaticSettingsManager->Destroy();
        pStaticSettingsManager = NULL;
    }

    CAMX_ASSERT(NULL != pExternalComponent);
    if ((CamxResultSuccess == result) && (NULL != pExternalComponent))
    {
        result = ProbeChiComponents(pExternalComponent, &m_numExternalComponent);
    }

    if (CamxResultSuccess == result)
    {
        // Load the OEM sensor capacity customization functions
        CAMXCustomizeCAMXInterface camxInterface;
        camxInterface.pGetHWEnvironment = HwEnvironment::GetInstance;
        CAMXCustomizeEntry(&m_pOEMInterface, &camxInterface);
    }

    if (CamxResultSuccess != result)
    {
        CAMX_LOG_ERROR(CamxLogGroupCore, "FATAL ERROR: Raise SigAbort. HwEnvironment initialization failed");
        m_numberSensors = 0;
        OsUtils::RaiseSignalAbort();
    }
    else
    {
        m_initCapsStatus = InitCapsInitialize;
    }
    return result;
}
```

</details>

通过上面的代码可以看出 **HwEnvironment::Initialize()** 做的事情还是挺多的。下面我们开始分析

1. 获取camx的相关配置

   SettingsManager*        pStaticSettingsManager  = SettingsManager::Create(NULL);

   经过一系列调用最终会调到以下代码，加载配置参数

   ```c++
   //vendor/proprietary/camx/src/coer/camxsettingsmanager.cpp
   CamxResult SettingsManager::Initialize(
       StaticSettings* pStaticSettings)
   {
       ......    
           // Populate the default settings
           InitializeDefaultSettings();
           InitializeDefaultDebugSettings();
           
           // Load the override settings from our override settings stores
           result = LoadOverrideSettings(m_pOverrideSettingsStore);
           result = LoadOverrideProperties(m_pOverrideSettingsStore, TRUE);
           result = ValidateSettings();
   
           DumpSettings();
           m_pOverrideSettingsStore->DumpOverriddenSettings();
       ......
       	UpdateLogSettings();
   
       	return result;
   }
   ```

2. 利用加载好的配置参数去初始化相关模块

   result = CSLInitialize(&params);

   经过一个跳转表格进入以下代码

   <details>
   <summary>CamxResult CSLInitializeHW()</summary>

   ```c++
   //vendor/proprietary/camx/src/csl/hw/camxcslhw.cpp
   CamxResult CSLInitializeHW()
   {
       CamxResult result                          = CamxResultEFailed;
       CHAR       syncDeviceName[CSLHwMaxDevName] = {0};
   
       if (FALSE == CSLHwIsHwInstanceValid())
       {
           if (TRUE == CSLHwEnumerateAndAddCSLHwDevice(CSLInternalHwVideodevice, CAM_VNODE_DEVICE_TYPE))
           {
               if (TRUE == CSLHwEnumerateAndAddCSLHwDevice(CSLInternalHwVideoSubdevice, CAM_CPAS_DEVICE_TYPE))
               {
                   CAMX_LOG_VERBOSE(CamxLogGroupCSL, "Platform family=%d, version=%d.%d.%d, cpas version=%d.%d.%d",
                       g_CSLHwInstance.pCameraPlatform.family,
                       g_CSLHwInstance.pCameraPlatform.platformVersion.majorVersion,
                       g_CSLHwInstance.pCameraPlatform.platformVersion.minorVersion,
                       g_CSLHwInstance.pCameraPlatform.platformVersion.revVersion,
                       g_CSLHwInstance.pCameraPlatform.CPASVersion.majorVersion,
                       g_CSLHwInstance.pCameraPlatform.CPASVersion.minorVersion,
                       g_CSLHwInstance.pCameraPlatform.CPASVersion.revVersion);
   
                   if (FALSE == CSLHwEnumerateAndAddCSLHwDevice(CSLInternalHwVideoSubdeviceAll, 0))
                   {
                       CAMX_LOG_ERROR(CamxLogGroupCSL, "No KMD devices found");
                   }
                   else
                   {
                       CAMX_LOG_VERBOSE(CamxLogGroupCSL, "Total KMD subdevices found =%d", g_CSLHwInstance.kmdDeviceCount);
                   }
                   // Init the memory manager data structures here
                   CamX::Utils::Memset(g_CSLHwInstance.memManager.bufferInfo, 0, sizeof(g_CSLHwInstance.memManager.bufferInfo));
                   // Init the sync manager here
                   g_CSLHwInstance.lock->Lock();
                   g_CSLHwInstance.pSyncFW = CamX::SyncManager::GetInstance();
                   if (NULL != g_CSLHwInstance.pSyncFW)
                   {
                       CSLHwGetSyncHwDevice(syncDeviceName, CSLHwMaxDevName);
                       CAMX_LOG_VERBOSE(CamxLogGroupCSL, "Sync device found = %s", syncDeviceName);
                       result = g_CSLHwInstance.pSyncFW->Initialize(syncDeviceName);
                       if (CamxResultSuccess != result)
                       {
                           CAMX_LOG_ERROR(CamxLogGroupCSL, "CSL failed to initialize SyncFW");
                           result = g_CSLHwInstance.pSyncFW->Destroy();
                           g_CSLHwInstance.pSyncFW = NULL;
                       }
                   }
                   g_CSLHwInstance.lock->Unlock();
                   CSLHwInstanceSetState(CSLHwValidState);
                   result = CamxResultSuccess;
                   CAMX_LOG_VERBOSE(CamxLogGroupCSL, "Successfully acquired requestManager");
               }
               else
               {
                   CAMX_LOG_ERROR(CamxLogGroupCSL, "Failed to acquire CPAS");
               }
           }
           else
           {
               CAMX_LOG_ERROR(CamxLogGroupCSL, "Failed to acquire requestManager invalid");
           }
       }
       else
       {
           CAMX_LOG_ERROR(CamxLogGroupCSL, "CSL in Invalid State");
       }
       return result;
   
   }
   ```

   </details>

   这一部分我个人理解为，遍历所有kernel端的设备。获取相关接口以及需要的事件。与HAL层建立联系。具体分析以后可以单独写一篇文章分析

3. 根据平台获取对应的入口方法

   这个暂时不知道是个什么鬼，先这样理解

   result = QueryHwContextStaticEntryMethods();

   经过一系列的调用最终是跑到了这里

   ```c++
   //vendor/proprietary/camx/src/csl/hwl/titan17x/camxtitan17xhwl.cpp
   CamxResult Titan17xGetStaticEntryMethods(
       HwContextStaticEntry* pStaticEntry)
   {
       CamxResult result = CamxResultSuccess;
   
       pStaticEntry->Create                               = &Titan17xContext::Create;
       pStaticEntry->GetStaticMetadataKeysInfo            = &Titan17xContext::GetStaticMetadataKeysInfo;
       pStaticEntry->GetStaticCaps                        = &Titan17xContext::GetStaticCaps;
       pStaticEntry->CreateHwFactory                      = &Titan17xFactory::Create;
       pStaticEntry->QueryVendorTagsInfo                  = &Titan17xContext::QueryVendorTagsInfo;
       pStaticEntry->GetHWBugWorkarounds                  = &Titan17xContext::GetHWBugWorkarounds;
       pStaticEntry->QueryExternalComponentVendorTagsInfo = &Titan17xContext::QueryExternalComponentVendorTagsInfo;
   
       return result;
   }
   ```

4. 获取CHI各个节点的接口

   result = ProbeChiComponents(pExternalComponent, &m_numExternalComponent);

   遍历所有chi相关的.so库，将各个接口保存起来。这一块的代码撸的比较少，先记录这么多

到此处 HwEnvironment::Initialize() 这个函数就介绍的差不多了。日后慢慢完善

### HwEnvironment::InitCaps()  函数介绍

<details>
<summary>HwEnvironment::InitCaps()</summary>

```c++
VOID HwEnvironment::InitCaps()
{
    CamxResult    result = CamxResultSuccess;

    m_pHWEnvLock->Lock();

    if (InitCapsRunning == m_initCapsStatus ||
        InitCapsDone == m_initCapsStatus)
    {
        m_pHWEnvLock->Unlock();
        return;
    }

    m_initCapsStatus = InitCapsRunning;

    if (CamxResultSuccess == result)
    {
        EnumerateDevices();
        ProbeImageSensorModules();
        EnumerateSensorDevices();
        InitializeSensorSubModules();
        InitializeSensorStaticCaps();

        result = m_staticEntryMethods.GetStaticCaps(&m_platformCaps[0]);
        // copy the static capacity to remaining sensor's
        for (UINT index = 1; index < m_numberSensors; index++)
        {
            Utils::Memcpy(&m_platformCaps[index], &m_platformCaps[0], sizeof(m_platformCaps[0]));
        }
        if (NULL != m_pOEMInterface->pInitializeExtendedPlatformStaticCaps)
        {
            m_pOEMInterface->pInitializeExtendedPlatformStaticCaps(&m_platformCaps[0], m_numberSensors);
        }
    }

    CAMX_ASSERT(CamxResultSuccess == result);

    if (CamxResultSuccess == result)
    {
        InitializeHwEnvironmentStaticCaps();
    }

    m_initCapsStatus = InitCapsDone;

    m_pHWEnvLock->Unlock();
}

```

</details>