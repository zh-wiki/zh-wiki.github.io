---
title: XTS 测试指南
toc: true
date: 2020-00-00 00:00:00
tags: XTS
---

# CTS 简介

------

## 搭建测试环境

1. sudo apt install aapt
2. 下载CTS工具包 [DOWNLOAD](https://source.android.com/compatibility/cts/downloads)
3. 安装对应版本的 JDK
4. cd 到目录android-cts/tools， 执行./cts-tradefed， 至此将进入CTS运行环境

## 常用测试命令

1. 测试整个camera

   ```bash
   run cts -m CtsCameraTestCases
   ```

2. 测试V8a或V7a 所有项

   ```bash
   run cts -m CtsCameraTestCases --abi xxx (arm64-v8a)
   run cts -m CtsCameraTestCases --abi xxx (armeabi-v7a)
   ```

3. 单测某一项

   ```bash
   run cts -m CtsCameraTestCases -t xxx (android.hardware.camera2.cts.CaptureResultTest#testCameraCaptureResultAllKeys[1])
   ```

# GSI 简介

------

GSI需要刷谷歌镜像，用cts的测试报工具测试

1. 刷镜像命令

   ```bash
   adb reboot fastboot
   fastboot flash system system.img
   fastboot reboot bootloader
   fastboot -w
   fastboot reboot
   ```

2. 常用测试命令

   ```bash
   run cts-on-gsi -m CtsCameraTestCases
   ```

# VTS 简介

------

VTS是要刷谷歌镜像和boot_debug.img,要用VTS的工具包测试

1. 刷镜像命令

   ```bash
   adb reboot fastboot
   fastboot fash system system.img
   fastboot reboot bootloader
   fastboot flash boot bootdebug.img
   fastboot -w
   fastboot reboot
   ```

2. 常用测试命令

   ```bash
   run vts -m VtsHalCameraProviderV2_4Target --skip-preconditions -s f5e4190f
   run vts -m VtsHalCameraProviderV2_5Target --skip-preconditions -s f5e4190f
   run vts -m VtsHalCameraServiceV2_0Target --skip-preconditions -s f5e4190f
   ```