# PVE Toolkit

**Proxmox VE Infrastructure Toolkit**：PVE 9（Debian 13 Trixie）台灣環境主機初始化、優化與硬體監控工具。

## 這個專案在做什麼？

PVE Toolkit 把日常 PVE 基礎建置與實機維運工具集中在同一個入口：

```text
PVE Toolkit
├── 主機初始化／優化
│   └── pve_config_notes.sh
├── 硬體監控
│   └── monitor/disk_monitor.sh
├── Ceph
│   └── ceph/
└── PBS
    └── pbs/
```

主腳本負責 PVE 初始化與優化；硬體監控核心維持獨立，透過主腳本統一安裝與操作。Ceph、PBS 與 VMware 遷移則以獨立實戰文件整理，不把不同用途硬塞進同一支腳本。

## 倉庫結構

```text
src/pve/
├── README.md
├── pve_config_notes.sh
├── 系統初始化與優化.md
├── ceph/
│   └── H755從RAID轉Non-RAID與OSD建置.md
├── pbs/
│   └── PBS安裝與儲存規劃.md
└── monitor/
    ├── disk_monitor.sh
    └── 硬體監控客製化.md
```

`src/` 放工具與技術文件；`img/` 只放對應的實機畫面。

## pve_config_notes.sh v2.0.0

v2.0.0 是 PVE Toolkit 的**單一入口**，負責 PVE 系統初始化／優化，以及安裝與轉呼叫硬體監控核心。

本腳本處理：

- 備份並重建 Debian APT 來源
- TWDS Debian mirror、Debian Security
- PVE no-subscription repository
- 可選 Ceph Squid no-subscription repository
- 清除 PVE／Ceph enterprise source 與重複來源
- `Asia/Taipei` 時區與 Chrony
- 必要硬體監控工具
- PVE subscription nag Hook
- Datacenter Tag 膠囊樣式與字母排序
- 自動下載並執行 `monitor/disk_monitor.sh v1.0.52`

### 直接執行

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh)
```

### 常用參數

```bash
# 完整系統升級
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) --upgrade

# 啟用 Ceph Squid no-subscription
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) --ceph

# Ceph + 完整升級
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) --ceph --upgrade

# 重新套用硬體監控 UI
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) remod

# 還原官方 UI
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) restore
```

> `remod` 與 `restore` 會轉呼叫已安裝的 `/root/disk_monitor.sh`，因此第一次使用前需先完成硬體監控安裝。

### 內部 NTP

```bash
INTERNAL_NTP=192.168.0.100 bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh)
```

## disk_monitor.sh v1.0.52

**2026-09-01 正式版，實機測試完成。**

硬體監控核心將 CPU、CPU 溫度、網卡溫度、NVMe、SATA/SAS、MegaRAID Physical Disk 與 SMART 資訊整合到 PVE Node Summary。

主要功能：

- CPU 頻率、governor、PkgWatt
- 多 CPU／多插槽與網卡溫度
- NVMe SMART 與健康資訊
- SATA / SAS SSD、HDD 分類
- MegaRAID Physical Disk 自動分流與 RAID Map
- SMART `OK` / `FAIL` / `UNKNOWN`
- 背景 runtime JSON 採集
- 每分鐘 cron 採集
- PVE 官方檔案版本化備份與 restore
- `install`、`collect`、`restore`、`remod`

### 單獨安裝硬體監控

```bash
curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/monitor/disk_monitor.sh -o /root/disk_monitor.sh
chmod +x /root/disk_monitor.sh
/root/disk_monitor.sh
```

完整架構與實機驗證：

- [硬體監控客製化](./monitor/硬體監控客製化.md)

## PVE 文件

- [系統初始化與優化](./系統初始化與優化.md)
- [硬體監控客製化](./monitor/硬體監控客製化.md)
- [H755 從 RAID 轉 Non-RAID 與 OSD 建置](./ceph/H755從RAID轉Non-RAID與OSD建置.md)
- [PBS 安裝與儲存規劃](./pbs/PBS安裝與儲存規劃.md)

## VMware

VMware 遷移至 PVE 的評估文件獨立放在 `src/vmware/`。

- [VMware 遷移至 PVE 評估](../vmware/VMware遷移至PVE評估.md)

## 文件維護原則

- `src/pve/`：PVE 工具與所有 PVE 技術文件。
- `src/pve/ceph/`：Ceph 實作與儲存相關文件。
- `src/pve/pbs/`：PBS 備份與儲存規劃文件。
- `src/pve/monitor/`：硬體監控程式與完整技術說明。
- `src/vmware/`：VMware → PVE 遷移評估。
- `img/`：與模組對應的實機截圖，不放文件或腳本。
