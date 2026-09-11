# PVE Toolkit

**Proxmox VE 系統初始化、優化與硬體監控工具**

針對 **Proxmox VE 9.x / Debian 13 Trixie**，將 PVE 主機初始化、系統優化與硬體監控客製化集中整理，提供可直接執行的 Shell 工具與完整實機操作文件。

> 目前版本：**PVE Toolkit 2.1.7**  
> 適用環境：**Proxmox VE 9.x / Debian 13 Trixie**

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

## 🛠️ 功能總覽

| 功能模組 | 支援內容 |
|---|---|
| PVE 系統初始化 | APT Repository、時區、Chrony、NTP、必要套件、Datacenter Tag |
| PVE 系統升級 | 完整 `apt full-upgrade` 與 PVE 系統套件更新 |
| Ceph Repository | Ceph Squid no-subscription repository 設定 |
| 硬體監控 | CPU、溫度、NVMe、SATA/SAS、MegaRAID、SMART 等資訊 |
| PVE Web UI 客製化 | Node Summary 硬體資訊整合與客製化顯示 |
| 客製化 UI 維護 | `remod` 重新套用、`restore` 還原官方介面 |

> `pve_init.sh` 負責 PVE 主機初始化與整合部署；`disk_monitor.sh` 負責硬體資訊收集與 Node Summary 客製化。

## 📋 常用指令

所有指令皆可直接從 GitHub 取得最新版 `pve_init.sh` 執行。

### 一般初始化

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh)
```

### 完整系統升級

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh) --upgrade
```

### 啟用 Ceph Squid no-subscription Repository

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh) --ceph
```

### Ceph + 完整系統升級

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_init.sh) --ceph --upgrade
```

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

## 📚 操作文件

### 00. PVE 系統初始化與優化

說明 `pve_init.sh` 的初始化流程、Repository、時間同步、Ceph、升級、重新套用與還原等功能，並提供實際安裝畫面。

👉 [00.PVE系統初始化與優化.md](00.PVE系統初始化與優化.md)

### 01. PVE 硬體監控客製化

說明 `disk_monitor.sh` 的安裝、硬體資訊收集、PVE Node Summary 客製化、重新套用與還原，以及實機驗證結果。

👉 [01.PVE硬體監控客製化.md](01.PVE硬體監控客製化.md)

---

## 🔄 專案流程

![PVE Toolkit 自動化管理流程](img/p00/PVE-Toolkit_自動化管理流程.jpg)

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
- `img/p00/`：00 文件使用的圖片
- `img/p01/`：01 文件使用的圖片

---

## ⚠️ 執行前請確認

PVE Toolkit 會直接修改 PVE 主機設定。正式環境執行前請確認：

- APT Repository 設定
- Cluster 狀態
- Storage 設定
- Network 設定
- 現有 PVE Web UI 客製化內容
- 必要的系統與設定備份

`--upgrade` 可能更新 PVE 核心，完成後請依實際環境安排重開機。

`--ceph` 僅加入 **Ceph Squid no-subscription repository**，不會建立 Ceph Cluster 或 OSD。

本工具目前不負責 VM、CT、Storage、Network、Firewall、Ceph Cluster/OSD 或 VMware 遷移等其他 PVE 管理工作。

---

## 👤 作者

**sungshu 手札筆記本**

GitHub：[sungshu.github.io](https://sungshu.github.io/)
