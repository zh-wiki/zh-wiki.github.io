---
title: 高通 Camx Bring up
toc: true
date: 2020-01-01 00:00:30
tags: 高通Camx
---

# Bring Up Sensor

## HAL层的配置

1. 移植驱动代码到相应的路径

   vendor/qcom/proprietary/chi-cdk/oem/qcom/sensor/

   驱动文件名字根据项目而定

   <img src="%E9%AB%98%E9%80%9A%20Camx%20Bring%20up/image-20201111142550122.png" alt="驱动代码" style="zoom:200%;" />

2. sensor xml 相关配置

   <details>
   <summary>lime_sunny_hi259_macro_sensor.xml</summary>

   ```xml
    <slaveInfo>
       <!--Name of the sensor -->
       <sensorName>lime_sunny_hi259_macro</sensorName>
       <!--8-bit or 10-bit write slave address
           For External Sensors for which camx needs not probe the slave address shoule be as 0 -->
       <slaveAddress>0x60</slaveAddress>
       <!--Register address / data size in bytes -->
       <regAddrType range="[1,4]">2</regAddrType>
       <!--Register address / data size in bytes -->
       <regDataType range="[1,4]">2</regDataType>
       <!--Register address for sensor Id -->
       <sensorIdRegAddr>0x04</sensorIdRegAddr>
       <!--Sensor Id 0xE1-->
       <sensorId>0x113</sensorId>
       <!--Mask for sensor id. Sensor Id may only be few bits -->
       <sensorIdMask>4294967295</sensorIdMask>
       <!--I2C frequency mode of slave
           Supported modes are: STANDARD (100 KHz), FAST (400 KHz), FAST_PLUS (1 MHz), CUSTOM (Custom frequency in DTSI) -->
       <i2cFrequencyMode>FAST</i2cFrequencyMode>
       <!--Sequence of power configuration type and configuration value required to control power to the device -->
   
      <powerUpSequence>
         <powerSetting>
           <configType>RESET</configType>
           <configValue>1</configValue>
           <delayMs>1</delayMs>
         </powerSetting>
         <powerSetting>
           <configType>CUSTOM_GPIO1</configType>
           <configValue>1</configValue>
           <delayMs>0</delayMs>
         </powerSetting>
         <powerSetting>
           <configType>CUSTOM_GPIO2</configType>
           <configValue>1</configValue>
           <delayMs>2</delayMs>
         </powerSetting>
         <powerSetting>
           <configType>MCLK</configType>
           <configValue>24000000</configValue>
           <delayMs>8</delayMs>
         </powerSetting>
         <powerSetting>
           <configType>RESET</configType>
           <configValue>0</configValue>
           <delayMs>1</delayMs>
         </powerSetting>
       </powerUpSequence>
       <!--Sequence of power configuration type and configuration value required to control power to the device -->
       <powerDownSequence>
         <!--Power setting configuration
             Contains: configType, configValue and delay in milli seconds -->
         <powerSetting>
   		  <configType>RESET</configType>
           <configValue>1</configValue>
           <delayMs>1</delayMs>
         </powerSetting>
         <powerSetting>
           <configType>MCLK</configType>
           <configValue>0</configValue>
           <delayMs>0</delayMs>
         </powerSetting>
         <powerSetting>
           <configType>CUSTOM_GPIO1</configType>
           <configValue>0</configValue>
           <delayMs>0</delayMs>
         </powerSetting>
         <powerSetting>
           <configType>CUSTOM_GPIO2</configType>
           <configValue>0</configValue>
           <delayMs>1</delayMs>
         </powerSetting>
       </powerDownSequence>
     </slaveInfo>
   ```

   </details>

   - sensor name 跟sensor  文件夹名字一致
   - slaveAddress IIC 从机地址
   - sensor id 寄存器地址 以及 sensor id
   - 上下电时序 (为了保险首先将reset引脚设置为禁止状态)

