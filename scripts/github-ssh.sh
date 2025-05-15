#!/bin/bash

# ======================================================================
# GitHub SSH 密钥一键配置脚本
#
# 使用方法: bash <(curl -sSL https://raw.githubusercontent.com/slowlyo/blog/master/scripts/github-ssh.sh)
#
# 功能:
#    - 检查并生成 SSH 密钥
#    - 配置 GitHub SSH 密钥
#    - 测试 SSH 连接
#    - 配置 SSH 代理（可选）
#
# ======================================================================

# 设置错误处理
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 输出日志
log() {
    echo -e "${GREEN}$(date '+%Y-%m-%d %H:%M:%S') $1${NC}"
}

error() {
    echo -e "${RED}$(date '+%Y-%m-%d %H:%M:%S') ERROR: $1${NC}"
    exit 1
}

warn() {
    echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') WARNING: $1${NC}"
}

# 检查 SSH 密钥
check_ssh_key() {
    if [ -f ~/.ssh/id_ed25519 ]; then
        log "发现已存在的 SSH 密钥"
        read -p "是否重新生成 SSH 密钥？(y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
        return 0
    fi
    return 1
}

# 生成 SSH 密钥
generate_ssh_key() {
    log "开始生成 SSH 密钥..."
    read -p "请输入您的 GitHub 邮箱: " email
    
    if [ -z "$email" ]; then
        error "邮箱不能为空"
    fi
    
    ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N "" || error "生成 SSH 密钥失败"
    log "SSH 密钥生成完成"
}

# 配置 SSH 代理
setup_ssh_proxy() {
    read -p "是否需要配置 SSH 代理？(y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "配置 SSH 代理..."
        
        # 创建或更新 SSH 配置
        mkdir -p ~/.ssh
        if [ ! -f ~/.ssh/config ]; then
            touch ~/.ssh/config
        fi
        
        # 检查是否已存在 GitHub 配置
        if ! grep -q "Host github.com" ~/.ssh/config; then
            cat <<EOF >> ~/.ssh/config
Host github.com
    Hostname ssh.github.com
    User git
    Port 443
    ProxyCommand nc -v -x 127.0.0.1:7897 %h %p
EOF
            log "SSH 代理配置完成"
        else
            log "SSH 代理配置已存在"
        fi
    fi
}

# 启动 SSH 代理
start_ssh_agent() {
    log "启动 SSH 代理..."
    eval "$(ssh-agent -s)" || error "启动 SSH 代理失败"
    ssh-add ~/.ssh/id_ed25519 || error "添加 SSH 密钥到代理失败"
    log "SSH 代理启动完成"
}

# 显示公钥
show_public_key() {
    log "您的 SSH 公钥是:"
    echo "=========================================="
    cat ~/.ssh/id_ed25519.pub
    echo "=========================================="
    log "请将此公钥添加到 GitHub: https://github.com/settings/keys"
    log "添加步骤:"
    log "1. 复制上面的公钥内容"
    log "2. 访问 https://github.com/settings/keys"
    log "3. 点击 'New SSH key'"
    log "4. 粘贴公钥内容并保存"
    echo
    read -p "完成配置后按回车键继续..."
}

# 测试 SSH 连接
test_ssh_connection() {
    read -p "是否要测试 SSH 连接？(y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "测试 SSH 连接..."
        ssh -T git@github.com || true
        log "如果看到 'Hi username! You've successfully authenticated...' 则表示配置成功"
    else
        log "跳过 SSH 连接测试"
    fi
}

# 主函数
main() {
    log "开始配置 GitHub SSH 密钥..."
    
    # 检查并生成 SSH 密钥
    if ! check_ssh_key; then
        generate_ssh_key
    fi
    
    # 配置 SSH 代理
    setup_ssh_proxy
    
    # 启动 SSH 代理
    start_ssh_agent
    
    # 显示公钥并等待用户配置
    show_public_key
    
    # 测试连接
    test_ssh_connection
    
    log "配置完成！"
}

# 执行主函数
main 
