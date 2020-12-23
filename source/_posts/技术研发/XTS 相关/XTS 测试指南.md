---
title: XTS 测试指南
toc: true
date: 2020-00-00 00:00:00
tags: XTS
---

# CTS 简介

------

## 描述

通过Google CTS兼容性测试工具，对安卓系统进行测试，检查系统是否符合兼容性规范，找出系统兼容性问题，提升系统稳定性。

APP 层与 Framework 层在设计上是分开的， 但通过 CTS 测试，确保了 APP 与 Android Framework 之间有一致的调用接口（API），这使得 APP 开发者编写的同一款程序可以运行在不同系统版本（向前兼容）、不同硬件平台、不同厂商制造的不同设备上。

CTS全称 Compatibility Test Suite 兼容性测试工具

- 让APP提供更好的用户体验。用户可以选择更多的适合自己设备的APP。让APP更稳定。
- 让开发者设计更高质量的APP。
- 通过CTS的设备可以运行Android market。

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

4. retry 命令

   ```bash
   l r #获取测试session
   run retry --retry sessionID -s 设备号
   ```

   

# GSI 简介

------

## 描述

GSI(Generic System Image)通用系统镜像是在所有安卓手机上可以通用的系统，不需要适配不同手机。

GSI需要刷谷歌镜像，用cts的测试报工具测试（img一般由供应商提供，或者google定期提供给手机厂商）

## 常用测试命令

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

## 描述

VTS的全称是 Vendor Test Suite（供应商测试套件）。

安卓 Project Treble 中引入 Vendor Interface 的目的是将 Android Framework 与 HAL 分开，并通过 VTS 测试来对这些 Vendor Interface 进行测试以确保 HAL 的向前兼容。

 VTS 类似 CTS，通过对 Vendor Interface 进行测试，确保同一个版本的 Android Framework 可以运行在不同 HAL 上，或不同 Android Framework 可以运行在 同一个 HAL 上。确保Framework / HAL 接口的一致性，可以直接对 Framework 进行升级而不用考虑 HAL 层的改动，从而缩短了用户手上设备得到系统升级 OTA 推送的时间。

VTS是要刷谷歌镜像和boot_debug.img,要用VTS的工具包测试

## 常用测试命令

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





> 博客推荐
>
> https://zhuanlan.zhihu.com/p/28301953
>
> https://cloud.tencent.com/developer/article/1662018

