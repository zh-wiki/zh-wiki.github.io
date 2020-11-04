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

App端主要做了以下几点工作

1. 获取 CameraManager 服务

2. 打开指定的 Camera
   - 获取 Camera Server
   - 调用 cameraService.connectDevice() 去连接打开设备，并且将上层传下来的回调传入Camera Server
   - 返回Device给App端

# Camera Server Open 流程

对于打开相机设备动作,主要由connectDevice来实现，当CameraFramework通过调用ICameraService的connectDevice接口的时候,主要做了两件事情：

- 创建CameraDeviceClient。
- 对CameraDeviceClient进行初始化,并将其给Framework。

##  创建 CameraDevcieClient

<details>
<summary>CameraDeviceClient</summary>


```c++
class CameraDeviceClient :
        public Camera2ClientBase<CameraDeviceClientBase>,
        public camera2::FrameProcessorBase::FilteredListener
{
public:
    /**
     * ICameraDeviceUser interface (see ICameraDeviceUser for details)
     */

    // Note that the callee gets a copy of the metadata.
    virtual binder::Status submitRequest(
            const hardware::camera2::CaptureRequest& request,
            bool streaming = false,
            /*out*/
            hardware::camera2::utils::SubmitInfo *submitInfo = nullptr) override;
    // List of requests are copied.
    virtual binder::Status submitRequestList(
            const std::vector<hardware::camera2::CaptureRequest>& requests,
            bool streaming = false,
            /*out*/
            hardware::camera2::utils::SubmitInfo *submitInfo = nullptr) override;
    virtual binder::Status cancelRequest(int requestId,
            /*out*/
            int64_t* lastFrameNumber = NULL) override;

    virtual binder::Status beginConfigure() override;

    virtual binder::Status endConfigure(int operatingMode,
            const hardware::camera2::impl::CameraMetadataNative& sessionParams) override;

    // Verify specific session configuration.
    virtual binder::Status isSessionConfigurationSupported(
            const SessionConfiguration& sessionConfiguration,
            /*out*/
            bool* streamStatus) override;

    // Returns -EBUSY if device is not idle or in error state
    virtual binder::Status deleteStream(int streamId) override;

    virtual binder::Status createStream(
            const hardware::camera2::params::OutputConfiguration &outputConfiguration,
            /*out*/
            int32_t* newStreamId = NULL) override;

    // Create an input stream of width, height, and format.
    virtual binder::Status createInputStream(int width, int height, int format,
            /*out*/
            int32_t* newStreamId = NULL) override;

    // Get the buffer producer of the input stream
    virtual binder::Status getInputSurface(
            /*out*/
            view::Surface *inputSurface) override;

    // Create a request object from a template.
    virtual binder::Status createDefaultRequest(int templateId,
            /*out*/
            hardware::camera2::impl::CameraMetadataNative* request) override;

    // Get the static metadata for the camera
    // -- Caller owns the newly allocated metadata
    virtual binder::Status getCameraInfo(
            /*out*/
            hardware::camera2::impl::CameraMetadataNative* cameraCharacteristics) override;

    // Wait until all the submitted requests have finished processing
    virtual binder::Status waitUntilIdle() override;

    // Flush all active and pending requests as fast as possible
    virtual binder::Status flush(
            /*out*/
            int64_t* lastFrameNumber = NULL) override;

    // Prepare stream by preallocating its buffers
    virtual binder::Status prepare(int32_t streamId) override;

    // Tear down stream resources by freeing its unused buffers
    virtual binder::Status tearDown(int32_t streamId) override;

    // Prepare stream by preallocating up to maxCount of its buffers
    virtual binder::Status prepare2(int32_t maxCount, int32_t streamId) override;

    // Update an output configuration
    virtual binder::Status updateOutputConfiguration(int streamId,
            const hardware::camera2::params::OutputConfiguration &outputConfiguration) override;

    // Finalize the output configurations with surfaces not added before.
    virtual binder::Status finalizeOutputConfigurations(int32_t streamId,
            const hardware::camera2::params::OutputConfiguration &outputConfiguration) override;

    /**
     * Interface used by CameraService
     */

    CameraDeviceClient(const sp<CameraService>& cameraService,
            const sp<hardware::camera2::ICameraDeviceCallbacks>& remoteCallback,
            const String16& clientPackageName,
            const String8& cameraId,
            int cameraFacing,
            int clientPid,
            uid_t clientUid,
            int servicePid);
    virtual ~CameraDeviceClient();

    virtual status_t      initialize(sp<CameraProviderManager> manager,
            const String8& monitorTags) override;

    virtual status_t      dump(int fd, const Vector<String16>& args);

    virtual status_t      dumpClient(int fd, const Vector<String16>& args);

    /**
     * Device listener interface
     */

    virtual void notifyIdle();
    virtual void notifyError(int32_t errorCode,
                             const CaptureResultExtras& resultExtras);
    virtual void notifyShutter(const CaptureResultExtras& resultExtras, nsecs_t timestamp);
    virtual void notifyPrepared(int streamId);
    virtual void notifyRequestQueueEmpty();
    virtual void notifyRepeatingRequestError(long lastFrameNumber);

    /**
     * Interface used by independent components of CameraDeviceClient.
     */
protected:
    /** FilteredListener implementation **/
    virtual void          onResultAvailable(const CaptureResult& result);
    virtual void          detachDevice();

    // Calculate the ANativeWindow transform from android.sensor.orientation
    status_t              getRotationTransformLocked(/*out*/int32_t* transform);

private:
    // StreamSurfaceId encapsulates streamId + surfaceId for a particular surface.
    // streamId specifies the index of the stream the surface belongs to, and the
    // surfaceId specifies the index of the surface within the stream. (one stream
    // could contain multiple surfaces.)
    class StreamSurfaceId final {
    public:
        StreamSurfaceId() {
            mStreamId = -1;
            mSurfaceId = -1;
        }
        StreamSurfaceId(int32_t streamId, int32_t surfaceId) {
            mStreamId = streamId;
            mSurfaceId = surfaceId;
        }
        int32_t streamId() const {
            return mStreamId;
        }
        int32_t surfaceId() const {
            return mSurfaceId;
        }

    private:
        int32_t mStreamId;
        int32_t mSurfaceId;

    }; // class StreamSurfaceId

private:
    /** ICameraDeviceUser interface-related private members */

    /** Preview callback related members */
    sp<camera2::FrameProcessorBase> mFrameProcessor;
    static const int32_t FRAME_PROCESSOR_LISTENER_MIN_ID = 0;
    static const int32_t FRAME_PROCESSOR_LISTENER_MAX_ID = 0x7fffffffL;

    std::vector<int32_t> mSupportedPhysicalRequestKeys;

    template<typename TProviderPtr>
    status_t      initializeImpl(TProviderPtr providerPtr, const String8& monitorTags);

    /** Utility members */
    binder::Status checkPidStatus(const char* checkLocation);
    binder::Status checkOperatingModeLocked(int operatingMode) const;
    binder::Status checkPhysicalCameraIdLocked(String8 physicalCameraId);
    binder::Status checkSurfaceTypeLocked(size_t numBufferProducers, bool deferredConsumer,
            int surfaceType) const;
    static void mapStreamInfo(const OutputStreamInfo &streamInfo,
            camera3_stream_rotation_t rotation, String8 physicalId,
            hardware::camera::device::V3_4::Stream *stream /*out*/);
    bool enforceRequestPermissions(CameraMetadata& metadata);

    // Find the square of the euclidean distance between two points
    static int64_t euclidDistSquare(int32_t x0, int32_t y0, int32_t x1, int32_t y1);

    // Create an output stream with surface deferred for future.
    binder::Status createDeferredSurfaceStreamLocked(
            const hardware::camera2::params::OutputConfiguration &outputConfiguration,
            bool isShared,
            int* newStreamId = NULL);

    // Set the stream transform flags to automatically rotate the camera stream for preview use
    // cases.
    binder::Status setStreamTransformLocked(int streamId);

    // Find the closest dimensions for a given format in available stream configurations with
    // a width <= ROUNDING_WIDTH_CAP
    static const int32_t ROUNDING_WIDTH_CAP = 1920;
    static bool roundBufferDimensionNearest(int32_t width, int32_t height, int32_t format,
            android_dataspace dataSpace, const CameraMetadata& info,
            /*out*/int32_t* outWidth, /*out*/int32_t* outHeight);

    //check if format is not custom format
    static bool isPublicFormat(int32_t format);

    // Create a Surface from an IGraphicBufferProducer. Returns error if
    // IGraphicBufferProducer's property doesn't match with streamInfo
    binder::Status createSurfaceFromGbp(OutputStreamInfo& streamInfo, bool isStreamInfoValid,
            sp<Surface>& surface, const sp<IGraphicBufferProducer>& gbp,
            const String8& physicalCameraId);


    // Utility method to insert the surface into SurfaceMap
    binder::Status insertGbpLocked(const sp<IGraphicBufferProducer>& gbp,
            /*out*/SurfaceMap* surfaceMap, /*out*/Vector<int32_t>* streamIds,
            /*out*/int32_t*  currentStreamId);

    // Check that the physicalCameraId passed in is spported by the camera
    // device.
    bool checkPhysicalCameraId(const String8& physicalCameraId);

    // IGraphicsBufferProducer binder -> Stream ID + Surface ID for output streams
    KeyedVector<sp<IBinder>, StreamSurfaceId> mStreamMap;

    // Stream ID -> OutputConfiguration. Used for looking up Surface by stream/surface index
    KeyedVector<int32_t, hardware::camera2::params::OutputConfiguration> mConfiguredOutputs;

    struct InputStreamConfiguration {
        bool configured;
        int32_t width;
        int32_t height;
        int32_t format;
        int32_t id;
    } mInputStream;

    // Streaming request ID
    int32_t mStreamingRequestId;
    Mutex mStreamingRequestIdLock;
    static const int32_t REQUEST_ID_NONE = -1;

    int32_t mRequestIdCounter;
    bool mPrivilegedClient;

    // The list of output streams whose surfaces are deferred. We have to track them separately
    // as there are no surfaces available and can not be put into mStreamMap. Once the deferred
    // Surface is configured, the stream id will be moved to mStreamMap.
    Vector<int32_t> mDeferredStreams;

    // stream ID -> outputStreamInfo mapping
    std::unordered_map<int32_t, OutputStreamInfo> mStreamInfoMap;

    KeyedVector<sp<IBinder>, sp<CompositeStream>> mCompositeStreamMap;

    static const int32_t MAX_SURFACES_PER_STREAM = 4;
    sp<CameraProviderManager> mProviderManager;
};
```

</details>

CameraDeviceClient 该类在打开设备的时候被实例化，一次打开设备的操作对应一个该类对象，它实现了ICameraDeviceUser接口，以AIDL方式暴露接口给Camera Framework进行调用，于此同时,该类在打开设备的过程中，获取了来自Camera Framework对于ICameraDeviceCallback接口的实现代理，通过该代理可以将结果上传至Camera Framewor中。

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

