---
title: 高通 Camx Bring up
toc: true
date: 2020-01-01 00:00:30
tags: Camx
---

### Dump EEprom Data

```bash
adb shell "echo dumpSensorEEPROMData=1 >> /vendor/etc/camera/camxoverridesettings.txt"
```

数据存放位置： **/data/vendor/camera/xxx_kbuffer_OTP.txt**

