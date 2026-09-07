# PVE Toolkit

**Proxmox VE Infrastructure Toolkit**：PVE 系統初始化、優化、硬體監控與實戰工具。

## 介紹

本專案已從單純的「Config Notes」逐步發展為可直接部署的 PVE Toolkit，持續累積 PVE、Ceph、PBS、VMware 遷移與實戰工具。

- PVE 版本：9.x（Debian 13 Trixie）
- 主機初始化／優化入口：`pve_config_notes.sh v2.0.0`
- 硬體監控正式版：`disk_monitor.sh v1.0.52`
- 更新日期：2026-09-07

## 目錄結構

```text
pve_config_notes/
├── img/
│   ├── pve/
│   │   ├── ceph/
│   │   ├── pbs/
│   │   └── monitor/
│   └── vmware/
└── src/
    ├── pve/
    │   ├── pve_config_notes.sh       # PVE 初始化／優化單一入口 v2.0.0
    │   ├── 系統初始化與優化.md
    │   ├── ceph/
    │   ├── pbs/
    │   └── monitor/
    │       ├── disk_monitor.sh       # 硬體監控核心 v1.0.52
    │       └── 硬體監控客製化.md
    ├── ceph/
    ├── pbs/
    └── vmware/
```

## PVE Toolkit 主入口

### pve_config_notes.sh v2.0.0

v2.0.0 將 **PVE 系統初始化／優化與硬體監控安裝整合為單一入口**。

`pve_config_notes.sh` 本身負責：

- 備份並重建 Debian APT 來源
- 使用 TWDS Debian mirror、Debian Security
- 設定 PVE no-subscription repository
- 可選擇啟用 Ceph Squid no-subscription repository
- 移除 PVE／Ceph enterprise source 與重複來源
- 設定時區 `Asia/Taipei`
- 設定 Chrony 校時
- 安裝必要硬體監控工具
- 設定 PVE subscription nag 修補 Hook
- 設定 Datacenter Tag 膠囊樣式與字母排序
- 自動下載並執行 `monitor/disk_monitor.sh v1.0.52`

**注意：v2.0.0 並沒有把兩支 Shell Script 的程式碼硬合併。**

`pve_config_notes.sh` 是 Toolkit 的統一入口；硬體監控核心仍獨立保留在 `monitor/disk_monitor.sh`，避免破壞已完成實機驗證的 v1.0.52。

### 建議安裝方式

在 PVE 主機以 `root` 執行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/pve_config_notes/main/src/pve/pve_config_notes.sh)
```

預設會執行 PVE 初始化／優化，並自動下載及執行最新的 `disk_monitor.sh v1.0.52`。

### 完整系統升級

預設不執行 `apt full-upgrade`。如果希望初始化後一併執行完整系統升級：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/pve_config_notes/main/src/pve/pve_config_notes.sh) -- --upgrade
```

### 啟用 Ceph Squid no-subscription

需要建立 Ceph Squid no-subscription repository 時：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/pve_config_notes/main/src/pve/pve_config_notes.sh) -- --ceph
```

也可以同時執行完整升級：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/pve_config_notes/main/src/pve/pve_config_notes.sh) -- --ceph --upgrade
```

### 重新套用硬體監控 UI

如果硬體監控核心已經安裝，需要重新套用 PVE UI Hook：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/pve_config_notes/main/src/pve/pve_config_notes.sh) -- remod
```

### 還原官方 PVE UI

還原 `disk_monitor.sh` 對 PVE UI 的修改：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/pve_config_notes/main/src/pve/pve_config_notes.sh) -- restore
```

### 本機執行

```bash
chmod +x pve_config_notes.sh
./pve_config_notes.sh
./pve_config_notes.sh --upgrade
./pve_config_notes.sh --ceph
./pve_config_notes.sh --ceph --upgrade
./pve_config_notes.sh remod
./pve_config_notes.sh restore
```

### 內部 NTP

可透過 `INTERNAL_NTP` 指定內部 NTP Server：

```bash
INTERNAL_NTP=192.168.0.100 bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/pve_config_notes/main/src/pve/pve_config_notes.sh)
```

## disk_monitor.sh v1.0.52

正式版包含：

- CPU 狀態、頻率、governor、PkgWatt
- 多 CPU／雙插槽溫度分行
- 網卡溫度自動編號
- NVMe SMART、健康度、溫度、通電與讀寫資訊
- SATA / SAS SSD、HDD 分類
- MegaRAID Physical Disk 自動分流
- SMART 狀態顏色顯示
- Node Summary Auto-Height
- 背景硬體資料採集與 `/run/disk_monitor_runtime/`
- 每分鐘 `/etc/cron.d/disk_monitor`
- PVE 官方檔案版本化備份與 restore
- `install`、`collect`、`restore`、`remod`

### 單獨取得硬體監控核心

如果只需要安裝硬體監控，不需要執行 PVE 初始化／APT 設定，可直接下載：

```bash
curl -fsSL https://raw.githubusercontent.com/sungshu/pve_config_notes/main/src/pve/monitor/disk_monitor.sh -o /root/disk_monitor.sh
chmod +x /root/disk_monitor.sh
/root/disk_monitor.sh
```

### 背景採集

```bash
/root/disk_monitor.sh collect
```

### 重新套用 UI

```bash
/root/disk_monitor.sh remod
```

### 還原官方 UI

```bash
/root/disk_monitor.sh restore
```

套用完成後，請在 PVE Web UI 執行 **Ctrl + F5**。

## PVE 文件

- [系統初始化與優化](src/pve/系統初始化與優化.md)
- [PVE Toolkit 腳本與硬體監控說明](src/pve/README.md)
- [硬體監控客製化](src/pve/monitor/硬體監控客製化.md)

## Ceph 儲存

- [H755 從 RAID 轉 Non-RAID 與 OSD 建置](src/ceph/H755從RAID轉Non-RAID與OSD建置.md)

## PBS 備份

- [PBS 安裝與儲存規劃](src/pbs/PBS安裝與儲存規劃.md)

## VMware 遷移

- [VMware 遷移至 PVE 評估](src/vmware/VMware遷移至PVE評估.md)

## 注意事項

- 所有初始化／優化操作請先確認目前 PVE 節點的 APT 與叢集狀態。
- `--upgrade` 會執行 `apt full-upgrade -y`，正式環境建議於維護時段執行。
- `--ceph` 僅在需要 Ceph Squid no-subscription repository 時使用。
- PVE／PBS 版本更新後，部分 UI 插入點與 API 結構可能改變；正式套用前請在測試節點驗證。

## 作者

**sungshu 手札筆記本**  
GitHub：sungshu.github.io
