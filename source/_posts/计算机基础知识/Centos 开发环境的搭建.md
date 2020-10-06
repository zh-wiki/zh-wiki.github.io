---
title: Centos 开发环境的搭建
toc: true
date: 2020-01-01 00:00:02
tags:
---

## 同一网段外部浏览器不能访问Tomcat

1. 问题产生背景和原因

   背景：服务器已经安装好tomcat, 服务器主机通过 **ip+8080** 的方式进行访问, 但是其他在同一网段下的客户端机器通过同样方式不能访问.

   原因：服务器未将 8080 端口进行开放

2. 解决方法

   1)查看防火墙状态

   ```bash
   firewall-cmd --state
   ```

   2)添加需要开放的端口

   ```bash
   firewall-cmd --permanent --zone=public --add-port=8080/tcp
   ```

   3)加载配置使其生效

   ```bash
   firewall-cmd --reload
   ```

   4)查看配置是否生效

   ```bash
   firewall-cmd --permanent --zone=public --list-ports
   ```

   5)重新访问 Tomcat **(IP+8080)** 

## 防火墙的相关操作

1. 开启防火墙的命令  

   ```bash
   systemctl start firewalld.service
   ```

2. 关闭防火墙的命令

   ```bash
   systemctl stop firewalld.service
   ```

3. 开机自动启动

   ```bash
   systemctl enable firewalld.service
   ```

4. 关闭开机自动启动

   ```bash
   systemctl disable firewalld.service
   ```

5. 查看防火墙状态

   ```bash
   systemctl status firewalld
   ```

   

