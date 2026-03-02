# IncidentVault - Root Cause Analysis Data Collection Script

## Overview

`IncidentVault` is an automated system diagnostics and data collection script designed to capture comprehensive system information at the moment of a failure. It enables quick Root Cause Analysis (RCA) by gathering critical system metrics, logs, and configuration data in a single execution.

---

## Purpose

When a service or system fails, this script automatically collects:
- **System Information** - Hostname, OS details, uptime, logged-in users
- **Performance Metrics** - CPU, memory, disk I/O, virtual memory statistics
- **Process Details** - Top CPU/memory consuming processes
- **Storage Information** - Disk usage, block devices, mount points
- **Service Status** - Running/failed services, systemd unit status
- **System Logs** - Journal logs, syslog, system messages
- **Package Inventory** - Installed packages (RPM or DEB)

All data is archived into a compressed tarball for easy transport and analysis.

---

## Why This Script Helps RCA

### **1. Immediate Snapshot of System State**
- Captures the exact state of the system at the moment of failure
- Prevents data loss from logs that rotate or are cleared
- Preserves evidence for forensic analysis

### **2. Comprehensive Data Collection**
- Single execution provides end-to-end system view
- No need to manually run multiple diagnostic commands
- Reduces investigation time from hours to minutes

### **3. Performance Context**
- Identifies resource bottlenecks (CPU, memory, I/O)
- Shows which processes consumed most resources during failure
- Helps distinguish between root cause and symptoms

### **4. Service & Log Investigation**
- Lists all failed services at time of failure
- Provides recent system logs and journal entries
- Correlates service failures with system events

### **5. Portability & Archival**
- Creates compressed archive for secure transport
- Easy to store for compliance/audit trails
- Can be copied to central logging/analysis system

### **6. Quick Timeline Reconstruction**
- Provides exact timestamps for all data points
- Enables correlation with monitoring alerts
- Accelerates incident triage

---

## Data Collected

The script creates a timestamped directory with the following files:

```
/tmp/rca_<hostname>_<timestamp>/
├── date.txt                      # Current system date/time
├── uname.txt                     # OS and kernel details
├── uptime.txt                    # System uptime & load average
├── logged_user.txt               # Currently logged-in users
├── lscpu.txt                     # CPU architecture details
├── free_memory.txt               # Memory free/used/available
├── iops.txt                      # Disk I/O statistics
├── vmstat.txt                    # Virtual memory statistics
├── top_cpu_processes.txt         # Top 10 CPU-consuming processes
├── top_mem_processes.txt         # Top 10 memory-consuming processes
├── disk_usage.txt                # Disk utilization (df -h)
├── block_device.txt              # Block device information
├── mounts.txt                    # Mount points and /etc/fstab
├── failed_service.txt            # Failed systemd services
├── running_service.txt           # Running systemd services
├── journal_log.txt               # Last 300 systemd journal entries
├── syslog.txt                    # Last 300 syslog entries (if exists)
├── messages.txt                  # Last 300 /var/log/messages (if exists)
├── installed_packages_rpm.txt    # Installed packages (RPM-based systems)
└── installed_packages_dpkg.txt   # Installed packages (DEB-based systems)

Archive: /tmp/rca_<hostname>_<timestamp>.tar.gz
```

---

## Installation & Setup

### **Step 1: Download the Script**
```bash
wget -O /usr/local/bin/rca_script.sh https://github.com/ManuMahadevu11/IncidentVault/rca_script.sh
# OR
cp rca_script.sh /usr/local/bin/
chmod +x /usr/local/bin/rca_script.sh
```

### **Step 2: Verify Permissions**
```bash
ls -la /usr/local/bin/rca_script.sh
# Should show: -rwxr-xr-x
```

### **Step 3: Test the Script**
```bash
/usr/local/bin/rca_script.sh
# Should complete without errors and create a tarball
```

---

## Configuration Methods

