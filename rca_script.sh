#!/bin/bash
echo "Stating the RCA data collection script"

Hostname=$(hostname)
Date=$(date +%Y%m%d_%H%M%s)
rca_output_dir="/tmp/rca_${Hostname}_${Date}"
mkdir -p "$rca_output_dir"

echo "All logs are stored in below path\n $rca_output_dir"

#########################################
# Capture basic details                 #
#########################################

echo "Collecting basic system info...."

date > "$rca_output_dir/date.txt"
uname -a > "$rca_output_dir/uname.txt"
uptime > "$rca_output_dir/uptime.txt"
who -a > "$rca_output_dir/logged_user.txt"

echo "Collecting cpu, memory, network & iops...."

lscpu > "$rca_output_dir/lscpu.txt" 2>1
free -h > "$rca_output_dir/free_memory.txt"
iostat --human > "$rca_output_dir/iops.txt"
vmstat 1 10 > "$rca_output_dir/vmstat.txt"
ps aux --sort=-%cpu | head -n 10 > "$rca_output_dir/top_cpu_processes.txt"
ps aux --sort=-%mem | head -n 10 > "$rca_output_dir/top_mem_processes.txt"

echo "Collecting Disk details....."

df -h > "$rca_output_dir/disk_usage.txt"
lsblk -f > "$rca_output_dir/block_device.txt"
findmnt > "$rca_output_dir/mounts.txt"
cat /etc/fstab >> "$rca_output_dir/mounts.txt"

echo "Collecting service details...."
systemctl --failed > "$rca_output_dir/failed_service.txt"
systemctl list-units --type=service --state=running > "$rca_output_dir/running_service.txt"

echo "Collecting journal logs..."
journalctl -n 300 --no-pager > "$rca_output_dir/journal_log.txt"
if [ -f /var/log/syslog ]; then
    tail -n 300 /var/log/syslog > "$rca_output_dir/syslog.txt"
fi

if [ -f /var/log/messages ]; then
    tail -n 300 /var/log/messages > "$rca_output_dir/messages.txt"
fi


echo "Collecting packages installed...."
if command -v rpm >/dev/null 2>&1; then
	rpm -qa | sort > "$rca_output_dir/installed_packages_rpm.txt"
elif command -v dpkg >/dev/null 2>&1; then
	dpkg -l > "$rca_output_dir/installed_packages_dpkg.txt"
fi

echo "Creating an tar archive...."
tar -czf "${rca_output_dir}.tar.gz" -C /tmp "$(basename "$rca_output_dir")"
echo "Archive created at: ${rca_output_dir}.tar.gz"
exit 0
