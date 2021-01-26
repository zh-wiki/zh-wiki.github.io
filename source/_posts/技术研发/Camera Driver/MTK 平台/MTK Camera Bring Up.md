---
title: MTK Camera Bring Up
toc: true
date: 2020-00-00 00:00:00
tags: MTK Camera
---

https://online.mediatek.com/_layouts/15/mol/portal/ext/ECMLogin.aspx?ReturnUrl=%2f_layouts%2f15%2fAuthenticate.aspx%3fSource%3d%252FFAQ&Source=%2FFAQ&confirm=true#/SW/FAQ21886

# Camera Driver 文件概览

------

<style type="text/css">
.tg  {border-collapse:collapse;border-color:#ccc;border-spacing:0;}
.tg td{background-color:#fff;border-color:#ccc;border-style:solid;border-width:1px;color:#333;
  font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;word-break:normal;}
.tg th{background-color:#f0f0f0;border-color:#ccc;border-style:solid;border-width:1px;color:#333;
  font-family:Arial, sans-serif;font-size:14px;font-weight:normal;overflow:hidden;padding:10px 5px;word-break:normal;}
.tg .tg-9wq8{border-color:inherit;text-align:center;vertical-align:middle}
.tg .tg-c3ow{border-color:inherit;text-align:center;vertical-align:top}
.tg .tg-0pky{border-color:inherit;text-align:left;vertical-align:top}
</style>
<table class="tg">
<thead>
  <tr>
    <th class="tg-c3ow">分类</th>
    <th class="tg-c3ow">路径</th>
    <th class="tg-c3ow">描述</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td class="tg-9wq8">配置文件</td>
    <td class="tg-0pky"><span style="font-weight:400;font-style:normal">device/mediatek/${project}/PorjectConfig.mk</span><br><span style="font-weight:400;font-style:normal">Kernel-4.4/arch/arm64/configs/ * defconfig *</span></td>
    <td class="tg-9wq8">应该是编译相关</td>
  </tr>
  <tr>
    <td class="tg-9wq8">Kernel Driver</td>
    <td class="tg-0pky">kernel-4.4/drivers/misc/mediatek/imgsensor/src/${platform}/ * mipi_raw *<br>kernel-4.4/drivers/misc/mediatek/imgsensor/src/mt6763/imgsensor_sensor_list.c <br><span style="font-weight:400;font-style:normal">kernel-4.4/drivers/misc/mediatek/imgsensor/src/mt6763/imgsensor_sensor_list.h</span><br>kernel-4.4/drivers/misc/mediatek/imgsensor/inc/kd_imgsensor.h<br>kernel-4.4/drivers/misc/mediatek/imgsensor/src/mk6763/camera_hw/imgsensor_cofg_table.c</td>
    <td class="tg-9wq8">内核驱动相关</td>
  </tr>
  <tr>
    <td class="tg-9wq8">Hal Driver</td>
    <td class="tg-0pky"><span style="font-weight:400;font-style:normal">vendor/mediatek/proprietary/custom/${platform}/hal/imgsensor/ * mipi_raw */</span><br><span style="font-weight:400;font-style:normal">vendor/mediatek/proprietary/custom/${platform}/hal/imgsensor_src/sensorlist.cpp/</span><br><span style="font-weight:400;font-style:normal">vendor/mediatek/proprietary/custom/${platform}/hal/sendepfeature/ * mipi_raw */</span></td>
    <td class="tg-9wq8">Hal 驱动相关</td>
  </tr>
</tbody>
</table>

