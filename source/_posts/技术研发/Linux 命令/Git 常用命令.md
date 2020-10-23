---
title: Git 常用命令
toc: true
date: 2020-01-01 00:00:01
tags: 
---

###  撤销指令
1. 撤销工作区的修改
	**git checkout** 文件名
	**git checkout** 目录 -f
2. 从暂存区撤销到工作区（可以理解为**git add**的反向动作）
	**git reset HEAD**
3. 从版本库撤销到暂存区
	**git reset --soft HEAD^**
4. 从版本库撤销到工作区
	**git reset --mixed HEAD^**
5. 撤销到上一次提交（本地修改丢失）
	**git reset --hard HEAD^**

### 保存恢复指令
1. 保存本地未追踪的修改
	 **git stash save** 路径
2. 将保存的内容导出
	**git stash pop stash@{index}**
3. 获取保存列表
	 **git stash list**

### 解决冲突
这里我分为两种情况：
1. 代码提到服务器上。
	a. 首先把自己的提交reset掉。
	b.更新代码
	c.将自己的代码从服务器上拉下来。
	d.冲突用code工具解决掉。然后add 修改文件，重新commit

2. 代码在本地提交
	a.将本地提交撤回到工作区。
	b.保存本地修改
	c.更新代码
	d.将保存的代码还原。
	e.冲突用code工具解决掉。然后add 修改文件，重新commit
