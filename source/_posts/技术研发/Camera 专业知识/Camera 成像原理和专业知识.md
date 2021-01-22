---
title: Camera 成像原理和专业知识
toc: true
date: 2021-01-21 09:52:01
tags: Camera
---

# Camera 模组

------

1. 基本介绍

   - 一个camera主要由两部分组成，镜头(Lens)，感光IC(Sensor IC)。其中大部分的Sensor都是自己集成DSP的。

   - Sensor将Lens上传导过来的光线转换为电信号，通过CFA滤波后，变为三基色，再通过内部的DA转换为数字信号。对于CFA模式的相机来说，Sensor中的每个pixel只能感光R光/B光/G光，因此每个像素此时存贮的都是单色的。

   - 一个camera的输出信号：

     一般有data信号，输出YUV，RGB，JPEG格式的数据。

     hsync信号，行同步信号，表示一个frame有效。

     vsync信号，列同步信号，对于一个frame表示新的一行有效。

     PCLK信号，每一个像素的同步时钟。

     输出I2C总线，主要用在通信，寄存器配置。

# 彩色滤波阵列-CFA

------

图像传感器都采用一定的模式来采集图像数据，常用的有 RGB 模式和 CFA 模式。BGR 模式是一种可直接进行显示和压缩等处理的图像数据模式，它由 R( 红)、G( 绿) 、B( 蓝) 三原色值来共同确定 1 个像素点，例如富士数码相机采用的 SUPER CCD 图像传感器就采用这种模式，其优点是图像传感器产生的图像数据无需插值就可直接进行显示等后续处理，图像效果最好，但是成本高，常用于专业相机中。

为了减少成本，缩小体积，市场上的数码相机大多采用 CFA 模式，即在像素阵列的表面覆盖一层彩色滤波阵列（Color Filter Array，CFA），彩色滤波阵列有多种，现在应用最广泛的是 Bayer 格式滤波阵列，满足 GRBG 规律，绿色像素数是红色或蓝色像素数的两倍，这是因为人眼对可见光光谱敏感度的峰值位于中波段，这正好对应着绿色光谱成分。在该模式下图像数据只用R, G, B三个值中的一个值来表示一个像素点，而缺失另外两个颜色值，这时得到的是一副马赛克图片，为了得到全彩色的图像，需要使用其周围像素点的色彩信息来估计缺失的另外两种颜色，这种处理叫做色彩插值。

# 相位对焦 PDAF (Phase Detection Auto Focus)

------



1. **简介**

   在CMOS（感光元件）上留出一些成对儿的遮蔽像素点来进行相位检测，即从像素传感器上拿出左右相对的成对像素点，分别对场景中的物体进行进光量等信息的检测，通过比对左右两侧的相关值情况，对焦系统根据判断信号波峰的位置可判断出镜头应该往前还是往后偏移，便会迅速找出准确的对焦点，之后镜间马达便会一次性将镜片推动到相应位置完成对焦。

2. **对焦的基本过程**

   - 通过左右(屏蔽像素点)shield pixel之间的差异来将被摄物映射到镜头移动距离中的某个位置。
   - 系统在进行对焦的时候，需要将检测到的相位差(phase difference)转换为离焦率(Defocus Value)，这个转换过程应用到的表单数据称为DCC(defocus conversion coefficient)离焦转换系数。

# Camera 尺寸相关

------

我们在追Camera configureStream 流程的时候一般会看到以下关键字

```c++
HAL_PIXEL_FORMAT_BLOB = 33;
HAL_PIXEL_FORMAT_IMPLEMENTATION_DEFINED = 34;
HAL_PIXEL_FORMAT_YCbCr_420_888 = 35;
```

- HAL_PIXEL_FORMAT_BLOB表示是jpeg stream，对应的size即平时所说的picture size
- HAL_PIXEL_FORMAT_IMPLEMENTATION_DEFINED表示preview stream，对应的size即平时所说的preview size.