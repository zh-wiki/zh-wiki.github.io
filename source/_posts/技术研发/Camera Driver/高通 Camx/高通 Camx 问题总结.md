---
title: 高通 Camx 问题总结
toc: true
date: 2020-01-01 00:00:60
tags: 
---

# 帧率问题

## 人像模式在暗环境，帧率过低，预览卡顿

1. 首先确认一下信息
   - 测试环境有多暗 lux（是否有量变的过程）
   - camera 镜头距离拍摄物多远
   
   
   
2. 查看sensor 出帧是否正常

   开启内核双摄帧同步的log

   ```bash
   adb shell "echo 0x1000018 > ./sys/module/cam_debug_util/parameters/debug_mdl"
   adb logcat -b kernel > kmd.log
   ```

   正常环境log

   ```verilog
   Line 3662: 01-02 02:37:40.256     0     0 I CAM_DBG : CAM-ISP: __cam_isp_ctx_send_sof_timestamp: 666: request id:64 frame number:66 SOF time stamp:0x4ceb8d14a14
   Line 3679: 01-02 02:37:40.256     0     0 I CAM_DBG : CAM-ISP: __cam_isp_ctx_send_sof_timestamp: 666: request id:64 frame number:66 SOF time stamp:0x4ceb8d5cc41
   Line 4564: 01-02 02:37:40.289     0     0 I CAM_DBG : CAM-ISP: __cam_isp_ctx_send_sof_timestamp: 666: request id:65 frame number:67 SOF time stamp:0x4cebacd4843
   Line 4618: 01-02 02:37:40.290     0     0 I CAM_DBG : CAM-ISP: __cam_isp_ctx_send_sof_timestamp: 666: request id:65 frame number:67 SOF time stamp:0x4cebad1caa4
   ```

   通过上述log，发现 request id 和  frame number 都是成双成对的。分别对应主摄和辅摄的出帧。

   For Example ：request id:65 frame number:67

   Line 4564: 01-02 02:37:40.289 

   Line 4618: 01-02 02:37:40.290 

   通过分析log ，可以看出主摄和辅摄只差1ms，同步OK.

   暗环境下的log

   ```verilog
   Line 124973: 01-02 03:00:15.035     0     0 I CAM_DBG : CAM-ISP: __cam_isp_ctx_send_sof_timestamp: 666: request id:0 frame number:193 SOF time stamp:0x60a27f1067b
   Line 124990: 01-02 03:00:15.035     0     0 I CAM_DBG : CAM-ISP: __cam_isp_ctx_send_sof_timestamp: 666: request id:0 frame number:110 SOF time stamp:0x60a27f5890f
   
   Line 131018: 01-02 03:00:16.055     0     0 I CAM_DBG : CAM-ISP: __cam_isp_ctx_send_sof_timestamp: 666: request id:0 frame number:213 SOF time stamp:0x60a64afe776
   Line 131041: 01-02 03:00:16.055     0     0 I CAM_DBG : CAM-ISP: __cam_isp_ctx_send_sof_timestamp: 666: request id:74 frame number:121 SOF time stamp:0x60a64b469d7
   ```

   很明显没有同步，分别算一下帧率

   16.055 - 15.035 = 1.5s

   主摄 (213-193)/1.5 = 13fps

   辐射 (121-110)/1.5 = 7.3fps

3. 解决方法

   - 方案一

     找Tuning的同事固定帧率，调试曝光表

