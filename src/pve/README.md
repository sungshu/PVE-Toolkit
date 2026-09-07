# PVE Toolkit

**Proxmox VE Infrastructure Toolkit**：針對 **PVE 9 / Debian 13 Trixie** 的主機初始化、系統整理、硬體監控與 PVE 實戰文件。

本目錄是 PVE Toolkit 的主要 PVE 模組。真正執行主機初始化的是 `pve_config_notes.sh`；硬體監控則由獨立的 `monitor/disk_monitor.sh` 負責。兩支腳本的用途不同，但由主入口統一安裝與操作。

---

## 目錄內容

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

- `pve_config_notes.sh`：PVE 主機初始化與環境整理的單一入口。
- `monitor/disk_monitor.sh`：PVE Web UI 硬體監控客製化與硬體資料採集核心。
- `系統初始化與優化.md`：初始化腳本的背景、設定說明與驗證方式。
- `monitor/硬體監控客製化.md`：硬體監控的完整架構、備份、安裝與還原說明。
- `ceph/`：Ceph 實作與儲存相關文件，屬於選用的實戰內容。
- `pbs/`：PBS 安裝與儲存規劃文件，屬於選用的實戰內容。

---

# pve_config_notes.sh

## 版本

**pve_config_notes.sh v2.1.7**  
更新日期：**2026-09-07**

`pve_config_notes.sh` 是 PVE Toolkit 的**主安裝／初始化腳本**。

它不是單純「執行幾個 apt 指令」的安裝腳本，而是將一台剛安裝或需要重新整理的 PVE 9 主機，依照 Toolkit 預先定義的環境設定進行整理，最後部署硬體監控核心。

簡單來說：

```text
PVE 9 主機
   │
   ├─ APT Repository 整理
   ├─ 時區與 Chrony
   ├─ PVE Subscription Nag Hook
   ├─ 必要套件
   ├─ Datacenter Tag
   └─ Hardware Monitor
          │
          └─ /root/disk_monitor.sh
```

---

## pve_config_notes.sh 實際會做什麼？

腳本目前分成 6 個主要階段。

### [1/6] APT 來源設定

執行前會先建立一個時間戳記備份目錄：

```text
/root/apt-sources-backup-YYYY-MM-DD-HHMMSS/
```

並備份：

```text
/etc/apt/sources.list
/etc/apt/sources.list.d/
```

之後清理舊的 APT source，再建立 Toolkit 使用的來源。

### 會清理的 APT 來源

腳本會移除下列可能存在的舊檔案：

```text
/etc/apt/sources.list

/etc/apt/sources.list.d/debian.sources
/etc/apt/sources.list.d/pve-enterprise.list
/etc/apt/sources.list.d/pve-enterprise.sources
/etc/apt/sources.list.d/pve-install-repo.list
/etc/apt/sources.list.d/pve-install-repo.sources
/etc/apt/sources.list.d/pve-no-subscription.list
/etc/apt/sources.list.d/pve-no-subscription.sources
/etc/apt/sources.list.d/ceph.list
/etc/apt/sources.list.d/ceph.sources
/etc/apt/sources.list.d/ceph-enterprise.list
/etc/apt/sources.list.d/ceph-enterprise.sources
/etc/apt/sources.list.d/ceph-no-subscription.list
/etc/apt/sources.list.d/ceph-no-subscription.sources
```

這裡的目的不是刪除套件，而是**清除舊的／重複的 repository 設定，避免 Enterprise、舊格式或重複來源造成 APT 衝突**。

### 重新建立的來源

預設會建立：

```text
/etc/apt/sources.list.d/debian.sources
/etc/apt/sources.list.d/pve-no-subscription.sources
```

其中 Debian 使用 TWDS mirror，另外加入 Debian Security；PVE 使用 `pve-no-subscription` repository。

如果指定 `--ceph`，另外建立：

```text
/etc/apt/sources.list.d/ceph-no-subscription.sources
```

### 重要

**APT source 是「先備份 → 清理 → 重建」，不是直接覆蓋而不留紀錄。**

每執行一次初始化，都會產生新的：

```text
/root/apt-sources-backup-YYYY-MM-DD-HHMMSS/
```

歷史備份不會由腳本自動刪除。

---

## [2/6] 時區與 Chrony

腳本會將系統時區設定為：

```text
Asia/Taipei
```

並建立／覆寫：

```text
/etc/chrony/chrony.conf
```

預設 NTP：

```text
pool tick.stdtime.gov.tw iburst
pool tock.stdtime.gov.tw iburst
pool tw.pool.ntp.org iburst
```

也可以透過環境變數加入內部 NTP Server：

```bash
INTERNAL_NTP=192.168.0.100 bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh)
```

服務會啟用並立即啟動：

```text
chrony
```

