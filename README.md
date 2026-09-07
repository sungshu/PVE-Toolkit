# PVE Toolkit

**Proxmox VE Infrastructure Toolkit**

把實際部署與維運 Proxmox VE 會反覆使用的工具、硬體監控與相關實戰文件，整理成一套可以直接使用、容易理解、可以長期維護的 Toolkit。

## 🎯 專案定位

這不是單純的「PVE 筆記」。

它的核心目標是：

> **從 PVE 主機初始化開始，到系統優化與硬體監控，把實際維運會反覆使用的工具整理成有明確入口與分類的工具箱。**

其他 PVE 功能與實戰內容則依用途獨立整理，不塞進主安裝流程。

### 專案架構

```text
                         PVE Toolkit
                              │
              ┌───────────────┴───────────────┐
              │                               │
           工具層                         技術文件層
              │                               │
      pve_config_notes.sh          ┌──────────┼──────────┐
              │                    │          │          │
              ▼                  monitor     ceph       pbs
       disk_monitor.sh             │          │          │
              │                    │          │          │
              ▼                    └──────────┴──────────┘
       PVE Node Summary                     │
                                           ▼
                                      VMware → PVE
```

## 📦 目前版本

| 元件 | 版本 | 用途 |
|---|---:|---|
| PVE Toolkit | 2.1.7 | 主入口與整合架構 |
| `pve_config_notes.sh` | 2.1.7 | PVE 初始化／優化／監控部署 |
| `disk_monitor.sh` | 1.0.52 | Node Summary 硬體監控 |

目標環境：**Proxmox VE 9.x / Debian 13 Trixie**。

## 📁 Repository 結構

```text
PVE-Toolkit/
├── README.md                         # 專案入口與使用說明
│
├── src/
│   ├── pve/
│   │   ├── README.md                 # PVE 模組入口
│   │   ├── pve_config_notes.sh       # PVE 初始化／優化單一入口
│   │   ├── 系統初始化與優化.md
│   │   │
│   │   ├── monitor/
│   │   │   ├── disk_monitor.sh      # 硬體監控核心
│   │   │   └── 硬體監控客製化.md
│   │   │
│   │   ├── ceph/
│   │   │   └── H755從RAID轉Non-RAID與OSD建置.md
│   │   │
│   │   └── pbs/
│   │       └── PBS安裝與儲存規劃.md
│   │
│   └── vmware/
│       └── VMware遷移至PVE評估.md
│
└── img/
    ├── pve/
    │   ├── ceph/                     # Ceph 實機畫面
    │   ├── pbs/                      # PBS 實機畫面
    │   └── monitor/                  # 硬體監控實機畫面
    └── vmware/                       # VMware 遷移畫面
```

### 整理規則

- `src/`：工具與技術文件。
- `img/`：實機圖片。
- `src/pve/`：所有 PVE 相關內容。
- `monitor / ceph / pbs`：依用途分類的 PVE 功能文件。
- `src/vmware/`：VMware → PVE 遷移來源平台相關內容。
- 不建立 `src/ceph`、`src/pbs` 等重複頂層目錄。
- 同一份技術內容只保留一份。

## 🚀 快速開始

### 1. PVE 主機初始化

預設執行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh)
```

這是本 Toolkit 的**主要入口**，會：

- 備份現有 APT 設定
- 建立 Debian 13 Trixie APT 來源
- 使用 TWDS Debian mirror + Debian Security
- 使用 PVE `pve-no-subscription`
- 清除 PVE enterprise source 與重複來源
- 設定 `Asia/Taipei`
- 設定 Chrony
- 安裝硬體監控所需工具
- 設定 PVE subscription nag Hook
- 設定 Datacenter Tag
- 自動部署 `disk_monitor.sh`

### 2. 完整系統升級

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) --upgrade
```

### 3. 重新套用硬體監控

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) remod
```

### 4. 還原官方 UI

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve/pve_config_notes.sh) restore
```

## 📸 實際安裝畫面

以下為 **PVE Toolkit 2.1.7** 實際在 PVE 9.x 主機執行初始化腳本時的操作畫面，保留完整的階段進度、設定結果與成功／警告／失敗統計。

![PVE Toolkit 安裝畫面 01](img/pve/2026-09-07%20144912.png)

![PVE Toolkit 安裝畫面 02](img/pve/2026-09-07%20145031.png)

![PVE Toolkit 安裝畫面 03](img/pve/2026-09-07%20145048.png)

![PVE Toolkit 安裝畫面 04](img/pve/2026-09-07%20145110.png)

## 🖥️ 硬體監控

`disk_monitor.sh v1.0.52` 是目前正式硬體監控核心。

它把以下資訊整合到 PVE Node Summary：

- CPU 頻率與 governor
- CPU Package Watt
- CPU／多插槽溫度
- 網卡溫度
- NVMe SMART
- SATA / SAS SSD / HDD
- MegaRAID Physical Disk
- RAID Map
- SMART `OK / FAIL / UNKNOWN`

資料採集與 Web request 分離，以 runtime JSON 提供 Node Summary 使用。

完整說明：

- [硬體監控客製化](src/pve/monitor/硬體監控客製化.md)

## 💾 PVE 實戰文件

PVE 本身已有完整的儲存、Ceph、PBS 等功能；Toolkit 這裡只保留實際部署時累積的實戰文件，不把這些內容塞進一般主機初始化流程。

- [H755 從 RAID 轉 Non-RAID 與 OSD 建置](src/pve/ceph/H755從RAID轉Non-RAID與OSD建置.md)
- [PBS 安裝與儲存規劃](src/pve/pbs/PBS安裝與儲存規劃.md)

## 🔄 VMware → PVE

VMware 遷移不是 PVE 主機初始化的一部分，因此獨立分類：

- [VMware 遷移至 PVE 評估](src/vmware/VMware遷移至PVE評估.md)

## 📚 文件入口

- [PVE Toolkit 模組說明](src/pve/README.md)
- [PVE 系統初始化與優化](src/pve/系統初始化與優化.md)
- [PVE 硬體監控客製化](src/pve/monitor/硬體監控客製化.md)
- [Ceph / H755 / OSD](src/pve/ceph/H755從RAID轉Non-RAID與OSD建置.md)
- [PBS / 備份與儲存](src/pve/pbs/PBS安裝與儲存規劃.md)
- [VMware → PVE](src/vmware/VMware遷移至PVE評估.md)

## ⚠️ 生產環境注意

這個 Toolkit 包含會直接修改 PVE 主機的腳本，也包含可能清除資料的儲存操作文件。

執行前請確認：

1. PVE 節點是否為測試或生產環境。
2. APT / Cluster / Storage / Network 現況。
3. RAID → Non-RAID、Ceph OSD、ZFS 等操作是否已有可靠備份。
4. PVE 升級後是否需要重新套用 UI Hook。
5. 所有修改是否先在非生產節點驗證。

## 作者

**sungshu 手札筆記本**

GitHub：[sungshu.github.io](https://sungshu.github.io/)
