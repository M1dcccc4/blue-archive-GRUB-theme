#!/usr/bin/env bash

# GRUB 主题安装脚本
# 用法：在主题目录下运行 sudo ./install.sh

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查 root 权限
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}错误：请使用 root 权限运行此脚本${NC}"
    exit 1
fi

# 获取主题名称（当前目录名）
THEME_NAME=$(basename "$(pwd)")
THEME_DEST="/boot/grub/themes/${THEME_NAME}"
GRUB_CFG="/etc/default/grub"
echo -e "该主题的最佳使用分辨率为：1920x1080，你已知晓？（y/n）"
read result
if [[ "$result" != "y" ]]; then
	exit 1
fi

echo -e "${GREEN}>>> 正在安装 GRUB 主题：${THEME_NAME}${NC}"

# 1. 检查必要文件
if [[ ! -f "theme.txt" ]]; then
    echo -e "${RED}错误：当前目录不存在 theme.txt，请确认你在主题根目录下。${NC}"
    exit 1
fi

# 2. 创建目标目录（如果已存在则备份）
if [[ -d "$THEME_DEST" ]]; then
    BACKUP_SUFFIX=$(date +%Y%m%d_%H%M%S)
    echo -e "${YELLOW}警告：目标目录 ${THEME_DEST} 已存在，将备份为 ${THEME_DEST}_backup_${BACKUP_SUFFIX}${NC}"
    mv "$THEME_DEST" "${THEME_DEST}_backup_${BACKUP_SUFFIX}"
fi
mkdir -p "$THEME_DEST"

# 3. 复制所有文件（保留结构，但清理图片的执行权限）
echo -e "${GREEN}>>> 复制主题文件到 ${THEME_DEST} ...${NC}"
cp -r ./* "$THEME_DEST/" 2>/dev/null || cp -r . "$THEME_DEST/"


# 3.1 移除图片和字体等文件的执行权限（可选）
chmod -x "$THEME_DEST"/*.png "$THEME_DEST"/*.pf2 2>/dev/null || true

# 3.2 确保目录权限正确
find "$THEME_DEST" -type d -exec chmod 755 {} \;
find "$THEME_DEST" -type f -exec chmod 644 {} \;

# 4. 设置 GRUB 主题（修改 /etc/default/grub）
echo -e "${GREEN}>>> 配置 GRUB 默认主题...${NC}"
# 检查是否已存在 GRUB_THEME 行
if grep -q "^GRUB_THEME=" "$GRUB_CFG"; then
    # 替换为新的主题路径
    sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"${THEME_DEST}/theme.txt\"|" "$GRUB_CFG"
else
    # 追加到文件末尾
    echo "GRUB_THEME=\"${THEME_DEST}/theme.txt\"" >> "$GRUB_CFG"
fi

# 复制字体文件
cp *.pf2 /boot/grub/fonts

# 确保 GRUB 使用图形终端
if grep -q "^GRUB_TERMINAL_OUTPUT=" "$GRUB_CFG"; then
    sed -i "s|^GRUB_TERMINAL_OUTPUT=.*|GRUB_TERMINAL_OUTPUT=\"gfxterm\"|" "$GRUB_CFG"
else
    echo "GRUB_TERMINAL_OUTPUT=\"gfxterm\"" >> "$GRUB_CFG"
fi

# 5. 更新 GRUB 配置
echo -e "${GREEN}>>> 更新 GRUB 配置...${NC}"
grub-mkconfig -o /boot/grub/grub.cfg

echo -e "${GREEN}主题安装完成！${NC}"