腳本同時會驗證 Timezone 與 Chrony 的 active/enabled 狀態。

---

## [3/6] PVE Subscription Nag Hook

腳本會建立：

```text
/etc/apt/apt.conf.d/no-nag-script
```

這個 APT hook 的用途，是在 `proxmox-widget-toolkit` 更新後檢查官方 `proxmoxlib.js`，必要時重新套用 Subscription Nag 的客製化處理。

也就是說，它不是單純修改一次 Web UI，而是利用 APT 的 Post-Invoke 機制，在相關套件更新後再次檢查。

因此這個檔案屬於 Toolkit 的 PVE Web UI 客製化設定。

---

## [4/6] 必要套件

腳本會先執行：

```bash
apt update
```

接著安裝硬體監控與系統工具：

```text
chrony
lm-sensors
smartmontools
linux-cpupower
nvme-cli
hdparm
curl
wget
util-linux
jq
```

另外會重新安裝：

```text
proxmox-widget-toolkit
```

最後逐一確認必要套件是否真的處於：

```text
install ok installed
```

### `--upgrade`

如果指定：

```bash
--upgrade
```

則在上述套件處理後，再執行：

```bash
apt full-upgrade -y
```

所以 `--upgrade` 與一般執行的差異是：

```text
一般執行
→ 初始化與必要套件安裝

--upgrade
→ 初始化與必要套件安裝
→ apt full-upgrade
```

---

## [5/6] Datacenter Tag

腳本會修改：

```text
/etc/pve/datacenter.cfg
```

將 `tag-style` 設定為：

```text
tag-style: shape=full,ordering=alphabetical
```

效果是讓 PVE Datacenter Tag 使用完整膠囊樣式，並依字母排序。

如果原本已有 `tag-style`，腳本會修改既有設定；沒有則新增。

---

## [6/6] 硬體監控

這是主腳本最後的部署階段。

正式硬體監控程式固定安裝於：

```text
/root/disk_monitor.sh
```

每次執行初始化時，會先移除舊的：

```bash
rm -f /root/disk_monitor.sh
```

接著從 GitHub 下載最新版 `disk_monitor.sh` 到暫存檔，驗證版本必須是：

```text
1.0.52
```

驗證成功後才移動成正式檔案：

```text
/root/disk_monitor.sh
```

因此這裡的流程是：

```text
舊版 /root/disk_monitor.sh
        ↓
       刪除
        ↓
下載新版暫存檔
        ↓
驗證 VERSION=1.0.52
        ↓
/root/disk_monitor.sh
```

如果下載或版本驗證失敗，暫存檔會被清除，不會把未驗證的檔案當成正式版本。

---

# 執行後會留下什麼？

如果直接使用：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh)
```

`pve_config_notes.sh` 本身是透過 shell process substitution 執行，**不會自動留下 `/root/pve_config_notes.sh`**。

正常情況下 `/root` 可能看到：

```text
/root/
├── apt-sources-backup-2026-09-07-143626/
├── apt-sources-backup-2026-09-07-144849/
└── disk_monitor.sh
```

其中：

| 項目 | 用途 |
|---|---|
| `apt-sources-backup-*` | 初始化前的 APT 設定備份，每次執行會產生新的目錄 |
| `disk_monitor.sh` | 實際供 PVE 硬體監控使用的正式腳本 |
| `pve_config_notes.sh` | 使用 `bash <(curl ...)` 時不會自動留在 `/root` |

---

# pve_config_notes.sh 會刪除什麼？

這部分特別列出，避免第一次使用的人不知道腳本會動到哪些檔案。

### APT

會先備份，再清除指定的舊 repository 設定，包括：

```text
/etc/apt/sources.list
/etc/apt/sources.list.d/debian.sources
/etc/apt/sources.list.d/pve-enterprise.*
/etc/apt/sources.list.d/pve-install-repo.*
/etc/apt/sources.list.d/pve-no-subscription.*
/etc/apt/sources.list.d/ceph.*
```

實際刪除範圍限於腳本指定的檔名，不是把整個 `/etc/apt/sources.list.d/` 目錄清空。

### Hardware Monitor

會刪除舊的：

```text
/root/disk_monitor.sh
```

然後重新下載並驗證新版。

### 暫存檔

腳本執行過程使用的：

```text
/tmp/pve_toolkit_step.$$
```

在正常結束時會清除。

---

# 哪些東西不會由 pve_config_notes.sh 自動處理？

這支腳本的範圍是**主機環境初始化與 Toolkit 硬體監控部署**，不是 VM／CT 或整個 PVE 基礎架構的自動化建置工具。

它不會自動：

- 建立 VM
- 建立 CT
- 修改既有 VM 設定
- 修改既有 CT 設定
- 建立或刪除 Storage
- 修改 VM/CT 磁碟資料
- 修改 Bridge / NIC IP 設定
- 建立 Firewall Policy
- 建立 Ceph Cluster
- 建立 Ceph OSD
- 初始化 PBS
- 執行 VMware → PVE Migration

Ceph、PBS、VMware 等內容在本專案中保留為**獨立的實戰文件或選用功能**，不會因為執行一般 PVE 初始化就自動建立。

---

# 執行方式

## 一般初始化

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh)
```

