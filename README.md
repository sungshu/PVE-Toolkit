# PVE Toolkit

**Proxmox VE 的系統初始化、優化與硬體監控工具箱 —— 一行命令，快速就緒。**

![PVE Toolkit 自動化管理流程](img/p00/PVE-Toolkit_自動化管理流程.jpg)

> **目前版本：PVE Toolkit 2.1.7**  
> **適用環境：Proxmox VE 9.x / Debian 13 Trixie**

PVE Toolkit 是針對 Proxmox VE 主機日常建置與維護所整理的 Shell 工具與實戰文件。

它不取代 PVE 原生命令，而是把主機初始化、系統優化、硬體監控與 PVE Web UI 客製化等常用工作集中整理，讓需要重複執行或容易遺漏的步驟，可以透過固定流程快速完成。

---

## 📋 專案簡介

PVE Toolkit 目前主要包含兩個部分：

| 功能 | 說明 |
|---|---|
| **PVE 系統初始化與優化** | Repository、時區、Chrony、NTP、必要套件、Datacenter Tag 與系統升級 |
| **PVE 硬體監控客製化** | CPU、溫度、NVMe、SATA/SAS、MegaRAID、SMART 與 Node Summary 顯示 |

---

## 🚀 快速開始

### PVE 主機初始化

在 PVE 主機以 `root` 執行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh)
```

預設會執行：

- APT Repository 設定與備份
- `Asia/Taipei` 時區與 Chrony
- PVE Subscription Nag Hook
- 必要系統與硬體監控套件
- Datacenter Tag 樣式
- 自動部署 `disk_monitor.sh v1.0.52`

### 只需要硬體監控

```bash
curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/disk_monitor.sh -o /root/disk_monitor.sh
chmod +x /root/disk_monitor.sh
/root/disk_monitor.sh
```

正式安裝位置：

```text
/root/disk_monitor.sh
```

---

## ⚙️ 常用操作

### 完整系統升級

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh) --upgrade
```

執行完整 `apt full-upgrade`，更新 PVE 核心、韌體與其他系統套件。

### 啟用 Ceph Squid no-subscription Repository

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh) --ceph
```

### Ceph + 完整系統升級

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh) --ceph --upgrade
```

> `--ceph` 僅加入 Ceph Squid no-subscription repository，不會建立 Ceph Cluster 或 OSD。

### 重新套用硬體監控 UI

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh) remod
```

### 還原官方硬體監控 UI

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh) restore
```

### 指定內部 NTP

機房有內部 NTP 時，可透過 `INTERNAL_NTP` 指定：

```bash
INTERNAL_NTP=192.168.0.100 bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh)
```

`192.168.0.100` 僅為範例，請替換為實際 NTP 位址。

---

## 🛠️ 功能特性

### PVE 系統初始化與優化

- APT Repository 設定與原始設定備份
- Debian 13 Trixie / PVE no-subscription Repository
- `Asia/Taipei` 時區設定
- Chrony 時間同步與內部 NTP 指定
- PVE Subscription Nag Hook
- Datacenter Tag 樣式
- 系統與硬體監控套件安裝
- PVE 系統升級
- Ceph Squid no-subscription Repository

### PVE 硬體監控與 Web UI 客製化

- CPU 資訊與雙插槽溫度
- NVMe 健康資訊與使用量
- SATA / SAS 硬碟資訊
- MegaRAID 硬碟與 SMART 資訊
- 磁碟健康狀態與容量資訊
- Node Summary 硬體資訊整合
- `remod` 重新套用客製化 UI
- `restore` 還原官方 UI

---

## 📚 操作文件

| 文件 | 內容 |
|---|---|
| [00. PVE 系統初始化與優化](00.PVE系統初始化與優化.md) | 初始化、Repository、時間同步、Ceph、升級、重新套用與還原 |
| [01. PVE 硬體監控客製化](01.PVE硬體監控客製化.md) | 硬體資訊收集、Node Summary 客製化、安裝與實機驗證 |

---

## 📦 腳本

| 腳本 | 用途 |
|---|---|
| [`pve_init.sh`](src/pve/pve_init.sh) | PVE 系統初始化、優化、升級、Ceph、UI 套用與還原 |
| [`disk_monitor.sh`](src/pve/disk_monitor.sh) | 硬體資訊收集與 PVE Node Summary 客製化 |

---

## 📁 專案結構

```text
PVE-Toolkit/
├── README.md
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

- `src/pve/`：正式使用的 PVE Shell 工具
- `00.PVE系統初始化與優化.md`：初始化與系統優化文件
- `01.PVE硬體監控客製化.md`：硬體監控與 PVE Web UI 客製化文件
- `img/p00/`：00 文件與專案流程圖
- `img/p01/`：01 文件使用的圖片

---

## ⚠️ 風險與注意事項

PVE Toolkit 會直接修改 PVE 主機設定。執行前請確認現有環境與備份狀態。

本工具會依照所選功能實際執行 PVE 與 Linux 系統命令，包含 Repository、套件、時間同步與 PVE Web UI 客製化等變更。若操作環境不正確，可能造成系統或管理介面異常。

執行前建議確認：

- APT Repository 設定
- Cluster 狀態
- Storage 設定
- Network 設定
- 現有 PVE Web UI 客製化內容
- 必要的系統與設定備份

`--upgrade` 可能更新 PVE 核心，完成後請依實際環境安排重開機。

`--ceph` 僅加入 Ceph Squid no-subscription repository，不會建立 Ceph Cluster 或 OSD。

本工具目前不負責 VM、CT、Storage、Network、Firewall、Ceph Cluster/OSD 或 VMware 遷移等其他 PVE 管理工作。

**使用本工具前，請先確認執行內容與目標主機環境；任何系統變更均應由實際操作人員自行確認並承擔相應風險。**

---

## 👤 作者

**sungshu 手札筆記本**

GitHub：[sungshu.github.io](https://sungshu.github.io/)

---

## 📄 License

本專案採用 **GPL-3.0** 開源授權。
