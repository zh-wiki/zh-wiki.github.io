---
title: ADB 常用命令
toc: true
date: 2020-01-01 00:00:00
tags: 
---

## 通用命令

### 检测usb设备

```bash
adb wait-for-usb-device
```

### 属性相关

```bash
adb shell setprop 属性名
adb shell getprop
adb shell getprop | grep -i xxx
```

### 安装与卸载apk

```bash
adb install xxx.apk
adb uninstall com.xxx.xxx
adb shell pm list packages | grep xxx
```

### 设置屏幕

```bash
adb shell input keyevent 26
```

## Cam相关指令

###  dump camera的相关信息

```bash
adb shell dumpsys media.camera > cam
```

###  查看camera个数

```bash
watch -n 1 -d "adb shell dumpsys media.camera|grep Number"
```

###  打开摄像头

```bash
adb shell am start -a android.media.action.STILL_IMAGE_CAMERA
```

### 打开前置摄像头

```bash
adb shell am start -a android.media.action.IMAGE_CAPTURE --ei android.intent.extras.CAMERA_FACING 1
```



## 高通平台 Camera 相关

### 开启高通相机选择camera id

```bash
adb shell setprop persist.sys.camera.devoption.debug 100
```

### 使能多摄像

```bash
adb shell setprop persist.vendor.camera.multicam 1
```

### 开启支持多摄的权限

```bash
adb shell setprop vendor.camera.aux.packagelist org.codeaurora.snapcam
adb shell setprop persist.vendor.camera.privapp.list org.codeaurora.snapcam
adb shell setprop vendor.camera.aux.packagelist "org.codeaurora.snapcam,com.huaqin.cameraautotest,com.huaqin.factory"
```

### 高通 Camx 杀死 camera 进程

```bash
adb shell ps -A|grep camera |awk '{print $2}'|xargs adb shell kill -9
```

命令解释:

1. awk '{print $2}' 

   这个命令会把 **ps -A | grep camera** 得出的进程id 输出到终端 （$2 是第二字段也就是 进程id）
   
   <img src="ADB%20%E5%B8%B8%E7%94%A8%E5%91%BD%E4%BB%A4/image-20201016145122015.png" alt="例图" style="zoom:200%;" />    

2. xargs adb shell kill -9

   这个命令会把 awk 获取到的线程id 当做参数传递给 **kill -9** 这个命令

### 高通 Camx dump metadata 

```bash
adb shell dumpsys media.camera >meta.log   
```

## ADB 常见问题

### ADB 连接不上报以下错误

<img src="ADB%20%E5%B8%B8%E7%94%A8%E5%91%BD%E4%BB%A4/20200824114458995.png" alt="adb devices" style="zoom:200%;" />

解决方法：

```bash
cd /etc/udev/rules.d
sudo vim 51-android.rules
```

在文件中写入：
SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", MODE="0666"