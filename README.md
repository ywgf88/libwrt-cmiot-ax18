# LibWrt 云编译 — cmiot_ax18（中移物联 AX18 / IPQ6000）

基于 [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt) 工作流，使用 [LiBwrt/LibWrt](https://github.com/LiBwrt/LibWrt) 源码为 **cmiot_ax18** 编译 OpenWrt 固件。

## 基本信息

| 项目 | 内容 |
| --- | --- |
| 源码仓库 | https://github.com/LiBwrt/LibWrt |
| 源码分支 | `25.12-nss` |
| 平台 / 内核 | qualcommax / ipq60xx，内核 6.12，NSS 满血加速 |
| 目标机型 | `cmiot_ax18`（CMIOT AX18，IPQ6000） |
| 默认管理地址 | `192.168.9.1`（密码为空） |
| 参考配置 | https://github.com/hili68888/libwrt-cmiot_ax18_6.12- ；内存调优参考 https://github.com/ywgf88/OpenWRT-CI |

## 固件特性

- 中文 LuCI 后台（`luci` + `zh_Hans`）
- **HomeProxy 代理平台**：sing-box 内核，依赖 firewall4 / kmod-tun / nft-tproxy / ucode-mod-digest
- 高通 NSS 硬件转发加速（ECM / 网桥管理 / VLAN）
- 轻量代理依赖：TUN、nftables tproxy/socket/bridge/nat、ipset、ip-full、bash、curl、ca-bundle 等
- dnsmasq-full（DNS 分流，缓存提到 8192）
- ttyd 免登录、UPnP、DDNS、文件助手、LED 控制
- **1G 内存调优**（移植自 OpenWRT-CI，首启执行一次）：放大内核网络缓冲（rmem/wmem 16MiB、tcp 缓冲、conntrack 65536）、日志环缓冲 256KB、HomeProxy 看板资源重定向到 `/tmp` 内存盘以节省 overlay
- **纯净有线主/旁路由**：已剔除 ath11k 无线驱动、wpad 与板级无线固件包；无 USB，已关闭 USB 存储组件

## 目录说明

| 文件 | 作用 |
| --- | --- |
| `.github/workflows/build.yml` | GitHub Actions 编译工作流 |
| `.config` | 机型锁定与软件包配置 |
| `diy-part1.sh` | 更新 feeds 前执行（追加第三方插件源） |
| `diy-part2.sh` | 安装 feeds 后执行（改默认 IP、剔无线板级包、dnsmasq 替换等） |
| `files/etc/init.d/homeproxy-ram` | 把 HomeProxy 看板软链到 `/tmp` 内存盘 |
| `files/etc/uci-defaults/97-ram-tune` | 首启内存/网络缓冲调优（sysctl + DNS 缓存 + 日志缓冲） |

## 如何编译

1. 推送本仓库到 GitHub（工作流已包含 `workflow_dispatch` 手动触发）。
2. 仓库页面 → **Actions** → 选择 **Build LibWrt (cmiot_ax18)** → **Run workflow**。
3. 首次下载源码 + 编译约需 1～2 小时；完成后：
   - 固件打包在 Actions 页面右上角 **Artifacts**（`OpenWrt_firmware_...`）；
   - 同时会发布到仓库 **Releases**（默认保留最近 3 个）。
4. 产物位于源码树 `bin/targets/qualcommax/ipq60xx/`，常规使用 `sysupgrade.bin` 升级包。

## 备注

- 本版按参考项目做成**纯有线**固件。若需要保留无线，编辑 `.config`：
  - 把 `CONFIG_PACKAGE_kmod-ath11k=n`、`CONFIG_PACKAGE_kmod-ath11k-ahb=n`、`CONFIG_PACKAGE_wpad-openssl=n` 三行改为 `=y`（或直接删除）；
  - 并注释掉 `diy-part2.sh` 中擦除 `ipq-wifi-cmiot_ax18` 的那条 `find ... sed` 命令。
- 个别插件若在 feeds 中不存在，`make defconfig` 会自动丢弃对应选项，不影响编译。
- 编译环境：GitHub Actions `ubuntu-22.04`。
