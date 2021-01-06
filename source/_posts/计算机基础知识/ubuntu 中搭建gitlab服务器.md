---
title: Ubuntu 中搭建gitlab服务器
toc: true
date: 2020-01-01 00:00:00
tags: Ubuntu
---

# GitLab 服务器简介

------

1. 什么是gitlab？

   gitlab 和 githab 是一样的。只不过gitlab 适用于公司内部，服务器是搭建在本地的。有利于项目的保密。

2. 为什么搭建gitlab, 有什么作用？

   我们现在使用的wiki知识系统，用的是一种比较粗暴的手段，每个人都可以提交。提交进去就会直接入库。只能通过git log 查看提交记录。

   时间长了不方便管理。对每个人的权限不好进行管控。

   gitlab 有点类似我们日常工作的gerrit.

   - 可以管理我们每个人的权限
   - 管理项目的分支。方便查看提交记录。
   - 可以指定管理员进行管理每笔提交是否进行合入

# GitLab 的搭建

------

1. 安装依赖包

   ```bash
   sudo apt-get install curl openssh-server ca-certificates postfix
   ```

2. 添加镜像源

   ```bash
   vi /etc/apt/sources.list.d/gitlab-ce.list
   #添加以下内容
   deb https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu xenial main
   ```

3. 安装gitlab-ce

   ```bash
   sudo apt-get update
   sudo apt-get install gitlab-ce
   ```

4. gitlab 常用命令

   ```bash
   sudo gitlab-ctl start
   sudo gitlab-ctl stop
   sudo gitlab-ctl restart
   ```

gitlab 比较耗费系统资源，所以不要在自己的电脑上进行操作。最好找一台服务器。

# GitLab 的使用

------

## 注册账户

请严格按照以下格式进行填写

- Username ：华勤员工工号
- Email：公司邮箱地址

![image-20201230111606977](ubuntu%20%E4%B8%AD%E6%90%AD%E5%BB%BAgitlab%E6%9C%8D%E5%8A%A1%E5%99%A8/image-20201230111606977.png)

## 个人设置

点击右上方用户图标进入设置界面

配置以下内容

- ssh 配置（必须配置）
- 语言（中文）偏好设置的最下方
- 标题栏 

![配置内容](ubuntu%20%E4%B8%AD%E6%90%AD%E5%BB%BAgitlab%E6%9C%8D%E5%8A%A1%E5%99%A8/image-20201230112706901.png)

## 管理员配置

管理员可以很好的管理自己项目，用户，以及组别

![管理员设置](ubuntu%20%E4%B8%AD%E6%90%AD%E5%BB%BAgitlab%E6%9C%8D%E5%8A%A1%E5%99%A8/image-20201230113100934.png)

### 创建团队

1. 点击上图Groups 下方的 New group 即可创建团队

   ![项目团队](ubuntu%20%E4%B8%AD%E6%90%AD%E5%BB%BAgitlab%E6%9C%8D%E5%8A%A1%E5%99%A8/image-20201230113438885.png)

### 创建项目

1. 点击上图中的新建项目

   ![新建项目](ubuntu%20%E4%B8%AD%E6%90%AD%E5%BB%BAgitlab%E6%9C%8D%E5%8A%A1%E5%99%A8/image-20201230114015167.png)

2. 项目成员管理

   可以指定项目成员，成员角色，访问日期

   ![成员设置](ubuntu%20%E4%B8%AD%E6%90%AD%E5%BB%BAgitlab%E6%9C%8D%E5%8A%A1%E5%99%A8/image-20201230114254108.png)

## 研发工作

1. 管理员创建好项目，将组员添加好之后，组员们登录自己用户会看到该项目。

2. 组员需要将该项目派生到自己的项目中。应该在项目列表中会发现有两个相同的项目，但是owner不一样。

   ![派生项目](ubuntu%20%E4%B8%AD%E6%90%AD%E5%BB%BAgitlab%E6%9C%8D%E5%8A%A1%E5%99%A8/image-20201230122133611.png)

3. 克隆自己派生出来的那一套到自己的电脑本地。以后我们就是在这套代码上进行修改了。修改后提交代码。正常的git 操作

   ![克隆项目](ubuntu%20%E4%B8%AD%E6%90%AD%E5%BB%BAgitlab%E6%9C%8D%E5%8A%A1%E5%99%A8/image-20201230122413700.png)

4. 确认没问题之后，提交merge请求。

   ![提交请求](ubuntu%20%E4%B8%AD%E6%90%AD%E5%BB%BAgitlab%E6%9C%8D%E5%8A%A1%E5%99%A8/image-20201230123053576.png)

   完善请求信息指定reviewer 

   ![image-20201230123255910](ubuntu%20%E4%B8%AD%E6%90%AD%E5%BB%BAgitlab%E6%9C%8D%E5%8A%A1%E5%99%A8/image-20201230123255910.png)

   信息填写ok ，之后可以submit .当然也可一check一下自己的更改

   ![submi](ubuntu%20%E4%B8%AD%E6%90%AD%E5%BB%BAgitlab%E6%9C%8D%E5%8A%A1%E5%99%A8/image-20201230123527918.png)

5. 开发者指定的review者会收到消息

   ![get request](ubuntu%20%E4%B8%AD%E6%90%AD%E5%BB%BAgitlab%E6%9C%8D%E5%8A%A1%E5%99%A8/image-20201230123941326.png)

   review 可以check一下相关内容，没什么问题，可以合并。也可以点赞，加评论鼓舞士气。

   ![image-20201230124123877](ubuntu%20%E4%B8%AD%E6%90%AD%E5%BB%BAgitlab%E6%9C%8D%E5%8A%A1%E5%99%A8/image-20201230124123877.png)

   ![merge success](ubuntu%20%E4%B8%AD%E6%90%AD%E5%BB%BAgitlab%E6%9C%8D%E5%8A%A1%E5%99%A8/image-20201230124353237.png)

# 项目派生的简介

------

1. 管理员创建好项目默认是master分支，除了管理员其他人一律不能push, 只能是通过merge.

2. 所以说开发者必须在该项目的基础上派生一个出来。单独开发(可以理解为不同的用户创建不同的专属分支)

3. 这样的话，既不会影响基线上的项目，也不会影响别人的分支。你只是在自己派生出来的这个项目上折腾。

4. 那么问题来了，比如说管理员创建一个项目。甲和乙同事派生的项目。

   - 甲提交代码入库了。

   - 此时乙的代码已经不是最新了。即使你 git pull 也是拉的你派生的代码，并不是基线上的。执行一下指令，发现本地只有自己派生出来的远程分支，那么我们只要添加管理员创建的远程分支就好了.

     ![远程分支](ubuntu%20%E4%B8%AD%E6%90%AD%E5%BB%BAgitlab%E6%9C%8D%E5%8A%A1%E5%99%A8/image-20201230125709228.png)

   - 回到你项目的主页，会发现有两个同名的项目。点开管理员创建的那个。点击克隆。把ssh地址复制。

     ```bash
     git remote add upstream xxxxxx #添加远程分支
     git remote -v #增加了一条远程分支
     git fetch upstream  #获取最新的基线代码
     git merge upstream/master #将基线代码合入你本地分支
     git push origin master #将最新的代码提交到你派生的项目中
     #这时候你  本地代码  和你  远程派生的代码  还有  基线代码  是保持最新的同步的。
     ```

   - ok ,现在就可以在最新的基础上修改了。

     

     

