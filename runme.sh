#!/bin/bash

### Linux-disk-optimization 2.0 - Advanced Version ###
# Author: Johan Caripson (2025, AI/ChatGPT modernisering)
# https://github.com/Caripson/Linux-disk-optimization
# MIT License

set -e

LOGFILE="/var/log/linux-disk-optimization.log"
SYSCTL_CONF="/etc/sysctl.conf"
BACKUP_SUFFIX=".bak.$(date +%F-%H%M%S)"
DRYRUN=0
LEVEL="safe"
RESTORE=0

print_usage() {
cat <<EOF
Usage: sudo ./runme.sh [options]

Options:
  --level=safe|aggressive|custom   Choose optimization level (default: safe)
  --dry-run                        Only print what would be changed
  --restore                        Restore sysctl.conf and disk params from backup
  --help                           Show this help

Examples:
  sudo ./runme.sh --level=aggressive
  sudo ./runme.sh --dry-run
  sudo ./runme.sh --restore

EOF
}

log() {
    echo "[$(date +'%F %T')] $1" | tee -a "$LOGFILE"
}

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root." >&2
        exit 1
    fi
}

check_dependencies() {
    for dep in awk grep free lsmod; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            echo "Dependency $dep is missing. Please install."
            exit 1
        fi
    done
}

is_virtual_machine() {
    if grep -q 'hypervisor' /proc/cpuinfo || \
       [ -f /sys/class/dmi/id/product_name ] && grep -qi 'virtual' /sys/class/dmi/id/product_name; then
        return 0
    fi
    return 1
}

backup_all() {
    log "Creating backup of $SYSCTL_CONF -> $SYSCTL_CONF$BACKUP_SUFFIX"
    cp "$SYSCTL_CONF" "$SYSCTL_CONF$BACKUP_SUFFIX"
    log "Backup complete."
}

restore_backup() {
    LATEST_BAK=$(ls -1t "$SYSCTL_CONF".bak.* 2>/dev/null | head -n1)
    if [ -z "$LATEST_BAK" ]; then
        echo "No backup file found to restore."
        exit 1
    fi
    log "Restoring backup from $LATEST_BAK"
    cp "$LATEST_BAK" "$SYSCTL_CONF"
    log "Restoration of $SYSCTL_CONF complete."
    echo "You may need to reboot or run sysctl -p to reapply."
    exit 0
}

print_change() {
    [ $DRYRUN -eq 1 ] && echo "[DRY-RUN] $1" || log "$1"
}

run_iozone() {
    if ! command -v iozone >/dev/null 2>&1; then
        log "iozone not found, skipping performance test."
        return
    fi
    log "Running iozone disk benchmark (this may take some time)..."
    iozone -a -g 100M > /tmp/iozone_test_$(date +%s).log 2>&1
    log "Iozone test complete. See /tmp/iozone_test_*.log for results."
}

# ----- PARSE ARGUMENTS -----
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRYRUN=1
            shift
            ;;
        --level=*)
            LEVEL="${arg#*=}"
            shift
            ;;
        --restore)
            RESTORE=1
            shift
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            print_usage
            exit 1
            ;;
    esac
done

require_root
check_dependencies

if [ $RESTORE -eq 1 ]; then
    restore_backup
fi

if [ $DRYRUN -eq 0 ]; then
    mkdir -p "$(dirname "$LOGFILE")"
    touch "$LOGFILE"
fi

# -------- VIRTUAL MACHINE CHECK --------
if is_virtual_machine; then
    log "Virtual machine detected. Disk scheduler tweaks and queue depth settings will be skipped for safety."
    SKIP_DISK=1
else
    SKIP_DISK=0
fi

# -------- BACKUP --------
backup_all

# -------- PERFORMANCE TEST: BEFORE -------
run_iozone

