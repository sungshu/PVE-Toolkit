#!/usr/bin/env bash
# PVE Toolkit - Proxmox VE 9（Debian 13 Trixie）台灣環境主機初始化、優化與硬體監控入口
# Version: 2.1.5
# Updated: 2026-09-07
set -Eeuo pipefail

SCRIPT_VERSION="2.1.5"
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

# 固定寬度輸出，避免終端機只看到大量白字而難以辨識重點。
print_header() {
    echo
    echo "========================================================="
    echo " PVE Toolkit v${SCRIPT_VERSION}"
    echo "========================================================="
}

print_section() {
    echo
    echo "---------------------------------------------------------"
    echo " $1"
    echo "---------------------------------------------------------"
}

print_item() {
    printf '  %-20s : %s\n' "$1" "$2"
}

print_header

print_section "[1/6] APT 來源設定"
mkdir -p "$backup_dir"
[[ -f /etc/apt/sources.list ]] && cp -a /etc/apt/sources.list "$backup_dir/"
[[ -d /etc/apt/sources.list.d ]] && cp -a /etc/apt/sources.list.d "$backup_dir/"
print_item "Debian Mirror" "$DEBIAN_MIRROR"
print_item "Debian Suite" "${SUITE} / ${SUITE}-updates"
print_item "Security" "$DEBIAN_SECURITY"
print_item "PVE Repository" "$PVE_REPOSITORY"
print_item "PVE Channel" "pve-no-subscription"
print_item "Ceph Source" "$([[ "$ENABLE_CEPH" -eq 1 ]] && echo 已啟用 || echo 未啟用)"
print_item "APT 備份" "$backup_dir"

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

print_section "[2/6] 時區與 Chrony"
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
systemctl enable --now chrony
print_item "Timezone" "$(timedatectl show --property=Timezone --value)"
print_item "Chrony" "$(systemctl is-active chrony) / $(systemctl is-enabled chrony)"
print_item "NTP" "tick.stdtime.gov.tw, tock.stdtime.gov.tw, tw.pool.ntp.org"
[[ -n "$INTERNAL_NTP" ]] && print_item "Internal NTP" "$INTERNAL_NTP"

print_section "[3/6] PVE UI Subscription Nag Hook"
cat > /etc/apt/apt.conf.d/no-nag-script <<'EOF'
DPkg::Post-Invoke { "dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\\.js$'; if [ $? -eq 1 ]; then { echo 'Patching subscription nag...'; sed -i '/.*data\\.status.*active/{s/!//;s/active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; }; fi"; };
EOF
apt update
apt install -y chrony lm-sensors smartmontools linux-cpupower nvme-cli hdparm curl wget util-linux jq
apt --reinstall install -y proxmox-widget-toolkit
[[ "$DO_UPGRADE" -eq 1 ]] && apt full-upgrade -y
print_item "Hook" "/etc/apt/apt.conf.d/no-nag-script"
print_item "Status" "$(test -f /etc/apt/apt.conf.d/no-nag-script && echo 已設定 || echo 失敗)"

print_section "[4/6] 必要套件"
for pkg in chrony lm-sensors smartmontools linux-cpupower nvme-cli hdparm curl wget util-linux jq proxmox-widget-toolkit; do
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed'; then
        ver="$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null)"
        print_item "$pkg" "OK (${ver})"
    else
        print_item "$pkg" "未安裝"
    fi
done

print_section "[5/6] Datacenter Tag"
if [[ -f /etc/pve/datacenter.cfg ]]; then
    if grep -q '^tag-style' /etc/pve/datacenter.cfg; then
        sed -i 's/^tag-style:.*/tag-style: shape=full,ordering=alphabetical/' /etc/pve/datacenter.cfg
    else
        echo 'tag-style: shape=full,ordering=alphabetical' >> /etc/pve/datacenter.cfg
    fi
    tag_style="$(awk -F': ' '$1=="tag-style"{$1=""; sub(/^: /,""); print}' /etc/pve/datacenter.cfg | tail -1)"
    print_item "tag-style" "${tag_style:-shape=full,ordering=alphabetical}"
else
    print_item "tag-style" "找不到 /etc/pve/datacenter.cfg"
fi

print_section "[6/6] 硬體監控安裝"
rm -f "$disk_script"
monitor_tmp="${disk_script}.tmp.$$"
monitor_url="${MONITOR_RAW}?v=$(date +%s)"

if ! curl -fsSL "$monitor_url" -o "$monitor_tmp"; then
    rm -f "$monitor_tmp"
    echo "  ERROR                 : 無法下載 disk_monitor.sh" >&2
    exit 1
fi
chmod 0755 "$monitor_tmp"

if ! grep -q '^VERSION="1\.0\.52"' "$monitor_tmp"; then
    echo "  ERROR                 : 下載版本不符合預期" >&2
    echo "  實際版本              : $(grep -m1 '^VERSION=' "$monitor_tmp" || echo '未知')" >&2
    rm -f "$monitor_tmp"
    exit 1
fi

mv -f "$monitor_tmp" "$disk_script"
chmod 0755 "$disk_script"
installed_version="$(grep -m1 '^VERSION=' "$disk_script")"
print_item "Script" "$disk_script"
print_item "Version" "$installed_version"
print_item "Status" "已安裝"
print_item "Execute" "尚未執行"

echo
echo "========================================================="
echo " 安裝完成，以上為本次實際設定"
echo "========================================================="
echo
read -r -p "是否立即執行硬體監控？[Y/n] " RUN_MONITOR
RUN_MONITOR="${RUN_MONITOR:-Y}"

if [[ "$RUN_MONITOR" =~ ^[Yy]$ ]]; then
    echo
    echo "=== 啟動 disk_monitor.sh ${installed_version#VERSION=\"} ==="
    "$disk_script"
else
    echo
    echo "已安裝 disk_monitor.sh，暫不執行。"
fi

echo
echo "========================================================="
echo " PVE Toolkit v${SCRIPT_VERSION} 初始化完成"
echo "========================================================="
echo " APT：pve-no-subscription"
echo " Timezone：Asia/Taipei"
echo " Chrony：$(systemctl is-active chrony)"
echo " Datacenter Tag：shape=full,ordering=alphabetical"
echo " Hardware Monitor：${installed_version}"
echo " Upgrade：$([[ "$DO_UPGRADE" -eq 1 ]] && echo 已執行 || echo 未執行)"
echo " Ceph Source：$([[ "$ENABLE_CEPH" -eq 1 ]] && echo 已啟用 || echo 未啟用)"
echo "========================================================="
