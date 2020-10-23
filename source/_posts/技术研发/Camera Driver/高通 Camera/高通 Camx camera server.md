---
title: 高通 Camx camera server
toc: true
date: 2020-01-01 00:00:00
tags: Camx
---

### Camera Server

Camera Server 是一个独立的进程，对上通过AIDL来完成 Camera Framework 的一些请求；对下通过HIDL 将上层发下来的请求提交给 Camera Provider。

Camera Server 对 Camera Framework 而言属于 服务端

Camera Server 对 Camera Provider 而言属于 客户端

