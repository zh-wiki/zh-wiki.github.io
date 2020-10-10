---
title: 高通 Camx capture request 代码流程
toc: true
date: 2020-01-01 00:00:02
tags: 
---

### 预览和拍照的代码流程

```c++
chi_override_process_request() //chxextensioninterface.cpp 
	OverrideProcessRequest()   //chxextensionmodule.cpp 
    	ProcessCaptureRequest()//chxusecase.cpp
    		ExecuteCaptureRequest() //chxadvancedcamerausecase.cpp
    			result = pFeature->ExecuteProcessRequest(pRequest); //会调到chifeature2wrapper.cpp:494 ExecuteProcessRequest()
    			ExecuteProcessRequest() //chifeature2wrapper.cpp 开始进入算法的领域
                    SubmitRequestToSession() //经过一系类调用会走到 chifeature2base.cpp 
                    	 result = ExtensionModule::GetInstance()->ActivatePipeline() 
                    	 OnSubmitRequestToSession()
                    		ProcessFeatureMessage()
                    ProcessMessageCb() //通过回调又重新回到 chifeature2wrapper.cpp 
                    	result = pFeature2Wrapper->m_pUsecaseBase->SubmitRequest(&submitRequest); //将 request 下到 camx session 中  	
```

CHI feature 通过 usecase 提交 request 到 session, 套路还是一样的（chxextensionmodule.cpp 通过这条链路转到Camx）

```c++
result = pSession->ProcessCaptureRequest(pRequest); //camxchicontext.cpp feature submit request 会调到这里从这里开始步入 session
	CamxResult Session::ProcessCaptureRequest(); //camxsession.cpp 
```

