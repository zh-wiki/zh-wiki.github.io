---
title: Repo 常用命令
toc: true
date: 2020-01-01 00:00:02
tags: 
---

### repo 拉下来的代码如何新建分支

```bash
repo start xxx(分支名) --all
```

### repo sync 的时候如果有本地未提交的修改

```bash
repo forall -cv "git reset HEAD --hard; git clean -df " -j32
```

