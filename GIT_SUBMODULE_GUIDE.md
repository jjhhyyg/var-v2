# Git Submodule 使用指南

本项目使用 Git Submodule 管理三个独立的子项目（backend、frontend、ai-processor）。本文档说明如何在开发和协作中正确使用 Git Submodule。

---

## 📋 当前子模块状态

| 子模块 | 路径 | 分支 | 当前提交 |
|--------|------|------|---------|
| backend | `backend/` | main | `6b4452b` |
| frontend | `frontend/` | main | `9c79b94` |
| ai-processor | `ai-processor/` | main | `20f5910` |

---

## 🚀 初次克隆项目

### 方式1: 克隆时同时初始化子模块（推荐）

```bash
git clone --recurse-submodules <repository-url>
```

这会自动克隆主仓库和所有子模块。

### 方式2: 先克隆主仓库，再初始化子模块

```bash
# 克隆主仓库
git clone <repository-url>
cd codes

# 初始化并更新所有子模块
git submodule update --init --recursive
```

---

## 🔄 日常开发工作流

### 1. 拉取主仓库和子模块的最新更改

```bash
# 拉取主仓库更新
git pull

# 更新所有子模块到主仓库记录的提交
git submodule update --init --recursive

# 或者一步完成
git pull --recurse-submodules
```

### 2. 在子模块中开发

#### 进入子模块并切换分支

```bash
cd backend
git checkout main
git pull origin main
```

#### 进行开发和提交

```bash
# 在子模块中正常开发
git add .
git commit -m "feat: 添加新功能"
git push origin main
```

#### 返回主仓库并更新子模块引用

```bash
cd ..  # 返回主仓库根目录

# 查看子模块状态
git status
# 会看到: modified:   backend (new commits)

# 提交子模块引用的更新
git add backend
git commit -m "chore: 更新 backend 子模块到最新版本"
git push
```

### 3. 更新所有子模块到远程最新版本

```bash
# 更新所有子模块到各自远程分支的最新提交
git submodule update --remote --merge

# 提交子模块引用的更新
git add .
git commit -m "chore: 更新所有子模块到最新版本"
git push
```

---

## 📝 常用命令

### 查看子模块状态

```bash
# 查看所有子模块的提交ID和分支
git submodule status

# 查看子模块详细信息
git submodule foreach git status
```

### 在所有子模块中执行命令

```bash
# 在所有子模块中拉取最新代码
git submodule foreach git pull origin main

# 在所有子模块中查看当前分支
git submodule foreach git branch
```

### 克隆特定子模块

```bash
# 只初始化和更新 backend 子模块
git submodule update --init backend
```

---

## ⚠️ 注意事项

### 1. 子模块是独立的 Git 仓库

- 子模块有自己的 `.git` 目录
- 子模块的修改需要在子模块内提交
- 主仓库只记录子模块的提交 ID

### 2. 分离头指针（Detached HEAD）

当你运行 `git submodule update` 时，子模块会处于 **分离头指针** 状态（指向特定提交，不在任何分支上）。

**解决方法**：

```bash
cd backend
git checkout main  # 切换到 main 分支
```

### 3. 推送前检查子模块状态

```bash
# 在主仓库根目录
git submodule foreach git status

# 确保所有子模块的更改都已提交和推送
git submodule foreach git push
```

### 4. 两步提交流程

修改子模块后需要两次提交：

1. **在子模块中提交** - 提交代码更改
2. **在主仓库中提交** - 提交子模块引用的更新

---

## 🔧 问题排查

### 问题1: 子模块目录为空

**原因**: 克隆主仓库时没有初始化子模块

**解决**:
```bash
git submodule update --init --recursive
```

### 问题2: 子模块显示为修改状态但没有改动

**原因**: 子模块处于分离头指针状态或本地提交与主仓库记录不一致

**解决**:
```bash
cd backend
git checkout main
git pull origin main
cd ..
git add backend
git commit -m "chore: 同步 backend 子模块"
```

### 问题3: 无法推送子模块的更改

**原因**: 子模块处于分离头指针状态

**解决**:
```bash
cd backend
git checkout main
git merge <commit-id>  # 合并你的更改
git push origin main
```

### 问题4: 子模块URL失效

**原因**: `.gitmodules` 中的 URL 需要更新

**解决**:
```bash
# 编辑 .gitmodules 文件，更新 URL
git submodule sync
git submodule update --init --recursive
```

---

## 🎯 最佳实践

### 1. 保持子模块在分支上

```bash
# 进入子模块后立即切换到分支
cd backend
git checkout main
```

### 2. 开发前更新子模块

```bash
git pull --recurse-submodules
```

### 3. 提交前检查状态

```bash
# 检查主仓库和所有子模块的状态
git status
git submodule foreach git status
```

### 4. 使用脚本自动化

创建一个脚本 `update-all.sh`:

```bash
#!/bin/bash
# 更新主仓库和所有子模块

echo "📦 拉取主仓库更新..."
git pull

echo "📦 更新子模块..."
git submodule update --init --recursive

echo "📦 切换子模块到 main 分支..."
git submodule foreach 'git checkout main && git pull origin main'

echo "✅ 更新完成！"
```

---

## 📚 参考资料

- [Git Submodule 官方文档](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- [Pro Git - 子模块](https://git-scm.com/book/zh/v2/Git-%E5%B7%A5%E5%85%B7-%E5%AD%90%E6%A8%A1%E5%9D%97)

---

## 🔗 相关文件

- `.gitmodules` - 子模块配置文件
- `README.md` - 项目主文档
- 各子模块目录下的 `.git/` - 子模块 Git 仓库

---

**最后更新**: 2025-10-08
