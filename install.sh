#!/bin/bash

# ============================================
# 小红书 MCP Linux 安装脚本
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 安装配置
INSTALL_DIR="/opt/xiaohongshu-mcp"
DATA_DIR="/var/lib/xiaohongshu-mcp"
LOG_DIR="/var/log/xiaohongshu-mcp"
IMAGE_DIR="/var/lib/xiaohongshu-mcp/images"
SERVICE_FILE="xiaohongshu-mcp.service"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检查是否以 root 运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}错误：请使用 root 用户运行此安装脚本 (sudo ./install.sh)${NC}"
        exit 1
    fi
}

# 检测 Linux 发行版
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        echo -e "${BLUE}检测到操作系统：$OS $VERSION_ID${NC}"
    else
        echo -e "${RED}无法检测操作系统版本${NC}"
        exit 1
    fi
}

# 安装系统依赖
install_dependencies() {
    echo -e "${YELLOW}正在安装系统依赖...${NC}"
    
    case $OS in
        ubuntu|debian)
            apt-get update
            apt-get install -y wget curl gnupg ca-certificates
            ;;
        centos|rhel|fedora|almalinux|rocky)
            yum install -y wget curl gnupg ca-certificates
            ;;
        *)
            echo -e "${YELLOW}警告：未知的操作系统，尝试继续安装${NC}"
            ;;
    esac
    
    echo -e "${GREEN}✓ 系统依赖安装完成${NC}"
}

# 安装 Google Chrome
install_chrome() {
    echo -e "${YELLOW}正在安装 Google Chrome...${NC}"
    
    case $OS in
        ubuntu|debian)
            # 下载并安装 Chrome
            wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/googlechrome-linux-keyring.gpg
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrome-linux-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
            apt-get update
            apt-get install -y google-chrome-stable
            ;;
        centos|rhel|fedora|almalinux|rocky)
            # 下载并安装 Chrome RPM
            wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
            yum install -y ./google-chrome-stable_current_x86_64.rpm
            rm -f google-chrome-stable_current_x86_64.rpm
            ;;
        *)
            echo -e "${RED}错误：不支持的操作系统安装 Chrome${NC}"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}✓ Google Chrome 安装完成${NC}"
}

# 安装中文字体
install_fonts() {
    echo -e "${YELLOW}正在安装中文字体...${NC}"
    
    case $OS in
        ubuntu|debian)
            apt-get install -y fonts-wqy-zenhei fonts-wqy-microhei
            ;;
        centos|rhel|fedora|almalinux|rocky)
            yum install -y wqy-zenhei-fonts wqy-microhei-fonts
            ;;
    esac
    
    echo -e "${GREEN}✓ 中文字体安装完成${NC}"
}

# 创建安装目录
create_directories() {
    echo -e "${YELLOW}正在创建安装目录...${NC}"
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$DATA_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$IMAGE_DIR"
    
    # 设置权限
    chmod 755 "$INSTALL_DIR"
    chmod 755 "$DATA_DIR"
    chmod 755 "$LOG_DIR"
    chmod 777 "$IMAGE_DIR"
    
    echo -e "${GREEN}✓ 目录创建完成${NC}"
}

# 复制文件
copy_files() {
    echo -e "${YELLOW}正在复制文件...${NC}"
    
    # 复制主程序
    if [ -f "$SCRIPT_DIR/xiaohongshu-mcp" ]; then
        cp "$SCRIPT_DIR/xiaohongshu-mcp" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/xiaohongshu-mcp"
        echo -e "${GREEN}✓ 主程序复制完成${NC}"
    else
        echo -e "${RED}错误：找不到主程序文件 xiaohongshu-mcp${NC}"
        exit 1
    fi
    
    # 复制登录工具
    if [ -f "$SCRIPT_DIR/xiaohongshu-login" ]; then
        cp "$SCRIPT_DIR/xiaohongshu-login" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/xiaohongshu-login"
        echo -e "${GREEN}✓ 登录工具复制完成${NC}"
    else
        echo -e "${RED}错误：找不到登录工具文件 xiaohongshu-login${NC}"
        exit 1
    fi
    
    # 复制服务文件
    if [ -f "$SCRIPT_DIR/$SERVICE_FILE" ]; then
        cp "$SCRIPT_DIR/$SERVICE_FILE" /etc/systemd/system/
        echo -e "${GREEN}✓ systemd 服务文件复制完成${NC}"
    else
        echo -e "${YELLOW}警告：找不到服务文件，将跳过 systemd 配置${NC}"
    fi
}

# 配置 systemd 服务
setup_systemd() {
    if [ ! -f /etc/systemd/system/$SERVICE_FILE ]; then
        echo -e "${YELLOW}警告：服务文件不存在，跳过 systemd 配置${NC}"
        return
    fi
    
    echo -e "${YELLOW}正在配置 systemd 服务...${NC}"
    
    # 重新加载 systemd
    systemctl daemon-reload
    
    # 启用服务（不启动）
    systemctl enable xiaohongshu-mcp
    
    echo -e "${GREEN}✓ systemd 服务配置完成${NC}"
}

# 显示安装后说明
show_post_install() {
    echo -e "\n${GREEN}============================================${NC}"
    echo -e "${GREEN}安装完成！${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo -e "安装目录：${BLUE}$INSTALL_DIR${NC}"
    echo -e "数据目录：${BLUE}$DATA_DIR${NC}"
    echo -e "日志目录：${BLUE}$LOG_DIR${NC}"
    echo -e "图片目录：${BLUE}$IMAGE_DIR${NC}"
    
    echo -e "\n${YELLOW}下一步操作：${NC}"
    echo -e "1. 首先运行登录工具进行登录:"
    echo -e "   ${BLUE}cd $INSTALL_DIR && ./xiaohongshu-login -headless=false${NC}"
    echo -e "\n2. 登录完成后，启动服务:"
    echo -e "   ${BLUE}systemctl start xiaohongshu-mcp${NC}"
    echo -e "\n3. 查看服务状态:"
    echo -e "   ${BLUE}systemctl status xiaohongshu-mcp${NC}"
    echo -e "\n4. 查看日志:"
    echo -e "   ${BLUE}journalctl -u xiaohongshu-mcp -f${NC}"
    echo -e "\n5. 设置开机自启:"
    echo -e "   ${BLUE}systemctl enable xiaohongshu-mcp${NC}"
    
    echo -e "\n${YELLOW}服务管理命令：${NC}"
    echo -e "  启动：  systemctl start xiaohongshu-mcp"
    echo -e "  停止：  systemctl stop xiaohongshu-mcp"
    echo -e "  重启：  systemctl restart xiaohongshu-mcp"
    echo -e "  状态：  systemctl status xiaohongshu-mcp"
    echo -e "  日志：  journalctl -u xiaohongshu-mcp -f"
    echo ""
}

# 主函数
main() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}小红书 MCP 安装程序${NC}"
    echo -e "${BLUE}============================================${NC}"
    
    check_root
    detect_os
    install_dependencies
    install_chrome
    install_fonts
    create_directories
    copy_files
    setup_systemd
    show_post_install
    
    echo -e "${GREEN}安装成功！${NC}"
}

# 运行主函数
main "$@"
