---
title: Arch Linux 开发环境的搭建
toc: true
date: 2020-01-01 00:00:03
tags:
---



## Arch Linux 系统安装

主要进行分区，系统的安装，图形服务和必要驱动的安装

### 分区

1. 查看当前分区信息

   ```bash
   fdisk -l
   ```

2. 设置分区

   ```bash
   cfdisk /dev/sda
   ```

   1)首先选择分区类型

   ​	MBR 选择 dos	

   ​	GPT  选择 gpt 

    2)MBR启动一般分为2个分区

   ​	主分区   （选择为boot标志）

   ​	交换分区（内存的2倍）

3. 格式化分区

   格式化主分区

   ```bash
   mkfs.ext4 /dev/sda1
   ```

   格式化交换分区

   ```bash
   mkswap /dev/sda2
   ```

   启动交换分区

   ```bash
   swapon /dev/sda2
   ```

4. 挂载分区

   ```bash
   mount /dev/sda1 /mnt
   ```

### 编辑镜像源

```bash
vim /etc/pacman.d/mirrorlist
```

将中国的源放在文件的开头

### 安装系统基本组件

```bash
pacstrap /mnt base linus linux-firmware
```

### 安装基本开发工具包

```bash
arch-chroot /mnt
pacman -S base-devel
```

### 安装 sudo

```bash
arch-chroot /mnt
pacman -S sudo vi vim
visudo
```

删除这一行注释 **%wheel ALL = (ALL) ALL**

### 创建用户

```bash
arch-chroot /mnt
useradd -G wheel -m 用户名
```

### 安装 Grub

```bash
arch-chroot /mnt
pacman -S grub
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
```

### 生成 fstab

该配置不需要 arch-chroot 

```bash
genfstab /mnt > /mnt/etc/fstab
```

### 安装 Xorg 图形管理

```bash
pacstrap /mnt xorg-server xorg-xinit xorg-apps
```

### 安装网络组件

```bash
pacstrap /mnt dhcpcd wpa_supplicant networkmanager
arch-chroot /mnt
systemctl enable dhcpcd
systemctl enable wpa_supplicant
systemctl enable networkmanager
```

### 安装显卡驱动

```bash
lspci | grep VGA				//查看显卡是什么型号
pacman -S xf86-video-intel	  //intel 显卡驱动
```

### 安装音频组件

```bash
pacstrap /mnt alsa-utils pulseaudio
pacstrap /mnt pulseaudio-alsa
```

------

## Arch Linux 桌面环境安装

### 窗口管理器 dwm 

1. 安装终端内置浏览器 **w3m**

   ```bash
   sudo pacman -S w3m
   ```

2. 下载 **dwm**

   ```bash
   w3m suckless.org
   ```

3. 安装

   ```bash
   sudo make clean install
   ```

4. 运行dwm

   ```bash
   vim ~/.xinitrc
   startx
   ```
   
   在 **.xinitrc** 中 加入 **exec dwm**
   
   ------
   
   
## Arch Linux 基础配置

###    安装中文字体

   ```bash
   sudo pacman -S noto-fonts noto-fonts-cjk noto-fonts-emoji
   sudo vim /etc/locale.gen
   ```

取消 **/etc/locale.gen** 中 以下 的注释

- en_US.UTF-8 UTF-8

- zh_CN.UTF-8 UTF-8

- zh_TW.UTF-8 UTF-8

生成 locale

```bash
sudo locale-gen
```

### 设置 archlinuxcn

```bash
sudo vim /etc/pacman.conf
sudo pacman -Sy
sudo pacman -S archlinuxcn-keyring
```

在文件的末尾插入

[archlinuxcn]

Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch

### 安装 Chrome

```bash
sudo pacman -S google-chrome
```

### 安装中文输入法

1. 安装输入法以及配置工具

   ```bash
   sudo pacman -S fcitx fcitx-im kcm-fcitx fcitx-qt5 fcitx-gtk2 fcitx-gtk3 fcitx-configtool
   ```

2. 配置输入法

   ```bash
   vim ~/.xprofile
   ```

   输入以下内容

   export GTK_IM_MODULE=fcitx 
   export QT_IM_MODULE=fcitx 
   export XMODIFIERS="@im=fcitx"

### SSH 的安装与配置

```bash
pacman -Sy openssh
ssh-keygen -t rsa -C "xxxxx@xxxxx.com"
```

