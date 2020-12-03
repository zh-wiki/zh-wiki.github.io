---
title: 高通 mm 架构 bring up
toc: true
date: 2020-00-00 00:00:01
tags: 高通 mm 
---

# PDAF 调试方法

1. 首先设置号相应的log权限

   ```bash
   adb shell setprop persist.camera.stats.af.debug 5
   adb shell setprop persist.camera.stats.haf.debug 5
   ```

2. 使相机进入fullsweep(全扫描)模式

   ```bash
   adb shell setprop vendor.debug.camera.af_fullsweep 1
   ```

   可能不同的平台命令有所不同，可以在代码中搜索

   ```c
   //vendor/qcom/proprietary/mm-camera/mm-camera2/media-controller/modules/stats/q3a/af/af_biz.c
   void af_biz_process(stats_af_t *stats, af_output_data_t *output,
     uint8_t num_of_outputs, void *af_obj)
    {
       // Get Setproc for fullsweep algo.
      /* Enable full-sweep property:
        * 0 - disable
        * 1 - far-to-near
        * 2 - reverse search (near-to-far)
        * 3 - both (far->near->far)*/
       property_get("vendor.debug.camera.af_fullsweep", value, "0");
    }
   ```

3. log 分析

   ```verilog
   Line 86657: 01-03 07:11:00.426   681  4760 D mm-camera: <STATS_HAF >< HIGH> 3586: af_pdaf_proc_pd_single: roi(0) lens_pos=438 index=14, pd=-10.02, defocus(um)=-248, conf=537, is_conf=FALSE, not_conf_cnt=13, is_stable=TRUE
   Line 88565: 01-03 07:11:00.504   681  4760 D mm-camera: <STATS_HAF >< HIGH> 3586: af_pdaf_proc_pd_single: roi(0) lens_pos=438 index=16, pd=-10.24, defocus(um)=-253, conf=559, is_conf=FALSE, not_conf_cnt=15, is_stable=TRUE
   Line 94865: 01-03 07:11:00.769   681  4760 D mm-camera: <STATS_HAF >< HIGH> 3586: af_pdaf_proc_pd_single: roi(0) lens_pos=434 index=22, pd=-10.55, defocus(um)=-262, conf=532, is_conf=FALSE, not_conf_cnt=21, is_stable=TRUE
   Line 98620: 01-03 07:11:00.905   681  4760 D mm-camera: <STATS_HAF >< HIGH> 3586: af_pdaf_proc_pd_single: roi(0) lens_pos=432 index=26, pd=-10.45, defocus(um)=-259, conf=547, is_conf=FALSE, not_conf_cnt=25, is_stable=TRUE
   ..................
   Line 692125: 01-03 07:11:35.301   681  4760 D mm-camera: <STATS_HAF >< HIGH> 3586: af_pdaf_proc_pd_single: roi(0) lens_pos=4 index=34, pd=6.69, defocus(um)=166, conf=916, is_conf=FALSE, not_conf_cnt=259, is_stable=TRUE
   Line 694909: 01-03 07:11:35.424   681  4760 D mm-camera: <STATS_HAF >< HIGH> 3586: af_pdaf_proc_pd_single: roi(0) lens_pos=2 index=37, pd=6.72, defocus(um)=166, conf=917, is_conf=FALSE, not_conf_cnt=262, is_stable=TRUE
   Line 697981: 01-03 07:11:35.661   681  4760 D mm-camera: <STATS_HAF >< HIGH> 3586: af_pdaf_proc_pd_single: roi(0) lens_pos=0 index=43, pd=6.83, defocus(um)=169, conf=945, is_conf=FALSE, not_conf_cnt=268, is_stable=TRUE
   .................
   Line 1000442: 01-03 07:11:53.425   681  4760 D mm-camera: <STATS_HAF >< HIGH> 3586: af_pdaf_proc_pd_single: roi(0) lens_pos=166 index=36, pd=-0.06, defocus(um)=-1, conf=705, is_conf=TRUE, not_conf_cnt=0, is_stable=TRUE
   Line 1001078: 01-03 07:11:53.460   681  4760 D mm-camera: <STATS_HAF >< HIGH> 3586: af_pdaf_proc_pd_single: roi(0) lens_pos=166 index=37, pd=0.05, defocus(um)=1, conf=695, is_conf=TRUE, not_conf_cnt=0, is_stable=TRUE
   Line 1001836: 01-03 07:11:53.503   681  4760 D mm-camera: <STATS_HAF >< HIGH> 3586: af_pdaf_proc_pd_single: roi(0) lens_pos=166 index=38, pd=0.15, defocus(um)=3, conf=731, is_conf=TRUE, not_conf_cnt=0, is_stable=TRUE
   ```

   进入fullsweep Mode Far to Near

   - 进行完一次全扫描后，lens position 最终是 166，观察pd值 和 defocus 接近于0 表示正常
   - 过程中观察 pd 和 defocus 值应该是成线性的 

#  Dump OTP 数据

1. 如果camera文件夹在vendor路径下

   ![camera 配置路径](%E9%AB%98%E9%80%9A%20mm%20%E6%9E%B6%E6%9E%84%20bring%20up/image-20201130153505584.png)

   ```mariadb
   adb root
   adb remount
   adb shell setprop persist.vendor.camera.cal.dump 1
   adb reboot
   ```

2. dump 的数据路径如下

   ![OTP 数据路径](%E9%AB%98%E9%80%9A%20mm%20%E6%9E%B6%E6%9E%84%20bring%20up/image-20201130153815551.png)



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

