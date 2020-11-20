---
title: 高通 mm 架构 bring up
toc: true
date: 2020-00-00 00:00:01
tags: 高通 mm 
---

# 双摄帧同步导通

1. sensor setting 的配置

   <details>
   <summary>主摄配置</summary>
   
   ```c
   //vendor/qcom/proprietary/mm-camera/mm-camera2/media-controller/modules/sensors/sensor/libs/hi1336_hs70_hlt/hi1336_lib.h
   #define DUAL_CAM_MASTER_SETTINGS \
   { \
     {0x0250, 0x0100, 0x0000}, \
     {0x0254, 0x1c00, 0x0000}, \
     {0x0256, 0x0000, 0x0000}, \
     {0x0258, 0x0001, 0x0000}, \
     {0x025A, 0x0000, 0x0000}, \
     {0x025C, 0x0000, 0x0000}, \
   }
   
   static sensor_lib_t sensor_lib_ptr =
   {
     .dualcam_master_settings =
     {
       .reg_setting_a = DUAL_CAM_MASTER_SETTINGS,
       .addr_type = CAMERA_I2C_WORD_ADDR,
       .data_type = CAMERA_I2C_WORD_DATA,
       .delay = 0,
       .size = 6,
     },
   }
   ```
   
   </details>
   
      <details>
   <summary>辅摄配置</summary>
   
   ```c
   #define DUAL_CAM_SLAVE_SETTINGS \
   { \
       {0x3002, 0x00, 0x00}, \
       {0x3823, 0x30, 0x00}, \
       {0x3824, 0x00, 0x00}, \
       {0x3825, 0x20, 0x00}, \
       {0x3826, 0x00, 0x00}, \
       {0x3827, 0x04, 0x00}, \
   }
   
   static sensor_lib_t sensor_lib_ptr =
   {
       .dualcam_slave_settings =
       {
         .reg_setting_a = DUAL_CAM_SLAVE_SETTINGS,
         .addr_type = CAMERA_I2C_WORD_ADDR,
         .data_type = CAMERA_I2C_BYTE_DATA,
         .delay = 0,
         .size = 6,
       },
   }
   ```
   
   </details>

