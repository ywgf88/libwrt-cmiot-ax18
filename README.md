# LibWrt 云编译 — cmiot_ax18（中移物联 AX18 / IPQ6000）

基于 [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt) 工作流，使用 [LiBwrt/LibWrt](https://github.com/LiBwrt/LibWrt) 源码为 **cmiot_ax18** 编译 OpenWrt 固件。

## 基本信息

| 项目 | 内容 |
| --- | --- |
| 本仓库 | https://github.com/ywgf88/libwrt-cmiot-ax18 |
| 源码仓库 | https://github.com/LiBwrt/LibWrt |
| 源码分支 | `25.12-nss` |
| 平台 / 内核 | qualcommax / ipq60xx，内核 6.12，NSS 满血加速 |
| 目标机型 | `cmiot_ax18`（CMIOT AX18，IPQ6000） |
| 默认管理地址 | `192.168.9.1`（root 密码为空，首登请先设密码） |
| 最新固件 | [Release 2026.11.22-0931](https://github.com/ywgf88/libwrt-cmiot-ax18/releases/tag/2026.11.22-0931) |
| 编译环境 | GitHub Actions `ubuntu-22.04` |
| 参考配置 | https://github.com/hili68888/libwrt-cmiot_ax18_6.12- ；内存调优参考 https://github.com/ywgf88/OpenWRT-CI |

## 固件特性

- 中文 LuCI 后台（`luci` + `zh_Hans`）
- **Argon 主题**（`luci-theme-argon` 3.1.4，immortalwrt luci feed 内置）：明 / 暗 / 纯黑模式 + 玻璃拟态，自带「Argon 配置」页，**默认主题**
- **内置 4 个第三方主题**（kenzok8 feed，后台 系统 → 语言和外观 可切换）：Carbon、Glass、Liquid、Vantage；默认外观由 `98-default-theme-argon` 兜底锁定为 Argon，不会被其他主题抢占
  - 均为现代 ucode 模板结构；
  - 已剔除 Design / iFIT：二者为旧版 Lua 模板，在 25.12 ucode 调度器下调用已不存在的 `_entries` 状态，选中即导致 LuCI 后端崩溃
- **HomeProxy 代理平台**：sing-box 1.12.25 内核，依赖 firewall4 / kmod-tun / nft-tproxy / ucode-mod-digest
- 高通 NSS 硬件转发加速（ECM / 网桥管理 / VLAN）
- 轻量代理依赖：TUN、nftables tproxy/socket/bridge/nat、ipset、ip-full、bash、curl、ca-bundle、unzip 等
- dnsmasq-full（DNS 分流，缓存提到 8192）
- 运维工具：ttyd 免登录、UPnP、DDNS、文件助手（含中文包）、LED 触发控制
- **访客 WiFi 插件**（`luci-app-guest-wifi`）：旧版 Lua 应用，经 luci-compat 兼容层运行；配合已恢复的 ath11k 无线，可在「网络 → Guest WiFi」配置访客 SSID
- **1G 内存调优**（移植自 OpenWRT-CI，首启执行一次，写入 `/etc` 长期保留）：
  - 内核网络缓冲放大：rmem/wmem 16MiB、tcp_rmem/tcp_wmem、conntrack_max 65536
  - DNS 缓存 1500 → 8192；系统日志环缓冲 64KB → 256KB
  - HomeProxy 看板资源（约 8MiB）软链到 `/tmp` 内存盘，避免占用 overlay
- **无线已恢复**：编入 ath11k 驱动栈（IPQ6018 板载双频，AHB）+ `ath11k-firmware-ipq6018` + `ipq-wifi-cmiot_ax18` 板级 BDF + `wpad-openssl`；无 USB，已关闭 USB 存储组件

## 产物说明

文件名前缀：`libwrt-qualcommax-ipq60xx-cmiot_ax18-`

| 文件 | 用途 |
| --- | --- |
| `...-squashfs-factory.ubi` | 首刷固件（原厂系统 / U-Boot 下首次写入） |
| `...-squashfs-sysupgrade.bin` | 系统内升级包（OpenWrt 下 LuCI「备份与升级」或 `sysupgrade`） |
| `...-initramfs-uImage.itb` | 内存启动镜像（救急 / 试用，不写 flash） |
| `...manifest` | 固件内全部软件包清单（含版本号） |
| `sha256sums` | 各产物校验和 |

## 目录说明

| 文件 | 作用 |
| --- | --- |
| `.github/workflows/build.yml` | GitHub Actions 编译工作流（含 `contents: write` 权限以自动发布 Release） |
| `.config` | 机型锁定与软件包配置 |
| `diy-part1.sh` | 更新 feeds 前执行：追加 helloworld、kenzok8 第三方插件源 |
| `diy-part2.sh` | 安装 feeds 后执行：改默认 IP、dnsmasq → dnsmasq-full、ttyd 免登录、调优脚本赋权（BDF 切除手术已注释） |
| `files/etc/init.d/homeproxy-ram` | 开机把 HomeProxy 看板软链到 `/tmp` 内存盘 |
| `files/etc/uci-defaults/97-ram-tune` | 首启内存 / 网络缓冲调优（sysctl + DNS 缓存 + 日志缓冲 + 启用看板重定向） |
| `files/etc/uci-defaults/98-default-theme-argon` | 兜底脚本：所有主题首启脚本跑完后，强制默认主题回到 Argon |

## 如何编译

1. 推送本仓库到 GitHub（工作流已包含 `workflow_dispatch` 手动触发）。
2. 仓库页面 → **Actions** → 选择 **Build LibWrt (cmiot_ax18)** → **Run workflow**。
3. 下载源码 + 编译约需 1.5 小时；完成后：
   - 固件打包在 Actions 页面右上角 **Artifacts**（`OpenWrt_firmware_...`）；
   - 同时自动发布到仓库 **Releases**（默认保留最近 3 个，旧运行记录一并清理）。
4. 产物位于源码树 `bin/targets/qualcommax/ipq60xx/`，日常升级用 `sysupgrade.bin`。

## 备注

- **无线驱动栈**（2026-11-22 恢复）：AX18 为 IPQ6018 AX1800，双频均板载 AHB，无需 PCIe/QCN9074。`.config` 已编入 `kmod-ath11k` + `kmod-ath11k-ahb` + `ath11k-firmware-ipq6018` + `ipq-wifi-cmiot_ax18`（板级 BDF）+ `wpad-openssl`；`diy-part2.sh` 中擦除 BDF 的 `find ... sed` 已注释。
  - 若改回纯有线：把上述五行改回 `=n`，并取消 `diy-part2.sh` 中该 sed 的注释。
  - **刷机注意**：sysupgrade 时取消勾选「保留配置」，否则旧的空 `wireless` 文件会残留导致无线仍不可用。
  - 验证：`dmesg | grep ath11k` 应见 IPQ6018 加载成功；`wifi status` 两个 radio 均起来；`cat /etc/config/wireless` 非空。
- **更换主题**：固件内已编入 5 套主题（Argon + Carbon/Glass/Liquid/Vantage），后台 **系统 → 语言和外观** 直接切换；Argon 的外观、背景、明暗模式在 **系统 → Argon 配置** 里调整。增删主题在 `.config` 中改 `CONFIG_PACKAGE_luci-theme-*` 行即可。
- 个别插件若在 feeds 中不存在，`make defconfig` 会自动丢弃对应选项，不影响编译。
- **Design / iFIT 为何不在固件里**：这两套旧版 Lua 主题的头部模板调用 `disp.node()` / `disp.node_childs()` 读取旧调度器的 `_entries` 全局状态，25.12 ucode 调度器不再提供该状态，选中后 LuCI 后端直接崩溃（`attempt to index global '_entries' (a nil value)`），故不编入；如需使用需等上游改成 ucode 模板。
