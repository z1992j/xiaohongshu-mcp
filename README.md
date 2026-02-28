# 小红书 MCP Linux 服务器安装指南

本文档介绍如何在 Linux 服务器上安装和部署小红书 MCP 服务。

## 系统要求

- **操作系统**: Ubuntu 18.04+ / Debian 10+ / CentOS 7+ / Rocky Linux 8+ / AlmaLinux 8+
- **架构**: x86_64 (amd64)
- **内存**: 最低 2GB，推荐 4GB+
- **磁盘**: 至少 1GB 可用空间
- **网络**: 需要访问小红书官网和 Google Chrome 下载源

## 快速开始

### 方式一：使用预编译包（推荐）

#### 1. 下载并解压

从 GitHub Releases 下载最新的 Linux 安装包：

```bash
# 创建安装目录
mkdir -p /tmp/xiaohongshu-mcp
cd /tmp/xiaohongshu-mcp

# 下载最新包 (请替换为实际的下载链接)

# 解压
tar -xzf xiaohongshu-mcp-linux-amd64.tar.gz
```

#### 2. 运行安装脚本

```bash
# 进入解压目录
cd xiaohongshu-mcp-linux-amd64

# 执行安装（需要 root 权限）
sudo ./install.sh
```

#### 3. 登录小红书

```bash
# 切换到安装目录
cd /opt/xiaohongshu-mcp

# 运行登录工具（需要界面，首次登录建议使用非无头模式）
sudo ./xiaohongshu-login -headless=false
```

按照提示完成小红书登录。

#### 4. 启动服务

```bash
# 启动服务
sudo systemctl start xiaohongshu-mcp

# 查看状态
sudo systemctl status xiaohongshu-mcp

# 设置开机自启
sudo systemctl enable xiaohongshu-mcp
```

#### 5. 验证安装

```bash
# 测试 MCP 连接
curl -X POST http://localhost:18060/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","params":{},"id":1}'
```

### 方式二：源码编译安装

#### 1. 安装 Go 环境

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y golang-go

# CentOS/RHEL
sudo yum install -y golang
```

#### 2. 克隆项目

```bash
git clone https://github.com/xpzouying/xiaohongshu-mcp.git
cd xiaohongshu-mcp
```

#### 3. 构建 Linux 版本

```bash
# 运行构建脚本
chmod +x build_linux.sh
./build_linux.sh
```

#### 4. 部署到服务器

```bash
# 将 build/linux 目录下的文件上传到服务器
# 然后按照方式一的步骤 2-5 进行安装
```

## 目录结构

安装完成后，文件和目录分布如下：

```
/opt/xiaohongshu-mcp/          # 安装目录
├── xiaohongshu-mcp           # 主程序
└── xiaohongshu-login         # 登录工具

/var/lib/xiaohongshu-mcp/     # 数据目录
├── cookies.json              # Cookies 文件
└── images/                   # 图片存储目录

/var/log/xiaohongshu-mcp/     # 日志目录
```

## 服务管理

### 基本命令

```bash
# 启动服务
sudo systemctl start xiaohongshu-mcp

# 停止服务
sudo systemctl stop xiaohongshu-mcp

# 重启服务
sudo systemctl restart xiaohongshu-mcp

# 查看状态
sudo systemctl status xiaohongshu-mcp

# 开机自启
sudo systemctl enable xiaohongshu-mcp

# 禁用自启
sudo systemctl disable xiaohongshu-mcp
```

### 查看日志

```bash
# 实时查看日志
sudo journalctl -u xiaohongshu-mcp -f

# 查看最近的日志
sudo journalctl -u xiaohongshu-mcp -n 100

# 查看特定时间的日志
sudo journalctl -u xiaohongshu-mcp --since "2024-01-01 00:00:00"
```

## 配置代理（可选）

如果服务器需要通过代理访问小红书，可以修改 systemd 服务配置：

```bash
# 编辑服务配置
sudo systemctl edit xiaohongshu-mcp
```

添加以下内容：

```ini
[Service]
Environment="XHS_PROXY=http://user:pass@proxy:port"
```

然后重启服务：

```bash
sudo systemctl daemon-reload
sudo systemctl restart xiaohongshu-mcp
```

## 防火墙配置

如果服务器启用了防火墙，需要开放端口：

```bash
# Ubuntu (UFW)
sudo ufw allow 18060/tcp

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-port=18060/tcp
sudo firewall-cmd --reload
```

## 卸载

如需卸载，运行：

```bash
# 下载或找到 uninstall.sh 脚本
sudo ./uninstall.sh
```

或手动卸载：

```bash
# 停止并禁用服务
sudo systemctl stop xiaohongshu-mcp
sudo systemctl disable xiaohongshu-mcp

# 删除文件
sudo rm -rf /opt/xiaohongshu-mcp
sudo rm -rf /var/lib/xiaohongshu-mcp
sudo rm -rf /var/log/xiaohongshu-mcp
sudo rm -f /etc/systemd/system/xiaohongshu-mcp.service

# 重新加载 systemd
sudo systemctl daemon-reload
```

## 常见问题

### 1. 服务启动失败

查看日志排查问题：

```bash
sudo journalctl -u xiaohongshu-mcp -n 50 --no-pager
```

常见原因：
- Cookies 文件不存在或已过期 → 重新运行登录工具
- 端口被占用 → 修改服务配置中的端口
- Chrome 依赖缺失 → 检查 Chrome 是否正确安装

### 2. Chrome 无法启动

确保安装了所有依赖：

```bash
# Ubuntu/Debian
sudo apt-get install -y libatk-bridge2.0-0 libgtk-3-0 libgbm1

# CentOS/RHEL
sudo yum install -y alsa-lib libXcomposite libXcursor libXdamage libXext libXi libXtst cups-libs libXScrnSaver libXrandr pango mesa-libGLES
```

### 3. 内存不足

如果服务器内存较小，可以添加 swap：

```bash
# 创建 2GB swap 文件
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 永久生效
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 4. Cookies 过期

Cookies 过期后需要重新登录：

```bash
# 停止服务
sudo systemctl stop xiaohongshu-mcp

# 运行登录工具
sudo /opt/xiaohongshu-mcp/xiaohongshu-login -headless=false

# 启动服务
sudo systemctl start xiaohongshu-mcp
```

## 安全建议

1. **不要以 root 运行**：创建专用用户运行服务
2. **配置防火墙**：只允许信任的 IP 访问
3. **定期更新**：保持软件为最新版本
4. **监控日志**：定期检查日志发现异常
5. **备份 Cookies**：定期备份 `/var/lib/xiaohongshu-mcp/cookies.json`

## 技术支持

- GitHub Issues: https://github.com/xpzouying/xiaohongshu-mcp/issues
- 项目文档：https://github.com/xpzouying/xiaohongshu-mcp

## 更新日志

### v1.0.0 (2024-01-01)
- 首次发布 Linux 安装包
- 支持 systemd 服务管理
- 支持自动安装 Chrome 和字体
- 提供完整的安装和卸载脚本
