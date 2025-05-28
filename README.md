# Linux Disk Optimization 2.0

Automated, safe, and flexible script to optimize disk, memory, and network parameters on Linux servers. Features backup/restore, logging, performance testing, and multiple optimization levels.

---

> ## Do you really need this? Does it make a difference?
>
> **Short answer:**  
> On most modern Linux systems, default parameters prioritize stability and compatibility—not peak performance for demanding workloads.  
> **You may see real improvements if:**
> - You run database, storage, file or streaming servers with many users or high I/O.
> - You operate servers with a lot of RAM and modern SSD or NVMe disks.
> - You want to maximize throughput or connection handling for specific applications.
>
> **What can change?**
> - Up to 20–50% higher disk throughput on some workloads (e.g. large file transfers, parallel IO).
> - Drastic improvement in handling thousands of simultaneous network connections.
> - More efficient use of available RAM for shared memory and disk caching.
>
> **When is this not needed?**
> - For laptops, desktops or small VMs running standard office/web apps, the benefit is usually minor.
> - On many cloud/VPS platforms, kernel or disk settings may be locked or have minimal effect.
>
> **Summary:**  
> These optimizations are mainly for system administrators and power users running high-demand Linux servers.

---

## Technical background

### Why aren't Linux defaults "optimal" for all workloads?

- **Conservatism:** Linux distributions set kernel, VM, and disk parameters to values that avoid edge-case crashes and work on almost all hardware—from old spinning disks to the latest NVMe.
- **Safety for all:** Default sysctl.conf, disk scheduler, and network buffer settings prevent issues on minimal RAM, virtualized, or embedded systems.
- **Diversity:** Not all workloads are equal—a database server and a desktop need radically different settings.

### What do these kernel and disk settings actually do?

- **Disk scheduler** (e.g., `noop`, `deadline`, `cfq`): Determines how Linux orders and prioritizes read/write requests to disks. For SSD/NVMe, simpler schedulers (like `noop`) are often much faster than legacy (rotating-disk-friendly) algorithms.
- **Read-ahead (`read_ahead_kb`)**: Sets how much data Linux reads in advance per I/O request, which can boost performance for large sequential reads.
- **Queue depth (`nr_requests`)**: Allows more outstanding IO operations in parallel; useful for high-throughput disks.
- **Memory management** (`vm.dirty_ratio`, `vm.swappiness`, etc): Dictates when and how data is written from RAM to disk, and how much RAM is used for caching.
- **Shared memory/semaphores:** Critical for database performance; default values are often too low for modern hardware.
- **Network stack tuning:** Adjusts TCP buffer sizes and queue lengths for servers handling thousands of simultaneous connections.

### Real-world impact

- **Databases (PostgreSQL, MySQL, Oracle):**  
  Properly tuned shared memory, disk scheduler, and dirty page settings can increase transaction throughput, reduce latency, and prevent bottlenecks under heavy load.
- **File and storage servers:**  
  Higher queue depths and more aggressive read-ahead allow higher sustained transfer rates, especially over fast networks and storage backends.
- **Web servers / Proxies:**  
  Tuning TCP stacks and connection queues improves resilience against connection floods and high concurrent loads.

### Is this still relevant in 2024+?

Yes!  
- Linux continues to use safe defaults to avoid support headaches across millions of device types.  
- Data centers, performance-focused SaaS, cloud workloads, and high-end VMs benefit from manual fine-tuning, especially as hardware (NVMe, huge RAM) outpaces default kernel values.
- Automation matters: This script combines best-practice parameters and automatic hardware detection, making it easy to apply (and revert) advanced tuning safely.

---

**Bottom line:**  
If your Linux server is doing "serious" work (data, network, high concurrency), **manual optimization is often still necessary**—and this script makes it safe, repeatable, and reversible.

---

## Contents

