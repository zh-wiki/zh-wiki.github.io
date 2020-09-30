---
title: Ubuntu 开发环境的搭建
toc: true
date: 2020-09-29 23:23:46
tags:
categories:
- 计算机基础知识
---

## VirtualBox 修复'modprobe vboxdrv' 报错

1. 问题发生背景 

   Linux 内核版本升级之后，virtualbox 的驱动没有更新成功。

2. 解决方法

   1. 更新整个系统

      ```bash
      sudo apt update
      sudo apt upgrade
      ```

   2. 重新安装对应内核版本的头文件,和virtualbox的驱动

      ```bash
      sudo apt install --reinstall linux-headers-$(uname -r) virtualbox-dkms dkms
      ```

   3. 加载驱动重启

      ```bash
      sudo modprobe vboxdrv
      reboot
      ```

   

   