# --------- DYNAMIC VALUES ---------
RAMBYTES=$(free -b | grep "Mem:" | awk '{print ($2)}')
RAMGB=$((RAMBYTES/1024/1024/1024))
SHMMNI=$((256*$RAMGB))
SHMALL=$(((2*$RAMBYTES)/4096))
MSGMNI=$((1024*$RAMGB))

# -------- SYSCTL CONFIGURATION ---------
print_change "Updating $SYSCTL_CONF with optimized kernel/network/vm parameters..."

if [ $DRYRUN -eq 0 ]; then
    cat > "$SYSCTL_CONF" <<EOF
#VALUES SET BY SCRIPT $(date)
# /etc/sysctl.conf - Kernel/system optimization

kernel.shmmni=$SHMMNI
kernel.shmmax=$RAMBYTES
kernel.shmall=$SHMALL
kernel.sem=250 256000 32 $SHMMNI
kernel.msgmni=$MSGMNI
kernel.msgmax=65536
kernel.msgmnb=65536
kernel.randomize_va_space=0
kernel.panic=60
kernel.sysrq=0
kernel.core_uses_pid=1
net.ipv6.conf.all.disable_ipv6=1
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_mem=134217728 134217728 134217728
net.ipv4.tcp_rmem=4096 277750 134217728
net.ipv4.tcp_wmem=4096 277750 134217728
net.core.netdev_max_backlog=3240000
net.core.somaxconn=50000
net.ipv4.tcp_max_tw_buckets=1440000
net.ipv4.tcp_max_syn_backlog=3240000
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_syncookies=1
vm.dirty_background_ratio=10
vm.dirty_background_bytes=0
vm.dirty_ratio=20
vm.dirty_bytes=0
vm.dirty_writeback_centisecs=500
vm.dirty_expire_centisecs=3000
vm.swappiness=0
vm.overcommit_memory=0
vm.vfs_cache_pressure=500
fs.file-max=2097152
fs.inotify.max_user_watches=65536
fs.mqueue.msg_max=16384
fs.mqueue.queues_max=4096
EOF
fi

# -------- DISK SCHEDULER & PARAMETERS --------
policy="noop"
read_ahead=16384
queue_depth=1024
iscsi_timeout=180

case "$LEVEL" in
    safe)
        policy="noop"
        read_ahead=16384
        queue_depth=1024
        ;;
    aggressive)
        policy="deadline"
        read_ahead=65536
        queue_depth=4096
        ;;
    custom)
        echo "Custom mode. Please edit script for manual tuning."
        ;;
    *)
        echo "Unknown optimization level: $LEVEL"
        exit 1
        ;;
esac

if [ $SKIP_DISK -eq 0 ]; then
    for disk in $(cd /sys/block; ls -d sd* 2>/dev/null); do
        print_change "Setting $disk: scheduler=$policy, read_ahead=$read_ahead, queue_depth=$queue_depth, iscsi_timeout=$iscsi_timeout"
        if [ $DRYRUN -eq 0 ]; then
            echo "$policy" > /sys/block/$disk/queue/scheduler 2>/dev/null || true
            echo "$read_ahead" > /sys/block/$disk/queue/read_ahead_kb 2>/dev/null || true
            echo "$queue_depth" > /sys/block/$disk/queue/nr_requests 2>/dev/null || true
            echo "$iscsi_timeout" > /sys/block/$disk/device/timeout 2>/dev/null || true
        fi
    done
else
    print_change "Skipping disk optimization due to VM detection."
fi

# ------- SYSCTL RELOAD ---------
print_change "Reloading sysctl parameters..."
[ $DRYRUN -eq 0 ] && sysctl -p || true

# ------- LOGGING COMPLETION -------
log "Optimization complete. Level: $LEVEL. Dry-run: $DRYRUN. VM Detected: $SKIP_DISK"
log "All actions have been logged to $LOGFILE."

# -------- PERFORMANCE TEST: AFTER ---------
run_iozone

echo "All done. Please review $LOGFILE for details. A system reboot may be recommended for some changes to take full effect."
