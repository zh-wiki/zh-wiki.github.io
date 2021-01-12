---
title: 高通 mm ConfigureStream 代码流程
toc: true
date: 2020-00-00 00:00:04
tags: 高通 mm 
---

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