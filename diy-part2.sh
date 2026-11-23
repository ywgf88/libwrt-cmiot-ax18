#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# 默认管理 IP -> 192.168.9.1
sed -i 's/192\.168\.[0-9]*\.[0-9]*/192.168.9.1/g' package/base-files/files/bin/config_generate

# 默认主题：argon 包自带首启脚本；98-default-theme-argon 兜底，防止第三方主题抢占默认外观

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate

# 随 files/ 挂载进 rootfs 的脚本可执行位
chmod +x ./files/etc/init.d/homeproxy-ram ./files/etc/uci-defaults/97-ram-tune ./files/etc/uci-defaults/98-default-theme-argon 2>/dev/null || true

# TTYD 免登录
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# 【无线已恢复】以下 BDF 切除手术已禁用：
# ipq-wifi-cmiot_ax18 提供 ath11k 必需的板级校准数据(board-2.bin)，
# 抹除后驱动即使编译也无法识别无线网卡，guest-wifi 菜单因此不显示。
# find target/linux/qualcommax/image/ -name "*.mk" | xargs sed -i 's/ipq-wifi-cmiot_ax18//g' 2>/dev/null

# 自动将基础组件中的 dnsmasq 替换为 dnsmasq-full, 从源头规避包冲突
find include/ target/ -name "Makefile" -o -name "*.mk" | xargs sed -i 's/\bdnsmasq\b/dnsmasq-full/g' 2>/dev/null

# ===== [2026-11-23] 修复 luci-app-guest-wifi 添加按钮无反应 bug =====
# 上游 wifi.js 的 handleAdd 仅创建空段，被 s.filter(guest_wifi==='1') 隐藏，
# 且 handleApply 调用了未 require 的 XHR.poll() 抛异常。
# 用修复版覆盖 feed 源文件（GITHUB_WORKSPACE 为仓库检出根目录，补丁源位于 patches/）。
GUEST_WIFI_JS="$(find feeds -type f -path '*/luci-app-guest-wifi/htdocs/luci-static/resources/view/guest-wifi/wifi.js' -print -quit 2>/dev/null)"
PATCH_SRC="${GITHUB_WORKSPACE:-$(pwd)/..}/patches/wifi.js"
if [ -n "$GUEST_WIFI_JS" ] && [ -f "$PATCH_SRC" ]; then
    cp -f "$PATCH_SRC" "$GUEST_WIFI_JS"
    echo "[patch] luci-app-guest-wifi wifi.js replaced -> $GUEST_WIFI_JS"
else
    echo "[patch][WARN] guest-wifi wifi.js or patch source not found, skip"
    echo "[patch][WARN] GUEST_WIFI_JS='$GUEST_WIFI_JS' PATCH_SRC='$PATCH_SRC'"
fi
