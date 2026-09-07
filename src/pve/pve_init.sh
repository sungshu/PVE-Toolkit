#!/usr/bin/env bash
# PVE Toolkit - Proxmox VE 9（Debian 13 Trixie）台灣環境主機初始化、優化與硬體監控入口
# Version: 2.1.7
# Updated: 2026-09-07
set -Eeuo pipefail

SCRIPT_VERSION="2.1.7"
readonly DEBIAN_MIRROR="https://mirror.twds.com.tw/debian"
readonly DEBIAN_SECURITY="https://security.debian.org/debian-security"
readonly PVE_REPOSITORY="http://download.proxmox.com/debian/pve"
readonly CEPH_REPOSITORY="http://download.proxmox.com/debian/ceph-squid"
readonly REPOSITORY_RAW="https://raw.githubusercontent.com/sungshu/PVE-Toolkit/main/src/pve"
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
  ./pve_init.sh [--upgrade] [--ceph]
  ./pve_init.sh restore
  ./pve_init.sh remod

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

disk_script="/root/disk_monitor.sh"
if [[ "$ACTION" != "install" ]]; then
    [[ -x "$disk_script" ]] || { echo "找不到可執行的 ${disk_script}。" >&2; exit 1; }
    exec "$disk_script" "$ACTION"
fi

backup_dir="/root/apt-sources-backup-$(date +%F-%H%M%S)"
mkdir -p "$backup_dir"
[[ -f /etc/apt/sources.list ]] && cp -a /etc/apt/sources.list "$backup_dir/"
[[ -d /etc/apt/sources.list.d ]] && cp -a /etc/apt/sources.list.d "$backup_dir/"
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

timedatectl set-timezone Asia/Taipei
ntp_lines=$'pool tick.stdtime.gov.tw iburst\npool tock.stdtime.gov.tw iburst\npool tw.pool.ntp.org iburst'
[[ -n "$INTERNAL_NTP" ]] && ntp_lines="server ${INTERNAL_NTP} iburst
${ntp_lines}"
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
systemctl enable --now chrony

cat > /etc/apt/apt.conf.d/no-nag-script <<'EOF'
DPkg::Post-Invoke { "dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\\.js$'; if [ $? -eq 1 ]; then { echo 'Patching subscription nag...'; sed -i '/.*data\\.status.*active/{s/!//;s/active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; }; fi"; };
EOF

apt update
apt install -y chrony lm-sensors smartmontools linux-cpupower nvme-cli hdparm curl wget util-linux jq
apt --reinstall install -y proxmox-widget-toolkit
[[ "$DO_UPGRADE" -eq 1 ]] && apt full-upgrade -y

if [[ -f /etc/pve/datacenter.cfg ]]; then
    if grep -q '^tag-style' /etc/pve/datacenter.cfg; then
        sed -i 's/^tag-style:.*/tag-style: shape=full,ordering=alphabetical/' /etc/pve/datacenter.cfg
    else
        echo 'tag-style: shape=full,ordering=alphabetical' >> /etc/pve/datacenter.cfg
    fi
fi

rm -f "$disk_script"
monitor_tmp="${disk_script}.tmp.$$"
monitor_url="${MONITOR_RAW}?v=$(date +%s)"
curl -fsSL "$monitor_url" -o "$monitor_tmp"
chmod 0755 "$monitor_tmp"
grep -q '^VERSION="1\.0\.52"' "$monitor_tmp" || { rm -f "$monitor_tmp"; echo "disk_monitor.sh 版本驗證失敗" >&2; exit 1; }
mv -f "$monitor_tmp" "$disk_script"
chmod 0755 "$disk_script"

"$disk_script"
EOF
