#!/bin/bash

# ============================================
# 小红书 MCP Linux 卸载脚本
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
SERVICE_FILE="/etc/systemd/system/xiaohongshu-mcp.service"

# 检查是否以 root 运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}错误：请使用 root 用户运行此卸载脚本 (sudo ./uninstall.sh)${NC}"
        exit 1
    fi
}

# 确认卸载
confirm_uninstall() {
    echo -e "${RED}============================================${NC}"
    echo -e "${RED}警告：这将卸载小红书 MCP 服务${NC}"
    echo -e "${RED}============================================${NC}"
    echo -e "${YELLOW}以下操作将会执行：${NC}"
    echo "  1. 停止并禁用 systemd 服务"
    echo "  2. 删除安装目录：$INSTALL_DIR"
    echo "  3. 删除数据目录：$DATA_DIR"
    echo "  4. 删除日志目录：$LOG_DIR"
    echo "  5. 删除 systemd 服务文件"
    echo ""
    echo -e "${YELLOW}注意：数据目录和日志目录将被永久删除！${NC}"
    echo ""
    read -p "确定要继续卸载吗？(y/N): " confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}已取消卸载${NC}"
        exit 0
    fi
}

# 停止服务
stop_service() {
    echo -e "${YELLOW}正在停止服务...${NC}"
    
    if systemctl is-active --quiet xiaohongshu-mcp; then
        systemctl stop xiaohongshu-mcp
        echo -e "${GREEN}✓ 服务已停止${NC}"
    else
        echo -e "${BLUE}服务未运行${NC}"
    fi
    
    if systemctl is-enabled --quiet xiaohongshu-mcp; then
        systemctl disable xiaohongshu-mcp
        echo -e "${GREEN}✓ 服务已禁用${NC}"
    fi
}

# 删除文件
remove_files() {
    echo -e "${YELLOW}正在删除文件...${NC}"
    
    # 删除安装目录
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        echo -e "${GREEN}✓ 已删除：$INSTALL_DIR${NC}"
    fi
    
    # 删除数据目录
    if [ -d "$DATA_DIR" ]; then
        rm -rf "$DATA_DIR"
        echo -e "${GREEN}✓ 已删除：$DATA_DIR${NC}"
    fi
    
    # 删除日志目录
    if [ -d "$LOG_DIR" ]; then
        rm -rf "$LOG_DIR"
        echo -e "${GREEN}✓ 已删除：$LOG_DIR${NC}"
    fi
    
    # 删除 systemd 服务文件
    if [ -f "$SERVICE_FILE" ]; then
        rm -f "$SERVICE_FILE"
        echo -e "${GREEN}✓ 已删除：$SERVICE_FILE${NC}"
    fi
    
    # 重新加载 systemd
    systemctl daemon-reload
    echo -e "${GREEN}✓ systemd 配置已更新${NC}"
}

# 清理日志
cleanup_journal() {
    echo -e "${YELLOW}正在清理系统日志...${NC}"
    journalctl --rotate
    journalctl --vacuum-time=1s
    echo -e "${GREEN}✓ 日志清理完成${NC}"
}

# 显示卸载后说明
show_post_uninstall() {
    echo -e "\n${GREEN}============================================${NC}"
    echo -e "${GREEN}卸载完成！${NC}"
    echo -e "${GREEN}============================================${NC}"
    
    echo -e "\n${YELLOW}如果需要重新安装：${NC}"
    echo "1. 下载最新的安装包"
    echo "2. 运行安装脚本：sudo ./install.sh"
    echo ""
}

# 主函数
main() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}小红书 MCP 卸载程序${NC}"
    echo -e "${BLUE}============================================${NC}"
    
    check_root
    confirm_uninstall
    stop_service
    remove_files
    cleanup_journal
    show_post_uninstall
    
    echo -e "${GREEN}卸载成功！${NC}"
}

# 运行主函数
main "$@"
