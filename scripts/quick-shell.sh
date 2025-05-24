#!/bin/bash

# ========================================================================
# Quick Shell
#
# 使用方法: bash <(curl -sSL https://raw.githubusercontent.com/slowlyo/blog/master/scripts/quick-shell.sh)
# ========================================================================

# 设置错误处理
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 输出日志
log() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
    exit 1
}

warn() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
}

title() {
    echo -e "${BLUE}==============================================${NC}"
    echo -e "${BLUE} $1 ${NC}"
    echo -e "${BLUE}==============================================${NC}"
}

# =====================================================================================

group_with_git() {
    script_list=(
        "保存用户名密码"
        "放弃所有本地更改"
        "全局忽略文件权限"
        "全局安全目录"
        "设置默认使用 merge 合并"
    )

    title "GIT 相关"

    select script in "${script_list[@]}"; do
        case $REPLY in
            1)
                # 保存用户名密码
                git config --global credential.helper store
                log "用户名密码已保存"
                ;;
            2)
                # 放弃所有本地更改
                git reset --hard && git clean -fd && git fetch --all && git reset --hard origin/master
                log "所有本地更改已放弃"
                ;;
            3)
                # 全局忽略文件权限
                git config --global core.fileMode false
                log "全局忽略文件权限已设置"
                ;;
            4)
                # 全局安全目录
                git config --global --add safe.directory "*"
                log "全局安全目录已设置"
                ;;
            5)
                # 设置默认使用 merge 合并
                git config --global pull.rebase false
                log "默认使用 merge 合并已设置"
                ;;
            *)
                warn "请选择正确的选项"
                ;;
        esac
    done
}

group_with_quick_config() {
    script_list=(
        "GitHub SSH 密钥"
        "WSL2 初始化 (Ubuntu)"
        "配置 vimrc"
        "更换系统软件源"
        "更换 Docker 镜像源"
    )

    title "一键配置脚本"

    select script in "${script_list[@]}"; do
        case $REPLY in
            1)
                # GitHub SSH 密钥
                curl -sSL https://raw.githubusercontent.com/slowlyo/blog/master/scripts/github-ssh.sh | bash
                ;;
            2)
                # WSL2 初始化 (Ubuntu)
                curl -sSL https://raw.githubusercontent.com/slowlyo/blog/master/scripts/wsl-setup.sh | sudo bash
                ;;
            3)
                # 配置 vimrc
                curl -sSL https://raw.githubusercontent.com/slowlyo/blog/refs/heads/master/conf/.vimrc -o ~/.vimrc || error "下载 vimrc 失败"
                ;;
            4)
                # 更换系统软件源
                bash <(curl -sSL https://raw.githubusercontent.com/SuperManito/LinuxMirrors/main/ChangeMirrors.sh)
                ;;
            5)
                # 更换 Docker 镜像源
                bash <(curl -sSL https://raw.githubusercontent.com/SuperManito/LinuxMirrors/main/DockerInstallation.sh)
                ;;
            *)
                warn "请选择正确的选项"
                ;;
        esac
    done
}

main() {
    script_list=(
        "GIT 相关"
        "一键配置脚本"
    )

    title "Quick Shell"

    # 检测当前 shell
    if alias | grep -q "qsh"; then
        log "别名 qsh 已存在, 后续使用 qsh 即可"
    else
        if [ "$SHELL" = "/bin/bash" ] || [ "$SHELL" = "/usr/bin/bash" ]; then
            echo "可以使用以下命令添加别名"
            echo "echo 'alias qsh='bash <(curl -sSL https://raw.githubusercontent.com/slowlyo/blog/master/scripts/quick-shell.sh)'' >> ~/.bashrc && source ~/.bashrc"
        elif [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
            echo "可以使用以下命令添加别名"
            echo "echo 'alias qsh='bash <(curl -sSL https://raw.githubusercontent.com/slowlyo/blog/master/scripts/quick-shell.sh)'' >> ~/.zshrc && source ~/.zshrc"
        else
            warn "当前 shell 为 $SHELL, 不支持添加别名"
        fi
    fi

    select script in "${script_list[@]}"; do
        case $REPLY in
            1)
                group_with_git
                ;;
            2)
                group_with_quick_config
                ;;
            *)
                warn "请选择正确的选项"
                ;;
        esac
    done
}

main
