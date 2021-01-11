---
title: 高通 mm 架构介绍
toc: true
date: 2020-00-00 00:00:00
tags: 高通 mm 
---

# Camera INIT 流程

------

```c++
//vendor/qcom/proprietary/mm-camera/mm-camera2/server-imaging/server.c
int main(int argc __unused, char *argv[] __unused)
{
    /* 2. after open node, initialize modules */
    if(server_process_module_sensor_init() == FALSE)
        goto module_init_fail;
    CLOGD(CAM_MCT_MODULE, "CAMERA_DAEMON:End of all modules init");
}

//vendor/qcom/proprietary/mm-camera/mm-camera2/server-imaging/server_process.c
boolean server_process_module_sensor_init(void)
{
    CLOGD(CAM_MCT_MODULE, "CAMERA_DAEMON: Begin sensor init mods");
    if( NULL == modules_list[0].init_mod)
      return FALSE;

    //这里用了一个转移表
    temp = modules_list[0].init_mod(modules_list[0].name);
}

//vendor/qcom/proprietary/mm-camera/mm-camera2/server-imaging/server_process.c
//转移表定义如下
static mct_module_init_name_t modules_list[] = {
  {"sensor", module_sensor_init,   module_sensor_deinit, NULL},
  {"iface",  module_iface_init,   module_iface_deinit, NULL},
  {"isp",    module_isp_init,      module_isp_deinit, NULL},
  {"stats",  stats_module_init,    stats_module_deinit, NULL},
  {"pproc",  pproc_module_init,    pproc_module_deinit, NULL},
  {"imglib", module_imglib_init, module_imglib_deinit, NULL},
};

//vendor/qcom/proprietary/mm-camera/mm-camera2/media-controller/modules/sensors/module/module_sensor.c
mct_module_t *module_sensor_init(const char *name)
{
    /* module_sensor_probe_sensors */
    ret = sensor_init_probe(module_ctrl);
    if (ret == FALSE) {
        SERR("failed");
        goto ERROR1;
    }
}

//vendor/qcom/proprietary/mm-camera/mm-camera2/media-controller/modules/sensors/module/sensor_init.c
//这个函数已经干到内核了
boolean sensor_init_probe(module_sensor_ctrl_t *module_ctrl)
{
    /* Open sensor_init subdev */
    SINFO("opening: %s", subdev_name);
    sd_fd = open(subdev_name, O_RDWR);
    if (sd_fd < 0) {
        SHIGH("Open sensor_init subdev failed");
        return FALSE;
    }
    ret = sensor_init_eebin_probe(module_ctrl, sd_fd);
    if (ret == FALSE) {
        SINFO("failed: to probe eeprom bin sensors (non-fatal)");
    }
    
    RETURN_ON_FALSE(sensor_init_xml_probe(module_ctrl, sd_fd));
}
```



# HAL Configure Stream 

------

主要函数

```c++
int QCamera3HardwareInterface::configureStreamsPerfLocked(camera3_stream_configuration_t *streamList)
{
    ......
    /* stream configurations */
    for (size_t i = 0; i < streamList->num_streams; i++) {
        camera3_stream_t *newStream = streamList->streams[i];
        ......
        //根据不同的格式 给局部变量赋值，暂时先不研究
        ......
    }
    
    camera3_stream_t *zslStream = NULL; //Only use this for size and not actual handle!
    for (size_t i = 0; i < streamList->num_streams; i++) {
        .......
        //给类成员 mStreamInfo 复值
        mStreamInfo.push_back(stream_info);
        .......
    }
    
    //Create metadata channel and initialize it
    //创建了metadata 的通道，并进行了初始化
    mMetadataChannel = new QCamera3MetadataChannel(mCameraHandle->camera_handle,
                    mChannelHandle, mCameraHandle->ops, captureResultCb,
                    setBufferErrorStatus, &padding_info, metadataFeatureMask, this);
    rc = mMetadataChannel->initialize(IS_TYPE_NONE);
    
     /* Allocate channel objects for the requested streams */
    for (size_t i = 0; i < streamList->num_streams; i++) {
        ......
         //这个循环可以理解为2部分 
            //第一部分
            //很多地方操作了 mStreamConfigInfo 这个类成员，应该是配置流的某些配置信息

            //第二部分
            //为请求的流分配 chanel 对象，但是并没有初始化，我大概搂了一眼，操作和metadata channel操作都是差不多的
            //只不过metadata channel 在配流的时候就初始化好了
            //流的channel只是 new 了一个对象，在 request的时候初始化的。
            if (newStream->priv == NULL) {
                //New stream, construct channel
                switch (newStream->format) {
                        case HAL_PIXEL_FORMAT_IMPLEMENTATION_DEFINED:
                                channel = new QCamera3RegularChannel(......); 
                             ........
                             newStream->max_buffers = MAX_INFLIGHT_HFR_REQUESTS;
                             newStream->priv = channel;
                             ........
                              break;
                }
                ......
                 //创建成功之后，将各个channel存入 mStreamInfo list 中。大概浏览了一下 request 时候会调用，进行给channel初始化
                for (List<stream_info_t*>::iterator it=mStreamInfo.begin(); it != mStreamInfo.end(); it++) {
                    if ((*it)->stream == newStream) {
                        (*it)->channel = (QCamera3ProcessingChannel*) newStream->priv;
                        break;
                    }
                }
                .......
            }
    }
}
```

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
   



------

> **博客推荐**
>
> https://www.jianshu.com/p/ecb1be82e6a8
>
> https://www.jianshu.com/p/1baad2a5281d
>
> https://wenku.baidu.com/view/3b408a6159fb770bf78a6529647d27284b733702.html