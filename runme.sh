#!/bin/sh

########
# ext4 noatime,barrier=0,data=writeback
# xfs noatime,nobarrier,logbufs=8,logbsize=256k,allocsize=2M
######


thefile='/etc/sysctl.conf'
datum=`date`

##FetchedValuesFromOS
RAMBYTES=`(cat /proc/meminfo | grep "MemTotal" | awk '{print ($2*1024-1073741824)}')`
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
echo "vm.swappiness=0" >> $thefile
echo "vm.overcommit_memory=0" >> $thefile
echo "net.ipv6.conf.all.disable_ipv6=1" >> $thefile
echo "net.core.rmem_max=134217728" >> $thefile
echo "net.core.wmem_max=134217728" >> $thefile
echo "net.ipv4.tcp_mem=134217728 134217728 134217728" >> $thefile
echo "net.ipv4.tcp_rmem=4096 277750 134217728" >> $thefile
echo "net.ipv4.tcp_wmem=4096 277750 134217728" >> $thefile
echo "net.core.netdev_max_backlog=300000" >> $thefile
echo "vm.dirty_background_ratio=0" >> $thefile
echo "vm.dirty_background_bytes=209715200" >> $thefile
echo "vm.dirty_ratio=40" >> $thefile
echo "vm.dirty_bytes=0" >> $thefile
echo "vm.dirty_writeback_centisecs=100" >> $thefile
echo "vm.dirty_expire_centisecs=200" >> $thefile

##AllDoneReloadSettings
sysctl -p
sleep 5

##SetQueueDepthAndSoOn
policy=noop
read_ahead=8192
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
