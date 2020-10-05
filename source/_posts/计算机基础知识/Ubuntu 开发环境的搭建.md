---
title: Ubuntu 开发环境的搭建
toc: true
date: 2020-01-01 00:00:00
tags:
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


3. 注意事项

   更新驱动的时候，会重新编译驱动，所以要选择对应的gcc编译器，太老的估计会凉。

## 支持多版本的gcc

1. 系统安装ok后默认gcc 版本是 v-7.x。我们先搞一个低版本的gcc

   ```bash
   sudo apt-get install gcc-4.8
   sudo apt-get install g++-4.8
   sudo ln -sf /usr/bin/g++-4.8 /usr/bin/g++
   sudo ln -sf /usr/bin/gcc-4.8 /usr/bin/gcc
   ```

2. 管理多个版本的gcc

   1. 查看存在几个版本的gcc

      ```bash
      ls -l /usr/bin/gcc
      ```

   2. 分别为gcc和g++添加管理组

      ```bash
      sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 40
      sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 40
      ```

   3. 能添加就能删除,从管理组中删除

      ```bash
      sudo update-alternatives --remove gcc /usr/bin/gcc-4.8
      ```

3. 设置ok使用以下指令选择gcc的版本

   ```bash
   sudo update-alternatives --config gcc
   sudo update-alternatives --config g++
   ```