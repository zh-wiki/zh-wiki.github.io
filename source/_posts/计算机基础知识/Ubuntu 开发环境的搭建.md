---
title: Ubuntu 开发环境的搭建
toc: true
date: 2020-01-01 00:00:00
tags: Ubuntu
---

# Samba 服务共享目录

------

添加以下配置 /etc/samba/smb.conf

```bash
[文件夹名]
	path = #目录路径
	browseable = ye   #可查看共享文件
	guest ok = yes        #所有人均可访问共享目录
	writable = yes        #允许写入
	public = yes            #允许匿名用户访问
```

配置结束重启服务

```bash
sudo service smbd restart
```

# ubuntu18.04 virtualBox windows 支持usb

------



1. 执行命令
   sudo usermod -aG vboxusers 用户名（让virtualbox 能识别到主机的usb）

2. cat /etc/group | grep vboxusers （查看是否已经添加成功）

3. 下载插件 [下载链接](https://download.java.net/virtualbox/).

4. 下载插件比较慢，已经提前下载好的。适用于（virtualbox 5.2.34) 

5. 安装插件

   ![操作示意图](Ubuntu%20%E5%BC%80%E5%8F%91%E7%8E%AF%E5%A2%83%E7%9A%84%E6%90%AD%E5%BB%BA/image-20201111105153041.png)

6. 设置 USB 协议的支持

   ![操作示意图](Ubuntu%20%E5%BC%80%E5%8F%91%E7%8E%AF%E5%A2%83%E7%9A%84%E6%90%AD%E5%BB%BA/image-20201111105232574.png)

7. reboot （重启ubuntu）

8. 如果重启电脑之后，虚拟机可以扫描到USB设备，但是Ｗin7中提示驱动未能安装成功。
   解决方法：
   下载驱动精灵。安装USB驱动。

# VirtualBox 修复'modprobe vboxdrv' 报错

------



1. 问题发生背景 

   Linux 内核版本升级之后，virtualbox 的驱动没有更新成功。

2. 解决方法

   a.更新整个系统

   ```bash
   sudo apt update
   sudo apt upgrade
   ```

   b.重新安装对应内核版本的头文件,和virtualbox的驱动

   ```bash
   sudo apt install --reinstall linux-headers-$(uname -r) virtualbox-dkms dkms
   ```

   c.加载驱动重启

   ```bash
   sudo modprobe vboxdrv
   reboot
   ```


3. 注意事项

   更新驱动的时候，会重新编译驱动，所以要选择对应的gcc编译器，太老的估计会凉。

# 支持多版本的gcc

------



1. 系统安装ok后默认gcc 版本是 v-7.x。我们先搞一个低版本的gcc

   ```bash
   sudo apt-get install gcc-4.8
   sudo apt-get install g++-4.8
   sudo ln -sf /usr/bin/g++-4.8 /usr/bin/g++
   sudo ln -sf /usr/bin/gcc-4.8 /usr/bin/gcc
   ```

2. 管理多个版本的gcc

   a.查看存在几个版本的gcc

   ```bash
   ls -l /usr/bin/gcc
   ```

   b.分别为gcc和g++添加管理组

   ```bash
   sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 40
   sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 40
   ```

   c.能添加就能删除,从管理组中删除

   ```bash
   sudo update-alternatives --remove gcc /usr/bin/gcc-4.8
   ```

3. 设置ok使用以下指令选择gcc的版本

   ```bash
   sudo update-alternatives --config gcc
   sudo update-alternatives --config g++
   ```

# 安装多版本的jdk

------



1. 首先到官网下载jdk源码包

   [JDK官网](http://www.oracle.com/technetwork/java/javase/downloads/index.html)

   [华为JDK网址](https://mirrors.huaweicloud.com/java/jdk/)

2. 安装jdk

   ```bash
   sudo mkdir /usr/lib/jvm
   sudo tar -zxvf jdk-7u60-linux-x64.gz -C /usr/lib/jvm #//将jdk包复制到该目录进行解压
   ```

3. 将jdk注册到系统方便多版本jdk进行切换

   ```bash
   #只需要将下面的命令中jdk的路径换为自己对应版本的路径就好了
   sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/jdk1.8.0_191/bin/java 300
   sudo update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/jdk1.8.0_191/bin/javac 300
   ```

4. 系统中切换jdk或者javac

   ```bash
   sudo update-alternatives --config java
   sudo update-alternatives --config javac
   ```

   