### **Method 1: Manual Execution (On-Demand)**
```bash
/usr/local/bin/rca_script.sh
# OR with custom output path
RCA_OUTPUT_PATH=/var/log/rca /usr/local/bin/rca_script.sh
```

---

### **Method 2: Scheduled Cron Job (Proactive)**

#### **Option A: Daily Collection at Specific Time**
```bash
# Collect RCA data every day at 2 AM
0 2 * * * /usr/local/bin/rca_script.sh >> /var/log/rca_cron.log 2>&1
```

#### **Option B: Hourly Collection**
```bash
# Collect RCA data every hour
0 * * * * /usr/local/bin/rca_script.sh >> /var/log/rca_cron.log 2>&1
```

#### **Option C: Every 30 Minutes**
```bash
# For high-criticality systems
*/30 * * * * /usr/local/bin/rca_script.sh >> /var/log/rca_cron.log 2>&1
```

**To add to crontab:**
```bash
# Edit crontab
crontab -e

# Add one of the lines above
# Save and exit (Ctrl+X, then Y in nano)
```

**Verify cron job:**
```bash
crontab -l
# Should display your scheduled RCA collection
```

---

### **Method 3: Automatic Trigger on Service Failure** 

#### **Option A: Using systemd Timer + Service Failure**

**Step 1: Create a systemd service that triggers RCA on failure**
```bash
sudo tee /etc/systemd/system/rca-on-failure.service > /dev/null <<EOF
[Unit]
Description=RCA Collection Service Failure Trigger
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/rca_script.sh
User=root
StandardOutput=journal
StandardError=journal
EOF
```

**Step 2: Create a systemd timer to monitor your application service**
```bash
sudo tee /etc/systemd/system/nginx.service > /dev/null <<EOF
[Unit]
Description=NGINX Service
After=network.target
OnFailure=rca-on-failure.service

[Service]
Type=forking
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
Restart=on-failure
RestartSec=10
User=appuser
StandardOutput=journal
StandardError=journal
EOF
```

**Step 3: Enable systemd units**
```bash
sudo systemctl daemon-reload
sudo systemctl enable nginx.service
sudo systemctl enable rca-on-failure.service
sudo systemctl start nginx.service
```

---

## Considerations & Best Practices

### **Disk Space**
- Each RCA collection uses ~5-50 MB (before compression)
- Archive is typically 1-5 MB
- For hourly jobs, allocate at least 5 GB for 30 days of data
- Example cleanup script:
```bash
# Keep only last 100 RCA archives
find /tmp -name "rca_*.tar.gz" -type f | sort -r | tail -n +101 | xargs rm -f
```

### **Permissions**
- Script must run as root for full data access
- Consider sudo for non-root cron jobs:
```bash
# In sudoers file (visudo)
svc-monitor ALL=(ALL) NOPASSWD: /usr/local/bin/rca_script.sh
```

### **Performance Impact**
- Collection takes 5-30 seconds depending on system load
- Minimal CPU impact (<5%)
- Suitable for production systems

### **Privacy & Compliance**
- RCA data may contain sensitive information
- Implement proper file permissions: `chmod 600`
- Encrypt archives for transmission: `gpg -c archive.tar.gz`
- Comply with data retention policies

### **Testing**
```bash
# Always test the script in non-production first
bash -x /usr/local/bin/rca_script.sh  # Debug mode
echo $?  # Should return 0 on success
```

---

## Post-Collection Analysis

### **Quick Diagnosis Steps**
```bash
# 1. Extract archive
tar -xzf rca_*.tar.gz

# 2. Check failed services
cat rca_*/failed_service.txt

# 3. Review recent errors
grep -i "error\|fail\|critical" rca_*/journal_log.txt

# 4. Analyze resource exhaustion
cat rca_*/top_cpu_processes.txt
cat rca_*/free_memory.txt
cat rca_*/disk_usage.txt

# 5. Check system events
tail rca_*/syslog.txt
```
