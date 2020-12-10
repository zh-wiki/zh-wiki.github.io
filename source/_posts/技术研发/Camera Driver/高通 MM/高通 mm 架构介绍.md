---
title: 高通 mm 架构介绍
toc: true
date: 2020-00-00 00:00:00
tags: 高通 mm 
---

# Config Stream 

关键结构体

```c++
//hardware/libhardware/include/hardware/camera3.h
typedef struct camera3_stream_configuration {
	uint32_t num_streams;
    camera3_stream_t **streams;
    uint32_t operation_mode;
    const camera_metadata_t *session_parameters;
} camera3_stream_configuration_t;
```

```c++
typedef struct camera3_stream {
    int stream_type;
    uint32_t width;
    uint32_t height;
    int format;
    uint32_t usage;
    uint32_t max_buffers;
    void *priv;
    android_dataspace_t data_space;
    int rotation;
    const char* physical_camera_id;
    void *reserved[6];
} camera3_stream_t;
```

主要函数

```c++
int QCamera3HardwareInterface::configureStreamsPerfLocked(camera3_stream_configuration_t *streamList)
{
    
}
```



# Camera INIT 流程

```c
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

