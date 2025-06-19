# EASE-UTM

**External Adapter Support Environment for M1 Macs using UTM**

A free, open-source alternative to EASE that enables external USB Wi-Fi adapters in WiFi Explorer Pro and Airtool 2 on M1/M2/M3 Macs using UTM instead of VirtualBox or Parallels.

![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1%20%7C%20M2%20%7C%20M3-blue?style=flat-square)
![UTM](https://img.shields.io/badge/UTM-Free%20%26%20Open%20Source-green?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

## ❓ What is this?

This is a **completely free** version of EASE that uses UTM (based on QEMU) instead of expensive virtualization software. Perfect if you:

- Want to use external USB Wi-Fi adapters with **WiFi Explorer Pro** or **Airtool 2**
- Have an Apple Silicon Mac (M1/M2/M3)
- Don't want to pay for Parallels Desktop
- Prefer open-source solutions

## 🛠 What You Need

1. **A Mac with Apple Silicon** (M1, M2, or M3 chip)
2. **UTM** installed (free - [download here](https://mac.getutm.app/))
3. **WiFi Explorer Pro** or **Airtool 2** ([get them here](https://www.intuitibits.com/))
4. **A compatible USB Wi-Fi adapter** (see list below)
5. **At least 4GB free RAM** and **10GB free disk space**

### Compatible Wi-Fi Adapters

These USB adapters work with EASE-UTM:

- **ASUS USB-N53**
- **ALFA AWUS051NH** / **AWUS036NHA** 
- **COMFAST CF-912AC**
- **Edimax EW-7822UAC** / **EW-7833UAC**
- **TP-Link adapters** with compatible chipsets
- **MediaTek MT7612U** based adapters
- **Realtek RTL8812AU/RTL8814AU** based adapters

## 🚀 Step-by-Step Setup

### Step 1: Install UTM

1. **Download UTM** from [mac.getutm.app](https://mac.getutm.app/)
2. **Open the .dmg file** and drag UTM to Applications
3. **Open UTM** and grant it necessary permissions when prompted

### Step 2: Download and Run the Setup Script

```bash
# Open Terminal and run these commands:

# Download the project
git clone https://github.com/lukeswitz/ease.git
cd ease/UTM/

# Make the script executable
chmod +x ease-utm.sh
```

### Step 3: Create the EASE Virtual Machine

```bash
# Install with default settings (2GB RAM, 2 CPU cores)
./ease-utm.sh install

# OR install with more resources if you have them:
./ease-utm.sh install --memory 4096 --cpus 4
```

This will:
- Download a Debian ARM64 ISO file (~400MB)
- Create a new UTM VM called "EASE-VM"
- Configure it for Wi-Fi adapter use
- Set up USB passthrough

### Step 4: Install Debian Linux

```bash
# Start the VM so you can install Debian
./ease-utm.sh start
```

UTM will open with the VM window. Follow the Debian installer:

1. **Select "Install"** (not Graphical Install)
2. **Choose your language** (English is fine)
3. **Select your location** and **keyboard layout**
4. **Set hostname**: `ease-vm` (or whatever you like)
5. **Set root password**: Choose something secure
6. **Create a user account**: Pick a username and password
7. **Use entire disk** for partitioning (it's a virtual disk, so this is safe)
8. **Install the base system** (this takes 5-10 minutes)
9. **Configure package manager**: Choose a nearby mirror
10. **Skip popularity contest** (say No)
11. **Software selection**: Uncheck everything except "SSH server" and "standard system utilities"
12. **Install GRUB**: Yes, install to `/dev/vda`
13. **Finish installation** and reboot

### Step 5: Set Up Wi-Fi Drivers and Software

After Debian finishes installing and reboots:

```bash
# Install all the Wi-Fi drivers and WiFi Explorer sensor
./ease-utm.sh provision
```

This automatically installs:
- Wireless drivers for your USB adapters
- The WiFi Explorer sensor software
- All necessary dependencies

Wait for this to complete (takes 5-10 minutes).

### Step 6: Connect Your USB Wi-Fi Adapter

1. **Plug your USB Wi-Fi adapter** into your Mac
2. **In UTM**, with your VM selected, click the **USB icon** in the toolbar
3. **Select your Wi-Fi adapter** from the list to connect it to the VM
4. **Verify it worked**:
   ```bash
   ./ease-utm.sh test
   ```

You should see your adapter listed as `wlan0` or similar.

### Step 7: Use with WiFi Explorer Pro

1. **Open WiFi Explorer Pro**
2. **In the toolbar**, click the **Scan Mode** dropdown
3. **Your adapter should appear** as a selectable sensor
4. **Select it** and start scanning!

For **Airtool 2**:
1. **Open Airtool 2**  
2. **EASE should appear** in the sensor list
3. **Select EASE** and choose your adapter (wlan0, wlan1, etc.)
4. **Start packet capture!**

## 🎯 Daily Usage

After initial setup, using EASE-UTM is simple:

```bash
# Start EASE (runs in background)
./ease-utm.sh start

# Check if everything is running
./ease-utm.sh status

# Stop EASE when done
./ease-utm.sh stop
```

The VM will run and your Wi-Fi adapters will be available in WiFi Explorer Pro and Airtool 2.

## 📋 All Available Commands

```bash
# Installation and setup
./ease-utm.sh install [--memory 4096] [--cpus 4] [--headless]
./ease-utm.sh provision

# VM control
./ease-utm.sh start [--headless]
./ease-utm.sh stop
./ease-utm.sh restart
./ease-utm.sh status

# USB and testing
./ease-utm.sh usb [--list|--connect|--disconnect]
./ease-utm.sh test
./ease-utm.sh logs

# Maintenance
./ease-utm.sh update [--memory 4096] [--cpus 4]
./ease-utm.sh remove [--force]
./ease-utm.sh backup [filename]
./ease-utm.sh restore [filename]

# Help
./ease-utm.sh --help
```

## 🐛 Troubleshooting

### "VM won't start"
```bash
./ease-utm.sh status
# Check UTM app is running and VM exists
```

### "Wi-Fi adapter not showing up"
1. Make sure adapter is connected to **VM** in UTM (USB icon in toolbar)
2. Check with: `./ease-utm.sh test`
3. Try reconnecting the adapter in UTM

### "WiFi Explorer Pro doesn't see the adapter"
```bash
# Check if the sensor is running
./ease-utm.sh logs

# Restart the sensor
./ease-utm.sh restart
```

### "VM is slow"
```bash
# Enable hardware acceleration (if available)
./ease-utm.sh update --acceleration

# Give the VM more resources
./ease-utm.sh update --memory 4096 --cpus 4
```

### "USB adapter keeps disconnecting"
This is a known UTM limitation. Try:
```bash
# Use a different USB port
# Try a USB 2.0 hub (some adapters work better through hubs)
# Check UTM's USB settings in the VM configuration
```
## 🔧 UTM-Specific Troubleshooting

### UTM VM Creation Issues

**"VM doesn't appear in UTM after install"**
```bash
# Manually import the .utm file
open ~/ease-utm/*.utm

# Or restart UTM
killall UTM && open -a UTM
```

**"Can't create VM with script"**
1. Create VM manually in UTM:
   - Click "+" in UTM
   - Choose "Virtualize" 
   - Select "Linux"
   - Set name to "EASE-VM"
   - Configure memory and CPU as desired
   - Create a new disk (8GB+)
   - Set CD/DVD to downloaded Debian ISO

### Performance Issues

**"VM is slower than expected"**
```bash
# Try these optimizations:
./ease-utm.sh optimize

# Manual optimizations in UTM:
# 1. Edit VM → System → Enable "Force Multicore"
# 2. QEMU tab → Add arguments: "-smp $(sysctl -n hw.ncpu)"
# 3. Increase memory allocation
```

**"USB passthrough is laggy"**
- Try connecting adapter through a USB 2.0 hub
- Disable USB 3.0 in UTM VM settings
- Use fewer USB devices simultaneously

### SSH and Networking Issues

**"Can't SSH into VM"**
```bash
# Check VM IP in UTM status bar, then:
ssh username@[VM_IP]

# If SSH fails, ensure SSH server is installed in VM:
# (Run this inside the VM console)
sudo apt install openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
```

**"No network connection in VM"**
1. In UTM, edit VM → Network
2. Try different network modes:
   - Shared (default, should work)
   - Bridged (if you need VM to appear on network)
3. Restart VM after changes

### USB Device Issues

**"Wi-Fi adapter not detected"**
1. Verify adapter is connected in UTM USB menu
2. Check adapter compatibility with Linux ARM64
3. Try different USB ports on your Mac
4. Some adapters need specific kernel modules

**"Adapter connects but no wireless interfaces"**
```bash
# SSH into VM and check:
lsusb                    # Should show your adapter
dmesg | grep -i wireless # Check for driver messages
ip link show            # Look for wlan0, wlan1, etc.

# If no wireless interfaces, may need specific drivers
```

### WiFi Explorer Integration Issues

**"Adapter shows in VM but not in WiFi Explorer Pro"**
1. Ensure WiFi Explorer sensor is running:
   ```bash
   # In VM:
   sudo systemctl status wifiexplorer-sensor
   sudo systemctl restart wifiexplorer-sensor
   ```
2. Check firewall settings in VM
3. Restart WiFi Explorer Pro

### UTM App Issues

**"UTM crashes or becomes unresponsive"**
```bash
# Force quit and restart UTM
killall UTM
open -a UTM

# Clear UTM preferences if issues persist
rm ~/Library/Preferences/com.utmapp.UTM.plist
```

**"VM won't start after Mac reboot"**
- UTM VMs don't auto-start like Parallels
- Always use: `./ease-utm.sh start`
- Or manually start in UTM app

### Memory and Storage Issues

**"VM runs out of disk space"**
1. Stop VM
2. In UTM, edit VM → Drives 
3. Resize the main drive
4. Boot from live USB and resize partition with `gparted`

**"Mac runs out of memory"**
```bash
# Reduce VM memory allocation
./ease-utm.sh update --memory 1024

# Or edit manually in UTM
```

## 🚨 Emergency Recovery

**If everything breaks:**

```bash
# Nuclear option - start fresh
./ease-utm.sh remove --force
rm -f debian-*.iso
./ease-utm.sh install

# Or restore from backup
./ease-utm.sh restore my-backup.utm
```

**Backup before major changes:**
```bash
# Always backup working configurations
./ease-utm.sh backup working-config-$(date +%Y%m%d).utm
```

## 🆚 Comparison with Other Solutions

| Feature | VirtualBox (Original EASE) | Parallels Desktop | **UTM (This Project)** |
|---------|---------------------------|-------------------|------------------------|
| **Cost** | Free | $99/year | **✅ Free** |
| **M1 Performance** | ❌ Poor | ✅ Excellent | ✅ Good |
| **USB Reliability** | ❌ Poor | ✅ Excellent | 🔶 Good |
| **Setup Difficulty** | 🔶 Medium | ✅ Easy | ✅ Easy |
| **Open Source** | ✅ Yes | ❌ No | **✅ Yes** |
| **Memory Usage** | ~1GB | ~1-2GB | **~1-1.5GB** |

## 💡 UTM-Specific Tips

### Performance Optimization
```bash
# Enable all performance features
./ease-utm.sh optimize

# This configures:
# - Hardware acceleration
# - Optimal CPU/memory settings  
# - Network performance tuning
```

### Backup and Restore
```bash
# Backup your configured VM
./ease-utm.sh backup my-ease-backup.utm

# Restore from backup
./ease-utm.sh restore my-ease-backup.utm
```

### Multiple Adapters
```bash
# UTM supports multiple USB adapters
# Connect each one individually through the UTM interface
# They'll appear as wlan0, wlan1, wlan2, etc.
```

## ⚠️ Known UTM Limitations

- **USB passthrough** can be less reliable than Parallels
- **Some adapters** may require specific USB configurations
- **Performance** is good but not quite as fast as Parallels
- **3D acceleration** is limited (but not needed for EASE)

## 🔧 Advanced Configuration

### Custom UTM Settings

Edit the VM in UTM directly for advanced configuration:

1. **Select EASE-VM** in UTM
2. **Click Edit** 
3. **Adjust settings** as needed:
   - **System**: CPU cores, memory
   - **Network**: Bridged vs NAT
   - **USB**: Device filters and settings

### Manual WiFi Explorer Sensor Setup

If automatic provisioning fails:

```bash
# SSH into the VM
./ease-utm.sh ssh

# Manual sensor installation
sudo apt update
sudo apt install python3 python3-pip git
git clone https://github.com/intuitibits/wifiexplorer-sensor.git
cd wifiexplorer-sensor
sudo python3 setup.py install
```

## 🤝 Contributing

This project is open source! Help make it better:

1. **Fork this repository**
2. **Create a branch**: `git checkout -b improve-utm-support`
3. **Make your changes** and test them thoroughly
4. **Submit a pull request**

### Testing Checklist

Before submitting changes:
- [ ] Test VM creation and deletion
- [ ] Test USB adapter passthrough
- [ ] Test WiFi Explorer Pro integration
- [ ] Test on different UTM versions
- [ ] Test with different adapter types

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

## 🙏 Credits

- **[UTM Team](https://mac.getutm.app/)** for the excellent free virtualization platform
- **[Intuitibits](https://www.intuitibits.com/)** for WiFi Explorer Pro, Airtool 2, and the original EASE
- **[QEMU Project](https://www.qemu.org/)** for the underlying virtualization technology
- **The Linux wireless community** for driver development

## 🔗 Related Projects

- **[Original EASE](https://github.com/intuitibits/ease)** - VirtualBox version
- **[EASE-Parallels](https://github.com/lukeswitz/ease-parallels)** - Parallels Desktop version
- **[UTM](https://github.com/utmapp/UTM)** - The virtualization platform we use

---

**Questions? Open an [issue](https://github.com/lukeswitz/ease-utm/issues) or start a [discussion](https://github.com/lukeswitz/ease-utm/discussions)!**

**💝 Like this project? Give it a ⭐ and tell your friends!**
