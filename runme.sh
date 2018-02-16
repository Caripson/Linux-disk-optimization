#!/bin/sh

### BEGIN INIT INFO
# Provides:          scriptname
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Enable service provided by daemon.
### END INIT INFO

########
# ext4 noatime,barrier=0,data=writeback
# xfs  noatime,nobarrier,logbufs=8,logbsize=256k,allocsize=2M
######

thefile='/etc/sysctl.conf'
datum=`date`

##FetchedValuesFromOS
RAMBYTES=`(free -b | grep "Mem:" | awk '{print ($2)}')`
RAMGB=$(($RAMBYTES/1024/1024/1024))

##DynamicValues
SHMMNI=$((256*$RAMGB))
SHMALL=$(((2*$RAMBYTES)/4096))
MSGMNI=$((1024*$RAMGB))

##SetThatShit
echo "#VALUES SET BY SCRIPT $datum" > $thefile
echo "#" >> $thefile
echo "# /etc/sysctl.conf - Configuration file for setting system variables" >> $thefile
echo "# See /etc/sysctl.d/ for additonal system variables" >> $thefile
echo "# See sysctl.conf (5) for information." >> $thefile
echo "#" >> $thefile
echo "" >> $thefile
echo "kernel.shmmni=$SHMMNI" >> $thefile
echo "kernel.shmmax=$RAMBYTES" >> $thefile
echo "kernel.shmall=$SHMALL" >> $thefile
echo "kernel.sem=250 256000 32 $SHMMNI" >> $thefile
echo "kernel.msgmni=$MSGMNI" >> $thefile
echo "kernel.msgmax=65536" >> $thefile
echo "kernel.msgmnb=65536" >> $thefile
echo "kernel.randomize_va_space=0" >> $thefile
echo "kernel.panic=60" >> $thefile
echo "kernel.sysrq=0" >> $thefile
echo "kernel.core_uses_pid=1" >> $thefile
echo "" >> $thefile
echo "net.ipv6.conf.all.disable_ipv6=1" >> $thefile
echo "net.core.rmem_max=134217728" >> $thefile
echo "net.core.wmem_max=134217728" >> $thefile
echo "net.ipv4.tcp_mem=134217728 134217728 134217728" >> $thefile
echo "net.ipv4.tcp_rmem=4096 277750 134217728" >> $thefile
echo "net.ipv4.tcp_wmem=4096 277750 134217728" >> $thefile
echo "net.core.netdev_max_backlog=3240000" >> $thefile
echo "net.core.somaxconn=50000" >> $thefile
echo "net.ipv4.tcp_max_tw_buckets=1440000" >> $thefile
echo "net.ipv4.tcp_max_syn_backlog=3240000 " >> $thefile
echo "net.ipv4.tcp_window_scaling=1" >> $thefile
echo "net.ipv4.tcp_tw_reuse=1" >> $thefile
echo "net.ipv4.tcp_syncookies=1" >> $thefile
echo "" >> $thefile
echo "vm.dirty_background_ratio=10" >> $thefile
echo "vm.dirty_background_bytes=0" >> $thefile
echo "vm.dirty_ratio=20" >> $thefile
echo "vm.dirty_bytes=0" >> $thefile
echo "vm.dirty_writeback_centisecs=500" >> $thefile
echo "vm.dirty_expire_centisecs=3000" >> $thefile
echo "vm.swappiness=0" >> $thefile
echo "vm.overcommit_memory=0" >> $thefile
echo "vm.vfs_cache_pressure=500" >> $thefile
echo "" >> $thefile
echo "fs.file-max=2097152" >> $thefile
echo "fs.inotify.max_user_watches=65536" >> $thefile
echo "fs.mqueue.msg_max=16384" >> $thefile
echo "fs.mqueue.queues_max=4096" >> $thefile
echo "" >> $thefile

##AllDoneReloadSettings
sysctl -p
sleep 2

##SetQueueDepthAndSoOn
policy=noop #noop cfq deadline
read_ahead=16384
queue_depth=1024
iscsi_timeout=180

for disk in ` cd /sys/block;ls -d sd*`
do
        #echo "Configuring $disk with $policy"
        echo "$policy" > /sys/block/$disk/queue/scheduler
        echo "$read_ahead" > /sys/block/$disk/queue/read_ahead_kb
        echo "$queue_depth" > /sys/block/$disk/queue/nr_requests
	echo "$iscsi_timeout" > /sys/block/$disk/device/timeout
done

exit
