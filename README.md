# PVE Toolkit

**Proxmox VE Infrastructure Toolkit**：把 PVE 主機初始化、硬體監控、Ceph、PBS 與 VMware → PVE 遷移實戰整理在同一個清楚的專案結構中。

## 這個專案到底要幹嘛？

一句話：**把實際部署 PVE 時會反覆使用的腳本、硬體監控與基礎架構實戰文件，整理成可以直接拿來用、也能持續維護的 Toolkit。**

目前分成兩個層次：

```text
工具層
└── src/pve/pve_config_notes.sh
    └── PVE 初始化／優化單一入口
        └── 自動安裝 monitor/disk_monitor.sh

技術文件層
├── src/pve/ceph/      → Ceph / OSD / 儲存
├── src/pve/pbs/       → PBS / 備份 / 儲存規劃
├── src/pve/monitor/   → 硬體監控核心與完整技術說明
└── src/vmware/        → VMware → PVE 遷移評估
```

`img/` 則只保存對應模組的實機畫面，不混放腳本或文件。

## 目前版本

- **PVE**：9.x（Debian 13 Trixie）
- **PVE 初始化／優化入口**：`pve_config_notes.sh v2.0.0`
- **硬體監控核心**：`disk_monitor.sh v1.0.52`
- **更新日期**：2026-09-07

## 目錄結構

```text
PVE-Toolkit/
├── README.md
├── img/
│   ├── pve/
│   │   ├── ceph/
│   │   ├── pbs/
│   │   └── monitor/       # 硬體監控實機畫面
│   └── vmware/
└── src/
    ├── pve/
    │   ├── README.md
    │   ├── pve_config_notes.sh
    │   ├── 系統初始化與優化.md
    │   ├── ceph/
    │   │   └── H755從RAID轉Non-RAID與OSD建置.md
    │   ├── pbs/
    │   │   └── PBS安裝與儲存規劃.md
    │   └── monitor/
    │       ├── disk_monitor.sh
    │       └── 硬體監控客製化.md
    └── vmware/
        └── VMware遷移至PVE評估.md
```

## 🚀 PVE 主機一鍵初始化

主入口是 `src/pve/pve_config_notes.sh`。

### 預設安裝

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh)
```

預設會：

- 備份並重建 Debian APT 來源
- 使用 TWDS Debian mirror 與 Debian Security
- 設定 PVE no-subscription repository
- 清除 PVE／Ceph enterprise source 與重複來源
- 設定 `Asia/Taipei` 與 Chrony
- 安裝必要硬體監控工具
- 設定 subscription nag Hook
- 設定 Datacenter Tag 膠囊樣式與字母排序
- 自動下載並執行 `monitor/disk_monitor.sh v1.0.52`

### 常用參數

```bash
# 完整系統升級
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) --upgrade

# 啟用 Ceph Squid no-subscription repository
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) --ceph

# Ceph + 完整升級
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) --ceph --upgrade

# 重新套用硬體監控 UI
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) remod

# 還原官方 UI
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) restore
```

> `--upgrade` 會執行 `apt full-upgrade -y`，正式環境請安排維護時段。

### 內部 NTP

```bash
INTERNAL_NTP=192.168.0.100 bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh)
```

## 🖥️ 硬體監控

`disk_monitor.sh v1.0.52` 是目前正式版核心，將 CPU、CPU 溫度、網卡溫度、NVMe、SATA/SAS、MegaRAID Physical Disk 與 SMART 整合到 PVE Node Summary。

主要能力：

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

- [硬體監控客製化](src/pve/monitor/硬體監控客製化.md)

## 📚 技術文件

### PVE 系統

- [系統初始化與優化](src/pve/系統初始化與優化.md)
- [PVE Toolkit 腳本與硬體監控說明](src/pve/README.md)

### Ceph

- [H755 從 RAID 轉 Non-RAID 與 OSD 建置](src/pve/ceph/H755從RAID轉Non-RAID與OSD建置.md)

### PBS

- [PBS 安裝與儲存規劃](src/pve/pbs/PBS安裝與儲存規劃.md)

### VMware

- [VMware 遷移至 PVE 評估](src/vmware/VMware遷移至PVE評估.md)

## 📐 整理原則

這個 repository 不再採用「想到什麼就丟一個資料夾」的方式：

- **PVE** 是主分類。
- **monitor / ceph / pbs** 是 PVE 底下的功能模組。
- **VMware** 保留獨立分類，因為它描述的是遷移來源平台，而不是 PVE 主機本身。
- **src** 放工具與文件；**img** 放圖片。
- 同一份內容只保留一份，不建立頂層重複副本。
- 已實機驗證的核心腳本不因文件整理而重寫功能。

## ⚠️ 使用前注意

- 初始化前請先確認 PVE 節點的 APT、叢集、儲存與網路狀態。
- 涉及 RAID / Non-RAID、Ceph OSD 或 ZFS 的操作可能清除資料，務必先確認備份。
- PVE／PBS 升級後，UI Hook 與 API 結構可能改變，正式環境先在測試節點驗證。

## 作者

**sungshu 手札筆記本**
