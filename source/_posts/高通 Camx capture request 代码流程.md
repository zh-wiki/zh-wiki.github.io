---
title: 高通 Camx capture request 代码流程
toc: true
date: 2020-09-29 23:23:09
tags: 
categories:
- 技术研发
- Android Camera Driver
- 高通 Camera
---

### 预览和拍照的代码流程

```c++
chi_override_process_request() //chxextensioninterface.cpp 
	OverrideProcessRequest()   //chxextensionmodule.cpp 
    	ProcessCaptureRequest()//chxusecase.cpp
    		ExecuteCaptureRequest() //chxadvancedcamerausecase.cpp
    			result = pFeature->ExecuteProcessRequest(pRequest); //会调到chifeature2wrapper.cpp:494 ExecuteProcessRequest()
    			ExecuteProcessRequest() //chifeature2wrapper.cpp
    	
```

