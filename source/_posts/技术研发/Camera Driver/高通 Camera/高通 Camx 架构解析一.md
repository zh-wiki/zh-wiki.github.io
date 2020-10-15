---
title: 高通 Camx 架构解析一
toc: true
date: 2020-01-01 00:00:00
tags: 
---

### Camera Server

Camera Server 是一个独立的进程，对上通过AIDL来完成 Camera Framework 的一些请求；对下通过HIDL 将上层发下来的请求提交给 Camera Provider。

Camera Server 对 Camera Framework 而言属于 服务端

Camera Server 对 Camera Provider 而言属于 客户端

![Camera Server](%E9%AB%98%E9%80%9A%20Camx%20%E6%9E%B6%E6%9E%84%E8%A7%A3%E6%9E%90%E4%B8%80/image-20201014172140989.png)



