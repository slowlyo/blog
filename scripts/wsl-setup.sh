# ======================================================================
# wsl2 一键初始化脚本 (适用 Ubuntu)
#
# 使用方法: curl -sSL https://raw.githubusercontent.com/slowlyo/blog/master/scripts/wsl-setup.sh -o wsl-setup.sh && sudo bash wsl-setup.sh; rm -f wsl-setup.sh
#
# wsl 常用命令:
#    - 安装: wsl --install -d Ubuntu-24.04
#    - 销毁: wsl --unregister Ubuntu-24.04
#    - 查看: wsl -l -v
#    - 进入: wsl -d Ubuntu-24.04
#    - 退出: exit
#    - 关闭指定发行版: wsl -t Ubuntu-24.04
#    - 关闭所有: wsl --shutdown
#    - 设置默认发行版: wsl --set-default Ubuntu-24.04
#
# ======================================================================

#!/bin/bash

# 设置错误处理
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 检查依赖
check_dependencies() {
    log "检查必要依赖..."
    local deps=("curl" "git")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            warn "$dep 未安装，正在安装..."
            apt-get update && apt-get install -y "$dep" || error "安装 $dep 失败"
        fi
    done
}

# 备份文件
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "${file}.bak"
        log "已备份 $file 到 ${file}.bak"
    fi
}

# 恢复备份
restore_backup() {
    local file=$1
    if [ -f "${file}.bak" ]; then
        mv "${file}.bak" "$file"
        log "已恢复 $file 的备份"
    fi
}

# 清理函数
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        error "脚本执行失败，退出码: $exit_code"
    fi
}

# 设置清理钩子
trap cleanup EXIT

# 记录开始时间
start_time=$(date +%s)

# 检查依赖
check_dependencies

# ==== 设置 root 密码 =============================================================================================

log "设置 root 密码"

# 如果 root 密码为空, 则设置 root 密码
if [ $(grep -c "^root::" /etc/shadow) -eq 0 ]; then
    echo "请输入 root 密码: "
    read -s root_password
    echo "请再次输入 root 密码: "
    read -s root_password_confirm
    
    if [ "$root_password" != "$root_password_confirm" ]; then
        error "两次输入的密码不一致"
    fi
    
    echo "root:$root_password" | chpasswd || error "设置 root 密码失败"
    log "root 密码设置完成"
else
    log "root 密码不为空, 已跳过设置密码"
fi

# ==== 配置 WSL ===================================================================================================

log "配置 WSL"

# 备份 wsl.conf
backup_file "/etc/wsl.conf"

# 如果 /etc/wsl.conf 文件存在, 则设置默认用户为 root
if [ -f /etc/wsl.conf ]; then
    # 检查是否已配置
    if ! grep -q "default=root" /etc/wsl.conf; then
        echo "" >> /etc/wsl.conf
        echo "[user]" >> /etc/wsl.conf
        echo "default=root" >> /etc/wsl.conf
        log "wsl 配置完成"
    else
        log "wsl 已配置，跳过"
    fi
else
    log "wsl 配置文件不存在, 已跳过配置"
fi

# ==== Git 配置 ===================================================================================================

# 全局安全目录
git config --global safe.directory '*'
# 忽略文件权限
git config --global core.filemode false
# 记住账号密码
git config --global credential.helper store
# github ssh 代理 (~/.ssh/config)
if [ ! -f ~/.ssh/config ] || ! grep -q "github.com" ~/.ssh/config; then
    cat <<EOF >> ~/.ssh/config
    Host github.com
        Hostname ssh.github.com
        User git
        Port 443
        ProxyCommand nc -v -x 127.0.0.1:7897 %h %p
EOF
    log "github ssh 代理配置完成"
else
    log "github ssh 代理配置已存在, 已跳过配置"
fi


# ==== 更换镜像源 ===================================================================================================

# 这里默认使用: 中国科学技术大学
# 项目地址: https://github.com/SuperManito/LinuxMirrors

log "开始更换镜像源"

# 备份 sources.list
backup_file "/etc/apt/sources.list"

# 使用中科大镜像源
bash <(curl -v -sSL https://raw.githubusercontent.com/SuperManito/LinuxMirrors/main/ChangeMirrors.sh) \
  --source mirrors.ustc.edu.cn \
  --protocol http \
  --use-intranet-source false \
  --backup true \
  --upgrade-software true \
  --clean-cache false \
  --ignore-backup-tips \
  --pure-mode || error "更换镜像源失败"

log "镜像源更换完成"

# ==== 配置 vimrc ===================================================================================================

# https://raw.githubusercontent.com/slowlyo/blog/refs/heads/master/conf/.vimrc

log "开始配置 vimrc"

# 备份现有的 vimrc
backup_file "$HOME/.vimrc"

# 下载新的 vimrc
curl -sSL https://raw.githubusercontent.com/slowlyo/blog/refs/heads/master/conf/.vimrc -o ~/.vimrc || error "下载 vimrc 失败"

log "vimrc 配置完成"

# ==== 安装 zsh ===================================================================================================

log "开始安装 zsh"

apt-get install -y zsh || error "安装 zsh 失败"

log "zsh 安装完成"

# ==== 安装 oh-my-zsh =================================================================================================

log "开始安装 oh-my-zsh"

# 安装 oh-my-zsh
RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || error "安装 oh-my-zsh 失败"

# 安装 oh-my-zsh 插件
log "安装 oh-my-zsh 插件"

# auto-suggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || error "安装 zsh-autosuggestions 失败"

# syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || error "安装 zsh-syntax-highlighting 失败"

# powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k || error "安装 powerlevel10k 失败"

# 安装 eza
apt-get install -y eza || error "安装 eza 失败"

# 备份 zshrc
backup_file "$HOME/.zshrc"

# 替换 oh-my-zsh 主题
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc || error "配置 zsh 主题失败"

# 设置 oh-my-zsh 插件
sed -i 's/plugins=(git)/plugins=(git z eza zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc || error "配置 zsh 插件失败"

# 设置 zsh 为默认 shell
chsh -s $(which zsh) || error "设置默认 shell 失败"

log "oh-my-zsh 安装完成"

# 计算执行时间
end_time=$(date +%s)
duration=$((end_time - start_time))
log "脚本执行完成，总耗时: ${duration} 秒"

# 提示用户
log "重启 wsl 后生效"
log "    1. exit"
log "    2. wsl -t Ubuntu-24.04 ; wsl -d Ubuntu-24.04"
log "注意: powerlevel10k 主题配置需要交互，请根据提示完成配置"
