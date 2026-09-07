# PVE Toolkit

**Proxmox VE Infrastructure Toolkit**

把實際部署與維運 Proxmox VE 時會使用到的初始化工具、硬體監控與實戰文件集中整理，讓 PVE 主機可以快速完成基本環境設定，並提供硬體狀態監控。

> 目前版本：**PVE Toolkit 2.1.7**  
> 適用環境：**Proxmox VE 9.x / Debian 13 Trixie**

## 🚀 快速開始

### PVE 主機初始化

在 PVE 主機以 `root` 執行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh)
```

這是 Toolkit 的主要入口。執行後會依序完成：

1. **APT 來源設定**
   - 先備份目前 APT 設定
   - 建立 Debian 13 Trixie repository
   - 設定 PVE `pve-no-subscription` repository
   - 清理舊的 enterprise / 重複來源
2. **時區與時間同步**
   - 設定時區為 `Asia/Taipei`
   - 設定並啟用 Chrony
3. **PVE Subscription Nag Hook**
   - 建立自動處理 PVE Subscription Nag 的設定
4. **必要套件**
   - 安裝硬體監控與系統管理所需工具
5. **Datacenter Tag**
   - 設定 PVE Tag 顯示為完整膠囊樣式並依字母排序
6. **硬體監控**
   - 自動下載並部署 `disk_monitor.sh v1.0.52`

執行完成後，畫面會顯示成功、失敗與警告項目。

## 🔧 常用操作

### 初始化 + 完整系統升級

預設初始化**不會執行** `apt full-upgrade`。

如果希望同時進行完整系統升級：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) --upgrade
```

### 重新套用硬體監控 UI

已經安裝硬體監控，但需要重新套用 UI 修改時：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) remod
```

### 還原硬體監控 UI 修改

如果需要移除硬體監控對 PVE 官方 UI 檔案的修改：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) restore
```

> `restore` 是還原 **硬體監控 UI 修改**，不是將整台 PVE 主機完整還原到執行 Toolkit 之前的狀態。

### 啟用 Ceph repository

只有在需要 Ceph Squid no-subscription repository 時使用：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) --ceph
```

也可以搭配完整升級：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) --ceph --upgrade
```

### 內部 NTP Server

如果環境有內部 NTP Server，可以透過 `INTERNAL_NTP` 指定：

```bash
INTERNAL_NTP=192.168.0.100 bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh)
```

## 🖥️ 硬體監控

`disk_monitor.sh v1.0.52` 是 Toolkit 的硬體監控核心，會將硬體資訊整合到 PVE Node Summary。

目前支援：

- CPU 頻率、governor、PkgWatt
- CPU 與多 CPU 插槽溫度
- 網卡溫度
- NVMe SMART 與健康資訊
- SATA / SAS SSD / HDD
- MegaRAID Physical Disk
- RAID Map
- SMART `OK / FAIL / UNKNOWN`
- 背景硬體資料採集
- PVE 官方檔案版本化備份與還原

硬體監控程式正式安裝位置：

```text
/root/disk_monitor.sh
```

**svg**

背景資料會使用 runtime JSON 提供 PVE Web UI 使用。

👉 [查看完整的硬體監控安裝流程與實機畫面](src/pve/monitor/硬體監控客製化.md)

### 單獨安裝硬體監控

如果只需要硬體監控，不需要執行 PVE 初始化：

```bash
curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/monitor/disk_monitor.sh -o /root/disk_monitor.sh
chmod +x /root/disk_monitor.sh
/root/disk_monitor.sh
```

背景採集：

```bash
/root/disk_monitor.sh collect
```

重新套用 UI：

```bash
/root/disk_monitor.sh remod
```

還原 UI 修改：

```bash
/root/disk_monitor.sh restore
```

套用 UI 修改後，請在 PVE Web UI 執行 **Ctrl + F5**。

## 📸 實際安裝畫面

以下為 **PVE Toolkit 2.1.7** 實際在 PVE 9.x 主機執行初始化腳本時的操作畫面。

![PVE Toolkit 安裝畫面 01](img/pve/2026-09-07%20144912.png)

![PVE Toolkit 安裝畫面 02](img/pve/2026-09-07%20145031.png)

![PVE Toolkit 安裝畫面 03](img/pve/2026-09-07%20145048.png)

![PVE Toolkit 安裝畫面 04](img/pve/2026-09-07%20145110.png)

## 📚 文件

### PVE

- [PVE Toolkit 腳本與硬體監控說明](src/pve/README.md)
- [PVE 系統初始化與優化](src/pve/系統初始化與優化.md)
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
│   │   ├── README.md
│   │   ├── pve_config_notes.sh
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

PVE Toolkit 的初始化腳本會直接修改 PVE 主機設定，執行前請確認目前節點的環境與維運需求。

尤其是：

- APT repository 設定
- PVE Cluster 狀態
- Storage 與 Network 設定
- 是否需要執行 `--upgrade`
- 是否需要啟用 Ceph repository

另外，Ceph OSD、RAID → Non-RAID 等儲存操作屬於獨立的實戰文件，執行前務必確認資料與備份狀態。

## 作者

**sungshu 手札筆記本**

GitHub：[sungshu.github.io](https://sungshu.github.io/)
