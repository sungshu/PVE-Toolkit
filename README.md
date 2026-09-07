# PVE Toolkit

**Proxmox VE Infrastructure Toolkit**

集中整理 Proxmox VE 主機初始化、硬體監控與實戰文件。

> 目前版本：**PVE Toolkit 2.1.7**  
> 適用環境：**Proxmox VE 9.x / Debian 13 Trixie**

## 🚀 快速開始

### PVE 主機初始化

在 PVE 主機以 `root` 執行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh)
```

初始化包含：

- APT Repository 設定與備份
- Asia/Taipei 時區與 Chrony
- PVE Subscription Nag Hook
- 必要系統與硬體監控套件
- Datacenter Tag 樣式
- 自動部署 `disk_monitor.sh v1.0.52`

完整流程與實際安裝畫面：

👉 [系統初始化與優化](src/pve/系統初始化與優化.md)

### 常用操作

完整系統升級：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh) --upgrade
```

啟用 Ceph Squid no-subscription repository：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh) --ceph
```

Ceph + 完整升級：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh) --ceph --upgrade
```

內部 NTP：

```bash
INTERNAL_NTP=192.168.0.100 bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh)
```

重新套用硬體監控 UI：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh) remod
```

還原硬體監控 UI：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh) restore
```

## 🖥️ 硬體監控

`disk_monitor.sh v1.0.52` 將 CPU、溫度、NVMe、SATA/SAS、MegaRAID、SMART 等硬體資訊整合至 PVE Node Summary。

正式安裝位置：

```text
/root/disk_monitor.sh
```

完整架構、安裝流程與實機畫面：

👉 [硬體監控客製化](src/pve/monitor/硬體監控客製化.md)

若只需要硬體監控，也可以單獨安裝：

```bash
curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/monitor/disk_monitor.sh -o /root/disk_monitor.sh
chmod +x /root/disk_monitor.sh
/root/disk_monitor.sh
```

## 📚 文件

### PVE

- [系統初始化與優化](src/pve/系統初始化與優化.md)
- [硬體監控客製化](src/pve/monitor/硬體監控客製化.md)

### Ceph

- [H755 從 RAID 轉 Non-RAID 與 OSD 建置](src/pve/ceph/H755從RAID轉Non-RAID與OSD建置.md)

### PBS

- [PBS 安裝與儲存規劃](src/pve/pbs/PBS安裝與儲存規劃.md)

### VMware

- [VMware 遷移至 PVE 評估](src/vmware/VMware遷移至PVE評估.md)

## 📁 專案結構

```text
PVE-Toolkit/
├── README.md
├── src/
│   ├── pve/
│   │   ├── pve_init.sh
│   │   ├── 系統初始化與優化.md
│   │   ├── monitor/
│   │   │   ├── disk_monitor.sh
│   │   │   └── 硬體監控客製化.md
│   │   ├── ceph/
│   │   │   └── H755從RAID轉Non-RAID與OSD建置.md
│   │   └── pbs/
│   │       └── PBS安裝與儲存規劃.md
│   └── vmware/
│       └── VMware遷移至PVE評估.md
└── img/
    ├── pve/
    │   ├── ceph/
    │   ├── pbs/
    │   └── monitor/
    └── vmware/
```

## ⚠️ 執行前請確認

PVE Toolkit 會直接修改 PVE 主機設定，正式環境執行前請確認：

- APT repository 設定
- PVE Cluster 狀態
- Storage 與 Network 設定
- 是否需要執行 `--upgrade`
- 是否需要啟用 Ceph repository

建議正式執行前先確認現有設定並做好必要備份。

## 作者

**sungshu 手札筆記本**

GitHub：[sungshu.github.io](https://sungshu.github.io/)
