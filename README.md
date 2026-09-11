# PVE Toolkit

**Proxmox VE Infrastructure Toolkit**

集中整理 Proxmox VE 主機初始化與硬體監控相關工具與實戰文件。

> 目前版本：**PVE Toolkit 2.1.7**  
> 適用環境：**Proxmox VE 9.x / Debian 13 Trixie**

## 🔄 專案流程

![PVE Toolkit 自動化管理流程](img/p00/PVE-Toolkit_自動化管理流程.png)

## 🚀 快速開始

### PVE 主機初始化

在 PVE 主機以 `root` 執行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh)
```

包含：

- APT Repository 設定與備份
- Asia/Taipei 時區與 Chrony
- PVE Subscription Nag Hook
- 必要系統與硬體監控套件
- Datacenter Tag 樣式
- 自動部署 `disk_monitor.sh v1.0.52`

👉 [完整初始化流程與實機安裝畫面](00.PVE系統初始化與優化.md)

### 常用操作

```bash
# 完整系統升級
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh) --upgrade

# 啟用 Ceph Squid no-subscription repository
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh) --ceph

# Ceph + 完整升級
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh) --ceph --upgrade

# 重新套用硬體監控 UI
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh) remod

# 還原硬體監控 UI
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh) restore
```

內部 NTP 可透過環境變數指定：

```bash
INTERNAL_NTP=192.168.0.100 bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh)
```

## 🖥️ 硬體監控

`disk_monitor.sh v1.0.52` 將 CPU、溫度、NVMe、SATA/SAS、MegaRAID、SMART 等硬體資訊整合至 PVE Node Summary。

正式安裝位置：

```text
/root/disk_monitor.sh
```

👉 [硬體監控客製化與實機畫面](01.PVE硬體監控客製化.md)

若只需要硬體監控，可單獨安裝：

```bash
curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/disk_monitor.sh -o /root/disk_monitor.sh
chmod +x /root/disk_monitor.sh
/root/disk_monitor.sh
```

## 📚 文件

- [00. PVE 系統初始化與優化](00.PVE系統初始化與優化.md)
- [01. PVE 硬體監控客製化](01.PVE硬體監控客製化.md)

## 📁 專案結構

```text
PVE-Toolkit/
├── README.md
│
├── 00.PVE系統初始化與優化.md
├── 01.PVE硬體監控客製化.md
│
├── src/
│   └── pve/
│       ├── pve_init.sh
│       └── disk_monitor.sh
│
└── img/
    ├── p00/
    └── p01/
```

## ⚠️ 執行前請確認

PVE Toolkit 會直接修改 PVE 主機設定。正式環境執行前，請確認 APT、Cluster、Storage、Network 等現有設定，並做好必要備份。

## 作者

**sungshu 手札筆記本**

GitHub：[sungshu.github.io](https://sungshu.github.io/)