- [Purpose](#purpose)
- [What the script does](#what-the-script-does)
- [Features](#features)
- [Requirements & Supported Systems](#requirements--supported-systems)
- [Installation & Usage](#installation--usage)
- [Flags & Levels](#flags--levels)
- [Examples](#examples)
- [Restore & Backup](#restore--backup)
- [Output & Logging](#output--logging)
- [Edge Cases & Tips](#edge-cases--tips)
- [Results & Performance](#results--performance)
- [License](#license)

---

## Purpose

This script aims to maximize I/O performance and optimize kernel, disk, and network parameters for Linux servers with large amounts of RAM and fast disks (e.g., for databases or storage-intensive workloads).

---

## What the script does

- **Backs up system files** before any changes
- **Dynamically optimizes** kernel parameters based on system RAM
- **Tunes disk scheduler and read-ahead** on all `/dev/sd*` disks (skips risky tweaks on VMs)
- **Tunes network and file system parameters** for high concurrency
- **Supports multiple optimization levels** (safe, aggressive, custom)
- **Restore**: easy rollback to the last backup
- **Logs** all actions to `/var/log/linux-disk-optimization.log`
- **Runs performance tests** before/after (with `iozone` if installed)
- **Dry-run** mode: see what would be done, without changing anything

---

## Features

- **Automatic backup & restore** of `/etc/sysctl.conf`
- **Optimization levels:** safe, aggressive, custom
- **Full change logging**
- **Performance tests** (with `iozone` if available)
- **Detects virtual machines** and skips risky optimizations
- **Dry-run** mode for safe simulation
- **Safety checks** (root, dependencies, etc)

---

## Requirements & Supported Systems

### **Supported**
- **Debian/Ubuntu** (tested on kernel 4.x/5.x)
- Physical Linux servers or powerful VMs where disk parameters can be changed
- Must be run as root

### **Not supported / Not tested**
- RedHat/CentOS/Fedora (may require manual tweaks)
- macOS, BSD, WSL
- Virtual/cloud servers where blockdev/IO parameters are locked (some cloud providers)
- Desktop systems (may affect usability and stability!)

---

## Installation & Usage

1. **Clone the repo:**
   ```sh
   git clone https://github.com/Caripson/Linux-disk-optimization.git
   cd Linux-disk-optimization
   ```

2. **Make the script executable:**
   ```sh
   chmod +x runme.sh
   ```

3. **Run the script (as root):**
   ```sh
   sudo ./runme.sh --level=aggressive
   ```

   Or do a dry run:
   ```sh
   sudo ./runme.sh --dry-run
   ```

---

## Flags & Levels

| Flag                | Function                                                             |
|---------------------|----------------------------------------------------------------------|
| `--level=safe`      | Conservative, safe optimization (default)                            |
| `--level=aggressive`| Maximal performance (use at your own risk)                           |
| `--level=custom`    | Manual tuning (requires editing values in the script directly)        |
| `--dry-run`         | Only shows what would be changed, makes no changes                   |
| `--restore`         | Restores the latest backup of `/etc/sysctl.conf`                     |
| `--help`            | Show help and usage examples                                         |

---

## Examples

**Safe optimization:**
```sh
sudo ./runme.sh --level=safe
```

**Aggressive optimization (max performance):**
```sh
sudo ./runme.sh --level=aggressive
```

**Show all planned changes without writing anything:**
```sh
sudo ./runme.sh --dry-run
```

**Restore to the latest backup:**
```sh
sudo ./runme.sh --restore
```

---

## Restore & Backup

- Backups of `/etc/sysctl.conf` are saved with a timestamp in the same directory.
- When using `--restore`, the script replaces your current sysctl.conf with the latest backup.
- **Manual restore:**  
  ```sh
  sudo cp /etc/sysctl.conf.bak.YYYY-MM-DD-HHMMSS /etc/sysctl.conf
  sudo sysctl -p
  ```

---

## Output & Logging

- All actions are logged to `/var/log/linux-disk-optimization.log`.
- Log includes errors and warnings.
- Performance test results (`iozone`) are saved to `/tmp/iozone_test_*.log`.

---

## Edge Cases & Tips

- **Virtual machine:** The script detects VMs and skips disk parameter tuning (can be forced manually).
- **Cloud platforms:** Ensure you have permission to change blockdev/sysctl parameters.
- **IOzone** must be installed manually for benchmarking (`sudo apt-get install iozone3`).
- **Custom sysctl:** In "custom" mode, edit parameter values in the script before running.
- **Multiple runs:** Always make a backup if you are making repeated changes.

---

## Results & Performance

- Performance tests (`iozone`) run before and after optimization and are saved in `/tmp`.
- **Typical improvements may include:**
  - Higher I/O throughput on large file transfers
  - More concurrent connections, improved socket/network performance

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

## Contact / Issues

[Open a GitHub issue](https://github.com/Caripson/Linux-disk-optimization/issues) for problems, bugs, or suggestions!

---

### Screenshot

![Linux Disk Optimization Dashboard](img/Linux-disk-optimization.png)

---
