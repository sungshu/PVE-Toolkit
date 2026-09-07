# PBS 安裝與儲存規劃

記錄將退役或轉役的企業級伺服器改裝為專用 Proxmox Backup Server（PBS）備份主機的規劃與注意事項。

## 為什麼 PBS 全用 SSD 可能是「浪費」

PBS 的底層是內容定址儲存（CAS），備份資料會拆成大量 Chunk 檔案，因此垃圾回收（GC）、Verify 與隨機讀取都會產生大量 metadata / filesystem I/O。

如果只考慮長期封存每 TB 成本，全用企業級 SSD 單價確實較高；但若需要較短備份窗口、較快 GC / Verify 或 Live-Restore，SSD 帶來的維運優勢會很明顯。

## 折衷方案：ZFS Special VDEV

可以使用少量 SSD 承擔 metadata 與小檔案，再以 HDD 提供主要容量：

```text
PBS 本機 ZFS Pool
 ├── [SSD] ──> Special VDEV：metadata / 小檔案
 └── [HDD] ──> 大容量備份資料
```

**重要限制：**

- special device 的容錯層級必須和主 pool 一致，必須依需求建立 mirror，不能把單顆 SSD 當成唯一 special device。
- special device 一旦加入 pool，規劃上應視為不可逆的架構決策；正式環境建議先完整測試與備份。
- 加入 special device 不會自動讓既有所有資料立即受益，既有資料的 metadata / data placement 需依 ZFS 行為與後續重寫情況評估。

## 硬體選型方向

| 類型 | 建議 | 原因 |
|---|---|---|
| 企業級伺服器 | 優先使用 ECC RAM、雙電源與可管理 BMC | 適合長時間備份與維運 |
| 開機碟 | 2 顆 SSD 做 RAID 1 | OS 與 PBS 本身保持可用性 |
| 備份資料碟 | HDD / SSD 依 RPO、RTO 與容量成本決定 | 備份容量通常比極致 IOPS 更重要 |
| 記憶體 | 依 datastore 規模與 GC / Verify 負載評估 | metadata cache 可降低磁碟 I/O |

## 磁碟陣列卡設定

不要在 RAID 卡內切多個單碟 RAID 0 再交給 ZFS。資料碟應優先使用 HBA / JBOD / Non-RAID 模式，讓 Linux 與 ZFS 直接辨識實體磁碟。

若原本是 RAID 5/6，需先確認資料備份，再刪除虛擬磁碟並轉為 Non-RAID。Dell PERC H755 的操作可參考本 Toolkit 的：

**[H755 從 RAID 轉 Non-RAID 與 OSD 建置](../ceph/H755從RAID轉Non-RAID與OSD建置.md)**

## PBS Datastore 與遠端儲存

PBS Datastore 優先建議使用 PBS 主機本地儲存。若使用 NFS / SMB 或其他網路儲存，應先針對 metadata 延遲、鎖定、一致性、GC 與 Verify 實際測試，不要只用順序讀寫速度判斷。

較穩妥的架構是：

```text
PVE 叢集
   │
   ▼
PBS-01 本地 Datastore
   │
   │ PBS Sync Job
   ▼
PBS-02 異地／第二份備份
```

以第二台 PBS 保存較長歷史，可同時改善災難復原與勒索軟體風險隔離。

## 規劃重點

1. PVE VM 備份先落到主要 PBS。
2. 依 RPO / RTO 決定保留天數與 datastore 容量。
3. 以 PBS 原生 Sync Job 建立第二份備份。
4. 異地 PBS 優先使用 Pull 模式與適當權限隔離。
5. 定期驗證 GC、Verify、Prune、Restore 與 Live-Restore，而不是只確認備份任務顯示成功。

## 注意事項

- 更換 RAID / HBA 模式可能清除既有資料，執行前務必確認備份。
- ZFS 特殊裝置與儲存池架構屬於長期設計決策，正式環境不要邊做邊改。
- PBS 的真正容量需求應以實際 VM 資料量、變更率、保留政策與 deduplication 結果估算。