3. module xml 配置

   <details>
   <summary>lime_sunny_hi259_macro_module.xml</summary>

   ```xml
   <?xml version="1.0" encoding="utf-8" ?>
   <!--========================================================================-->
   <!-- Copyright (c) 2018 Qualcomm Technologies, Inc.                         -->
   <!-- All Rights Reserved.                                                   -->
   <!-- Confidential and Proprietary - Qualcomm Technologies, Inc.             -->
   <!--========================================================================-->
   <cameraModuleData
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:noNamespaceSchemaLocation="..\..\..\api\sensor\camxmoduleconfig.xsd">
     <module_version major_revision="1" minor_revision="0" incr_revision="0"/>
   
       <!--Module group can contain either 1 module or 2 modules
         Dual camera, stereo camera use cases contain 2 modules in the group -->
     <moduleGroup>
       <!--Module configuration -->
       <moduleConfiguration description="Module configuration">
         <!--CameraId is the id to which DTSI node is mapped.
             Typically CameraId is the slot Id for non combo mode. -->
         <cameraId>3</cameraId>
         <!--Name of the module integrator -->
         <moduleName>sunny</moduleName>
         <!--Name of the sensor in the image sensor module -->
         <sensorName>lime_sunny_hi259_macro</sensorName>
         <!--Actuator name in the image sensor module
             This is an optional element. Skip this element if actuator is not present -->
         <actuatorName></actuatorName>
         <oisName></oisName>
         <!--EEPROM name in the image sensor module
             This is an optional element. Skip this element if EEPROM is not present -->
         <eepromName></eepromName>
         <!--Flash name is used to used to open binary.
             Binary name is of form flashName_flash.bin Ex:- pmic_flash.bin -->
         <flashName></flashName>
         <!--Chromatix name is used to used to open binary.
             Binary name is of the form sensor_model_chromatix.bin -->
         <chromatixName>lime_sunny_hi259_macro</chromatixName>
         <!--Position of the sensor module.
             Valid values are: REAR, FRONT, REAR_AUX, FRONT_AUX, EXTERNAL -->
         <position>REAR_AUX</position>
         <!--CSI Information -->
         <CSIInfo description="CSI Information">
             <laneAssign>2</laneAssign>
             <isComboMode>1</isComboMode>
         </CSIInfo>
         <!--Lens information -->
         <lensInfo description="Lens Information">
           <!--Focal length of the lens in millimeters. -->
           <focalLength>4.71</focalLength>
           <!--F-Number of the optical system. -->
           <fNumber>1.79</fNumber>
           <!--Minimum focus distance in meters. -->
           <minFocusDistance>0.1</minFocusDistance>
           <!--Total focus distance in meters. -->
           <maxFocusDistance>1.9</maxFocusDistance>
           <!--Horizontal view angle in degrees. -->
           <horizontalViewAngle>67</horizontalViewAngle>
           <!--Vertical view angle in degrees. -->
           <verticalViewAngle>53</verticalViewAngle>
           <!--Maximum Roll Degree. Valid values are: 0, 90, 180, 270, 360 -->
           <maxRollDegree>270</maxRollDegree>
           <!--Maximum Pitch Degree. Valid values are: 0 to 359 -->
           <maxPitchDegree>360</maxPitchDegree>
           <!--Maximum Yaw Degree. Valid values are: 0 to 359 -->
           <maxYawDegree>360</maxYawDegree>
         </lensInfo>
         <pdafName></pdafName>
       </moduleConfiguration>
     </moduleGroup>
   </cameraModuleData>
   ```

   </details>

   - 配置 CameraId 与kernel dts 相对应
   - 配置sensorname 与 sensor xml 保持一致
   - 配置 chromatixName 与 sensor name 保持一致
   - 配置 position 摄像头位置 前摄 后摄 或者 后辅
   - 配置 CSIInfo mipi 通道

# 双摄帧同步导通