用途：

```text
APT 整理
→ 時區 / Chrony
→ Subscription Nag Hook
→ 必要套件
→ Datacenter Tag
→ disk_monitor.sh
```

## 系統升級

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) --upgrade
```

在一般初始化流程後執行：

```bash
apt full-upgrade -y
```

## 啟用 Ceph repository

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) --ceph
```

只是在 APT 初始化流程中加入：

```text
ceph-no-subscription.sources
```

**不代表會建立 Ceph Cluster 或 OSD。**

## Ceph + 系統升級

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) --ceph --upgrade
```

## 重新套用硬體監控

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) remod
```

此模式不會重新執行完整 PVE 初始化，而是轉呼叫：

```text
/root/disk_monitor.sh remod
```

## 還原硬體監控客製化

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) restore
```

此模式同樣轉呼叫：

```text
/root/disk_monitor.sh restore
```

它的用途是**還原硬體監控所客製化的 PVE 官方 Web UI / API 檔案與相關監控排程**。

> 注意：`restore` 不是「完整還原 pve_config_notes.sh 所有設定」。它主要是 `disk_monitor.sh` 的還原功能；例如 APT source、Timezone、Chrony、Datacenter Tag 等，不會因執行 `restore` 自動恢復。

---

# disk_monitor.sh

## 版本

**disk_monitor.sh v1.0.52**  
更新日期：**2026-09-01**

`disk_monitor.sh` 是 PVE Toolkit 的硬體監控核心。

它負責收集主機硬體資訊，建立 runtime JSON，再將資料整合到 PVE Node Summary 的客製化介面。

### 主要監控內容

- CPU 頻率
- CPU governor
- CPU min/max frequency
- CPU PkgWatt（系統有 turbostat 時）
- CPU / 主機 thermal 資訊
- NVMe SMART 與健康資訊
- SATA / SAS SSD
- SATA / SAS HDD
- MegaRAID Physical Disk
- MegaRAID SMART
- RAID Physical Disk 與 `/dev/sdX` 對應
- SMART `OK` / `FAIL` / `UNKNOWN`
- PVE Disk Inventory

### 資料採集方式

硬體資料會先寫入 runtime：

```text
/run/disk_monitor_runtime/
```

以及執行期間的 JSON：

```text
/run/disk_monitor.<PID>/
```

最終資料入口：

```text
/run/disk_monitor.json
```

並透過 cron 定期採集：

```text
/etc/cron.d/disk_monitor
```

---

# disk_monitor.sh 的官方檔案備份與還原

硬體監控需要客製化 PVE 官方程式，因此安裝前會建立版本化的官方檔案備份。

備份位置：

```text
/var/lib/disk_monitor/<PVE版本>/
```

包含：

```text
Nodes.pm
pvemanagerlib.js
proxmoxlib.js
```

用途是確保監控客製化與 PVE 官方檔案之間有明確的版本對應，並讓 `restore` 可以回復官方檔案。

如果 PVE 升級，應重新確認硬體監控客製化與官方檔案版本是否一致。

---

# 單獨安裝 disk_monitor.sh

如果不使用主初始化腳本，也可以單獨安裝：

```bash
curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/monitor/disk_monitor.sh -o /root/disk_monitor.sh
chmod +x /root/disk_monitor.sh
/root/disk_monitor.sh
```

不過正常使用 PVE Toolkit 時，建議直接由 `pve_config_notes.sh` 統一部署，因為主腳本會負責下載、版本驗證與必要套件準備。

---

# 硬體監控完整文件

完整的監控架構、PVE 官方檔案修改、runtime JSON、RAID Map、cron、備份與 restore 說明：

- [硬體監控客製化](./monitor/硬體監控客製化.md)

---

# PVE 文件

- [系統初始化與優化](./系統初始化與優化.md)
- [硬體監控客製化](./monitor/硬體監控客製化.md)
- [H755 從 RAID 轉 Non-RAID 與 OSD 建置](./ceph/H755從RAID轉Non-RAID與OSD建置.md)
- [PBS 安裝與儲存規劃](./pbs/PBS安裝與儲存規劃.md)

---

# VMware

VMware → PVE 的遷移評估獨立放在 `src/vmware/`。

- [VMware 遷移至 PVE 評估](../vmware/VMware遷移至PVE評估.md)
