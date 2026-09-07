#!/usr/bin/env bash
# pve_config_notes.sh
# PVE Toolkit - Proxmox VE 9（Debian 13 Trixie）台灣環境主機優化與硬體監控安裝腳本
#
# v2.0：PVE Toolkit 統一 PVE 初始化／優化與硬體監控的單一入口。
# - 系統初始化與優化仍由本腳本處理。
# - 硬體監控核心維持 monitor/disk_monitor.sh v1.0.52。
# - 本腳本負責下載、安裝及轉呼叫硬體監控功能。
# - 不改動 disk_monitor.sh v1.0.52 已驗證的監控核心。
#
# 預設行為：
# - 備份並統一 APT 來源為 TWDS Debian mirror、Debian Security、PVE no-subscription。
# - 移除 PVE / Ceph enterprise source，避免 401 Unauthorized。
# - 移除傳統 sources.list 與 debian.sources 重複來源。
# - 安裝必要監控工具，不執行完整系統升級。
# - 自動下載並執行同倉庫 monitor/disk_monitor.sh。
#
# 用法：
#   ./pve_config_notes.sh
#   ./pve_config_notes.sh --upgrade
#   ./pve_config_notes.sh --ceph
#   ./pve_config_notes.sh --ceph --upgrade
#   ./pve_config_notes.sh restore
#   ./pve_config_notes.sh remod
#
# 選用內部 NTP：
#   INTERNAL_NTP=192.168.0.100 ./pve_config_notes.sh
set -Eeuo pipefail
SCRIPT_VERSION="2.0.0"
readonly DEBIAN_MIRROR="https://mirror.twds.com.tw/debian"
readonly DEBIAN_SECURITY="https://security.debian.org/debian-security"
readonly PVE_REPOSITORY="http://download.proxmox.com/debian/pve"
readonly CEPH_REPOSITORY="http://download.proxmox.com/debian/ceph-squid"
readonly REPOSITORY_RAW="https://raw.githubusercontent.com/sungshu/pve_config_notes/main/src/pve"
readonly MONITOR_RAW="${REPOSITORY_RAW}/monitor/disk_monitor.sh"
readonly SUITE="trixie"

INTERNAL_NTP="${INTERNAL_NTP:-}"
DO_UPGRADE=0
ENABLE_CEPH=0
ACTION="install"

usage() {
    cat <<'EOF'
PVE Toolkit - Proxmox VE Infrastructure Toolkit

用法：
  ./pve_config_notes.sh [--upgrade] [--ceph]
  ./pve_config_notes.sh restore
  ./pve_config_notes.sh remod

選項：
  --upgrade  安裝必要套件後執行 apt full-upgrade
  --ceph     啟用 Ceph Squid no-subscription repository
  restore    還原硬體監控介面修改
  remod      強制重新套用硬體監控介面
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --upgrade) DO_UPGRADE=1 ;;
        --ceph) ENABLE_CEPH=1 ;;
        restore|remod) ACTION="$1" ;;
        -h|--help) usage; exit 0 ;;
        *) echo "未知參數：$1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

if [[ ${EUID} -ne 0 ]]; then
    echo "請以 root 執行。" >&2
    exit 1
fi

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [[ "$script_dir" == /dev/fd* ]]; then
    disk_script="/root/disk_monitor.sh"
else
    disk_script="${script_dir}/monitor/disk_monitor.sh"
fi
backup_dir="/root/apt-sources-backup-$(date +%F-%H%M%S)"