1. 将camx平台默认的几个属性开启

   ```xml
    //camxsettings.xml      
   <VariableName>multiCameraEnable</VariableName>
   <VariableName>multiCameraHWSyncMask</VariableName>
   <VariableName>multiCameraFrameSyncMask</VariableName>
   <VariableName>multiCameraFPSMatchMask</VariableName>
   //高通的case还给了这两个，j19S项目代码中没有找到这连个配置，没有配置也是OK的
   adb shell "echo multiCamera3ASync=QTI >> /vendor/etc/camera/camxoverridesettings.txt"
   adb shell "echo multiCameraSATEnable=1 >> /vendor/etc/camera/camxoverridesettings.txt"
   ```

2. 在Camera Id 映射的位置指定双摄的Camera Id

   ```c++
   static LogicalCameraConfiguration logicalCameraConfigurationKamorta[] =
   {
       /*cameraId cameraType              exposeFlag phyDevCnt  sensorId, transition low, high, smoothZoom, alwaysOn  realtimeEngine            primarySensorID, hwMaster*/
       {0,        LogicalCameraType_Default, TRUE,      1,    {{0,                    0.0, 0.0,   FALSE,    TRUE,     RealtimeEngineType_IFE}},  0,              0    }, ///< Wide camera
       {1,        LogicalCameraType_Default, TRUE,      1,    {{2,                    0.0, 0.0,   FALSE,    TRUE,     RealtimeEngineType_IFE}},  2,              2    }, ///< Front camera
       {2,        LogicalCameraType_Default, TRUE,      1,    {{1,                    0.0, 0.0,   FALSE,    TRUE,     RealtimeEngineType_IFE}},  1,              1    }, ///< Tele camera
       {3,        LogicalCameraType_Default, TRUE,      1,    {{3,                    0.0, 0.0,   FALSE,    TRUE,     RealtimeEngineType_IFE}},  3,              3    },
       {4,        LogicalCameraType_RTB,     TRUE,      2,    {{0,                    2.0, 8.0,   FALSE,    TRUE,     RealtimeEngineType_IFE},
                                                               {2,                    1.0, 2.0,   FALSE,    TRUE,     RealtimeEngineType_IFE}},  0,              0    }, ///< RTB
   };
   ```

   在j19S项目中更改了一下参数 。（双摄预览出图是辐摄）

   - 第一个参数: 调节zoom值
   - 第二个参数: 配置主摄的camera Id

   ![双摄帧同步](%E9%AB%98%E9%80%9A%20Camx%20Bring%20up/image-20201112172851742.png)

   在j19S项目中还有存在一个平台bug （上面介绍的结构体双摄不能为最后一个成员）

   高通给的patch

   ```c++
   //vendor/qcom/proprietary/chi-cdk / oem/qcom/feature2/chifeature2graphselector/chifeature2graphselector.cpp
   VOID ChiFeature2GraphSelector::BuildCameraIdSet()
   {
       //Add by junwei.zhou according Qcom case num 04763737
       //fix platform design
   #ifdef __XIAOMI_CAMERA__
       m_cameraIdMap.insert({ { cameraIdSetSingle },  SINGLE_CAMERA });
       m_cameraIdMap.insert({ { cameraIdSetBokeh },   BOKEH_CAMERA });
       m_cameraIdMap.insert({ { cameraIdSetMulti },   MULTI_CAMERA });
       m_cameraIdMap.insert({ { cameraIdSetFusion },  FUSION_CAMERA });
   #else
       m_cameraIdMap.insert({ { cameraIdSetSingle },  SINGLE_CAMERA });
       m_cameraIdMap.insert({ { cameraIdSetMulti },   MULTI_CAMERA });
       m_cameraIdMap.insert({ { cameraIdSetBokeh },   BOKEH_CAMERA });
       m_cameraIdMap.insert({ { cameraIdSetFusion },  FUSION_CAMERA });
   #endif
   }
   ```

3. 分别配置主摄和辅摄的setting

   - 主摄：masterSettings

   - 辐摄：slaveSettings

# Dump EEprom Data

```bash
adb shell "echo dumpSensorEEPROMData=1 >> /vendor/etc/camera/camxoverridesettings.txt"
```

数据存放位置： **/data/vendor/camera/xxx_kbuffer_OTP.txt**

