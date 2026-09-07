#!/usr/bin/env bash
# PVE Toolkit - Proxmox VE 9（Debian 13 Trixie）台灣環境主機初始化、優化與硬體監控入口
# Version: 2.1.3
# Updated: 2026-09-07
set -Eeuo pipefail

SCRIPT_VERSION="2.1.3"
readonly DEBIAN_MIRROR="https://mirror.twds.com.tw/debian"
readonly DEBIAN_SECURITY="https://security.debian.org/debian-security"
readonly PVE_REPOSITORY="http://download.proxmox.com/debian/pve"
readonly CEPH_REPOSITORY="http://download.proxmox.com/debian/ceph-squid"
readonly REPOSITORY_RAW="https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve"
readonly MONITOR_RAW="${REPOSITORY_RAW}/monitor/disk_monitor.sh?v=$(date +%s)"
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

if [[ "$ACTION" != "install" ]]; then
    if [[ ! -x "$disk_script" ]]; then
        echo "找不到可執行的 ${disk_script}。" >&2
        echo "若是首次安裝，請先執行不帶 restore/remod 的主腳本。" >&2
        exit 1
    fi
    exec "$disk_script" "$ACTION"
fi

backup_dir="/root/apt-sources-backup-$(date +%F-%H%M%S)"

echo "=== [1/6] 備份並重建 APT 來源 ==="
mkdir -p "$backup_dir"
[[ -f /etc/apt/sources.list ]] && cp -a /etc/apt/sources.list "$backup_dir/"
[[ -d /etc/apt/sources.list.d ]] && cp -a /etc/apt/sources.list.d "$backup_dir/"
echo "APT 設定備份：${backup_dir}"

rm -f /etc/apt/sources.list
for f in debian.sources pve-enterprise.list pve-enterprise.sources pve-install-repo.list pve-install-repo.sources pve-no-subscription.list pve-no-subscription.sources ceph.list ceph.sources ceph-enterprise.list ceph-enterprise.sources ceph-no-subscription.list ceph-no-subscription.sources; do
    rm -f "/etc/apt/sources.list.d/${f}"
done

cat > /etc/apt/sources.list.d/debian.sources <<EOF
Types: deb deb-src
URIs: ${DEBIAN_MIRROR}
Suites: ${SUITE} ${SUITE}-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: ${DEBIAN_SECURITY}
Suites: ${SUITE}-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

cat > /etc/apt/sources.list.d/pve-no-subscription.sources <<EOF
Types: deb
URIs: ${PVE_REPOSITORY}
Suites: ${SUITE}
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

if [[ "$ENABLE_CEPH" -eq 1 ]]; then
    cat > /etc/apt/sources.list.d/ceph-no-subscription.sources <<EOF
Types: deb
URIs: ${CEPH_REPOSITORY}
Suites: ${SUITE}
Components: no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
fi

echo "=== [2/6] 設定 Asia/Taipei 與 Chrony ==="
timedatectl set-timezone Asia/Taipei
ntp_lines=$'pool tick.stdtime.gov.tw iburst\npool tock.stdtime.gov.tw iburst\npool tw.pool.ntp.org iburst'
if [[ -n "$INTERNAL_NTP" ]]; then
    ntp_lines="server ${INTERNAL_NTP} iburst
${ntp_lines}"
fi
install -d -m 0755 /etc/chrony
cat > /etc/chrony/chrony.conf <<EOF
${ntp_lines}
keyfile /etc/chrony/chrony.keys
driftfile /var/lib/chrony/chrony.drift
logdir /var/log/chrony
maxupdateskew 100.0
rtcsync
makestep 1 3
EOF

echo "=== [3/6] 設定 PVE UI subscription nag Hook ==="
cat > /etc/apt/apt.conf.d/no-nag-script <<'EOF'
DPkg::Post-Invoke { "dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\\.js$'; if [ $? -eq 1 ]; then { echo 'Patching subscription nag...'; sed -i '/.*data\\.status.*active/{s/!//;s/active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; }; fi"; };
EOF

echo "=== [4/6] 安裝必要套件 ==="
apt update
apt install -y chrony lm-sensors smartmontools linux-cpupower nvme-cli hdparm curl wget util-linux jq
apt --reinstall install -y proxmox-widget-toolkit
if [[ "$DO_UPGRADE" -eq 1 ]]; then
    apt full-upgrade -y
fi
systemctl enable --now chrony

echo "=== [5/6] 設定 Datacenter Tag 樣式 ==="
if [[ -f /etc/pve/datacenter.cfg ]]; then
    if grep -q '^tag-style' /etc/pve/datacenter.cfg; then
        sed -i 's/^tag-style:.*/tag-style: shape=full,ordering=alphabetical/' /etc/pve/datacenter.cfg
    else
        echo 'tag-style: shape=full,ordering=alphabetical' >> /etc/pve/datacenter.cfg
    fi
fi

echo "=== [6/6] 安裝／啟動 PVE 硬體監控 ==="

# 先移除舊版，避免舊檔案在下載失敗或版本驗證失敗時繼續被使用。
# 新檔案一律先下載到暫存檔，確認版本正確後才正式部署。
rm -f "$disk_script"
monitor_tmp="${disk_script}.tmp.$$"
rm -f "$monitor_tmp"

if ! curl -fsSL "$MONITOR_RAW" -o "$monitor_tmp"; then
    rm -f "$monitor_tmp"
    echo "無法下載最新 disk_monitor.sh：$MONITOR_RAW" >&2
    exit 1
fi

chmod 0755 "$monitor_tmp"
if ! grep -q '^VERSION="1\.0\.52"' "$monitor_tmp"; then
    echo "下載到的 disk_monitor.sh 版本不符合預期，已停止安裝。" >&2
    echo "預期版本：1.0.52" >&2
    grep -m1 '^VERSION=' "$monitor_tmp" >&2 || true
    rm -f "$monitor_tmp"
    exit 1
fi

mv -f "$monitor_tmp" "$disk_script"
chmod 0755 "$disk_script"

grep -m1 '^VERSION=' "$disk_script"
"$disk_script"

echo
echo "========================================================="
echo "PVE Toolkit v${SCRIPT_VERSION} 初始化完成"
echo "========================================================="
echo "PVE APT：pve-no-subscription"
echo "Debian APT：TWDS + Debian Security"
echo "時區：Asia/Taipei"
echo "時間同步：Chrony"
echo "硬體監控：disk_monitor.sh v1.0.52"
echo "完整升級：$([[ "$DO_UPGRADE" -eq 1 ]] && echo 已執行 || echo 未執行)"
echo "Ceph source：$([[ "$ENABLE_CEPH" -eq 1 ]] && echo 已啟用 || echo 未啟用)"
echo "APT 備份：${backup_dir}"
echo "========================================================="