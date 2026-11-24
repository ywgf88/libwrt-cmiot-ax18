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

# ===== [2026-11-24] guest-wifi 同步服务 v3：修复 LuCI「无线配置迁移」弹窗死循环 =====
# v2 遗留 bug：init 服务用 `uci add wireless wifi-iface` 生成匿名段(cfgxxxxxx)，
#   LuCI 检测到匿名 wifi-iface 就反复弹「无线配置迁移」对话框；因服务监听
#   wireless 变更，点「继续」或手动改名后会被立刻重建为匿名段，形成死循环。
# v3 方案：在 patches/guest-wifi-init 的 sync_one() 中，add 后立即重命名为
#   wifinet#（跳过已占用编号），从源头生成具名段。仅改 1 个文件：guest-wifi-init。
#   （下方 v1/v2 历史说明保留备查）
#
# ===== [2026-11-23] 修复 luci-app-guest-wifi 添加按钮无反应 bug (v2 独立配置版) =====
# v1 根因：访客段存于 wireless + s.filter(guest_wifi==='1')，新建段被 filter 隐藏，
#          且页面缺可靠 apply 入口 → 点击添加后界面无变化。
# v2 方案：改用独立 UCI 配置 guest-wifi 存储访客网络（无 filter），新增 init 服务
#          在配置变更时同步生成 wireless 的 wifi-iface 段。共覆盖 4 个文件：
#           1) wifi.js                   页面视图（主配置改 guest-wifi，去 filter）
#           2) luci-app-guest-wifi-acl.json  ACL 增加 guest-wifi 读写权限
#           3) guest-wifi-init           /etc/init.d/guest-wifi 同步服务
#           4) 40_luci-guest-wifi        /etc/uci-defaults 建默认配置+启用服务
# GITHUB_WORKSPACE 为仓库检出根目录，补丁源位于 patches/。
PATCH_DIR="${GITHUB_WORKSPACE:-$(pwd)/..}/patches"

# 1) 页面视图
GUEST_WIFI_JS="$(find feeds -type f -path '*/luci-app-guest-wifi/htdocs/luci-static/resources/view/guest-wifi/wifi.js' -print -quit 2>/dev/null)"
if [ -n "$GUEST_WIFI_JS" ] && [ -f "$PATCH_DIR/wifi.js" ]; then
    cp -f "$PATCH_DIR/wifi.js" "$GUEST_WIFI_JS"
    echo "[patch-v2] wifi.js replaced -> $GUEST_WIFI_JS"
else
    echo "[patch-v2][WARN] wifi.js not found (JS='$GUEST_WIFI_JS' SRC='$PATCH_DIR/wifi.js')"
fi

# 2) ACL（允许读写 guest-wifi）
GUEST_WIFI_ACL="$(find feeds -type f -path '*/luci-app-guest-wifi/root/usr/share/rpcd/acl.d/luci-app-guest-wifi.json' -print -quit 2>/dev/null)"
if [ -n "$GUEST_WIFI_ACL" ] && [ -f "$PATCH_DIR/luci-app-guest-wifi-acl.json" ]; then
    cp -f "$PATCH_DIR/luci-app-guest-wifi-acl.json" "$GUEST_WIFI_ACL"
    echo "[patch-v2] ACL replaced -> $GUEST_WIFI_ACL"
else
    echo "[patch-v2][WARN] ACL not found (ACL='$GUEST_WIFI_ACL')"
fi

# 3) init 同步服务（覆盖 feed 原 init 脚本）
GUEST_WIFI_INIT="$(find feeds -type f -path '*/luci-app-guest-wifi/root/etc/init.d/guest-wifi' -print -quit 2>/dev/null)"
if [ -n "$GUEST_WIFI_INIT" ] && [ -f "$PATCH_DIR/guest-wifi-init" ]; then
    cp -f "$PATCH_DIR/guest-wifi-init" "$GUEST_WIFI_INIT"
    chmod +x "$GUEST_WIFI_INIT"
    echo "[patch-v2] init script replaced -> $GUEST_WIFI_INIT"
else
    echo "[patch-v2][WARN] init script not found (INIT='$GUEST_WIFI_INIT')"
fi

# 4) uci-defaults（建默认配置并启用服务）
GUEST_WIFI_UCIDEF="$(find feeds -type f -path '*/luci-app-guest-wifi/root/etc/uci-defaults/40_luci-guest-wifi' -print -quit 2>/dev/null)"
if [ -n "$GUEST_WIFI_UCIDEF" ] && [ -f "$PATCH_DIR/40_luci-guest-wifi" ]; then
    cp -f "$PATCH_DIR/40_luci-guest-wifi" "$GUEST_WIFI_UCIDEF"
    chmod +x "$GUEST_WIFI_UCIDEF"
    echo "[patch-v2] uci-defaults replaced -> $GUEST_WIFI_UCIDEF"
else
    echo "[patch-v2][WARN] uci-defaults not found (UCIDEF='$GUEST_WIFI_UCIDEF')"
fi
