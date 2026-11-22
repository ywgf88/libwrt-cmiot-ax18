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
