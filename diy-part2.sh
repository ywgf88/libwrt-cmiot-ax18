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

# 修复 luci-theme-design 版本号：上游 PKG_VERSION=5.8.0-20240106 内嵌连字符，
# 25.12 的 apk 打包器（apk-tools）判定版本非法、打包中断；把日期分隔符改为 '.'，
# 最终版本 5.8.0.20240106-r1，符合 apk 版本规范（版本段不含 '-'，'-' 仅用于 release 分隔）。
sed -i 's/^PKG_VERSION:=5\.8\.0-20240106$/PKG_VERSION:=5.8.0.20240106/' feeds/kenzok/luci-theme-design/Makefile 2>/dev/null || true

# TTYD 免登录
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# 【针对 LibWrt 的无线切除手术】从机型 Makefile 定义里抹除强制捆绑的无线板级包
# 遍历 qualcommax 平台下所有 .mk 机型配置文件, 把 cmiot_ax18 强制捆绑的 wifi 依赖行擦除
find target/linux/qualcommax/image/ -name "*.mk" | xargs sed -i 's/ipq-wifi-cmiot_ax18//g' 2>/dev/null

# 自动将基础组件中的 dnsmasq 替换为 dnsmasq-full, 从源头规避包冲突
find include/ target/ -name "Makefile" -o -name "*.mk" | xargs sed -i 's/\bdnsmasq\b/dnsmasq-full/g' 2>/dev/null
