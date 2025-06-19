# EASE-Parallels

**External Adapter Support Environment for M1 Macs using Parallels Desktop**

A native Apple Silicon port of [EASE](https://github.com/intuitibits/ease) that enables external USB Wi-Fi adapters in WiFi Explorer Pro and Airtool 2 on M1/M2/M3 Macs using Parallels Desktop instead of VirtualBox.

![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1%20%7C%20M2%20%7C%20M3-blue?style=flat-square)
![Parallels Desktop](https://img.shields.io/badge/Parallels%20Desktop-18%2B-green?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

## 🚀 Why EASE-Parallels?

The original [EASE](https://github.com/intuitibits/ease) project uses VirtualBox, which has significant compatibility issues on Apple Silicon Macs:
- Poor performance under Rosetta 2 emulation
- Unreliable USB passthrough functionality
- Frequent crashes and stability issues

EASE-Parallels solves these problems by leveraging Parallels Desktop's native M1 support for:
- ✅ **Native ARM64 performance** - No emulation needed
- ✅ **Reliable USB passthrough** - Better hardware support
- ✅ **Seamless macOS integration** - Works like a native app
- ✅ **Easy automation** - Single script installation

## 📋 Requirements

- **macOS**: Big Sur 11.0+ (Apple Silicon recommended)
- **Parallels Desktop**: 17.0+ (18.0+ recommended)
- **Memory**: 4GB+ available RAM (8GB+ recommended)
- **Storage**: 10GB+ free disk space
- **Network**: Internet connection for initial setup

## 🛠 Supported Wi-Fi Adapters

All adapters supported by the original EASE project work with EASE-Parallels:

| Adapter | Chipset | Status |
|---------|---------|--------|
| ASUS USB-N53 | Atheros AR9271 | ✅ Tested |
| ALFA AWUS051NH | Atheros AR9271 | ✅ Tested |
| ALFA AWUS036NHA | Atheros AR9271 | ✅ Tested |
| COMFAST CF-912AC | Realtek RTL8812AU | ✅ Tested |
| Edimax EW-7822UAC | Realtek RTL8812AU | ✅ Tested |
| Edimax EW-7833UAC | Realtek RTL8814AU | ✅ Tested |
| MediaTek MT7612U | MediaTek MT7612U | ✅ Compatible |
| TP-Link Compatible | Various | ✅ Most models |

## 🚀 Quick Start

### 1. Install EASE-Parallels

```bash
# Clone the repository
git clone https://github.com/yourusername/ease-parallels.git
cd ease-parallels

# Make the script executable
chmod +x ease-parallels.sh

# Install with default settings
./ease-parallels.sh install
```

### 2. Initial Setup

```bash
# Start the VM (GUI mode for first-time setup)
./ease-parallels.sh start --gui

# Follow the Debian installation wizard
# After OS installation, provision the VM:
./ease-parallels.sh provision
```

### 3. Configure USB Wi-Fi Adapters

```bash
# List available USB devices
./ease-parallels.sh usb --list

# Connect your Wi-Fi adapter via Parallels Desktop:
# Devices > USB & Bluetooth > [Your Wi-Fi Adapter]

# Test adapter functionality
./ease-parallels.sh test
```

### 4. Use with WiFi Explorer Pro

1. Open **WiFi Explorer Pro**
2. Your connected adapters will appear as **pseudo-local sensors**
3. Select the adapter from the scan mode menu
4. Start scanning with external adapter capabilities!

## 📖 Detailed Usage

### Installation Options

```bash
# Custom VM configuration
./ease-parallels.sh install --memory 4096 --cpus 4 --disk 12288

# Headless installation (no GUI)
./ease-parallels.sh install --headless

# Force reinstall (removes existing VM)
./ease-parallels.sh install --force
```

### VM Management

```bash
# Start VM
./ease-parallels.sh start [--headless|--gui]

# Stop VM  
./ease-parallels.sh stop

# Restart VM
./ease-parallels.sh restart

# Check status
./ease-parallels.sh status

# View logs
./ease-parallels.sh logs

# Remove VM completely
./ease-parallels.sh remove [--force]
```

### USB Configuration

```bash
# List connected USB devices
./ease-parallels.sh usb --list

# Enable auto USB connection
./ease-parallels.sh usb --auto

# General USB help
./ease-parallels.sh usb
```

### Troubleshooting

```bash
# Test Wi-Fi adapter detection
./ease-parallels.sh test

# Re-provision VM (fixes software issues)
./ease-parallels.sh provision --verbose

# Update VM settings
./ease-parallels.sh update --memory 4096 --cpus 4

# View detailed logs
./ease-parallels.sh logs
```

## 🔧 Advanced Configuration

### Custom VM Settings

Edit the script variables at the top of `ease-parallels.sh`:

```bash
VM_NAME="EASE-VM"          # VM name in Parallels
VM_MEMORY="2048"           # RAM in MB
VM_CPUS="2"                # CPU cores
VM_DISK_SIZE="8192"        # Disk size in MB
```

### WiFi Explorer Sensor Configuration

The WiFi Explorer sensor runs automatically as a systemd service. Manual configuration:

```bash
# Check sensor status
./ease-parallels.sh exec "systemctl status wifiexplorer-sensor"

# Restart sensor
./ease-parallels.sh exec "systemctl restart wifiexplorer-sensor"

# View sensor logs
./ease-parallels.sh exec "journalctl -u wifiexplorer-sensor -f"
```

### Network Configuration

By default, the VM uses shared networking. For advanced setups:

```bash
# Switch to bridged networking
prlctl set EASE-VM --device-set net0 --type bridged --mac auto

# Configure static IP (inside VM)
./ease-parallels.sh exec "sudo nano /etc/network/interfaces"
```

## 🐛 Troubleshooting

### Common Issues

**VM won't start**
```bash
# Check Parallels Desktop is running
prlctl list

# Verify VM exists
./ease-parallels.sh status

# Recreate VM
./ease-parallels.sh remove --force
./ease-parallels.sh install
```

**USB adapter not detected**
```bash
# Verify adapter is connected to VM (not Mac)
./ease-parallels.sh usb --list

# Reconnect adapter via Parallels Desktop UI
# Devices > USB & Bluetooth > [Your Adapter]

# Check adapter in VM
./ease-parallels.sh test
```

**WiFi Explorer Pro doesn't see adapters**
```bash
# Verify sensor is running
./ease-parallels.sh logs

# Restart WiFi Explorer sensor
./ease-parallels.sh exec "sudo systemctl restart wifiexplorer-sensor"

# Check firewall (if enabled)
./ease-parallels.sh exec "sudo ufw status"
```

### Performance Issues

**Slow VM performance**
```bash
# Increase VM resources
./ease-parallels.sh update --memory 4096 --cpus 4

# Enable hardware acceleration
prlctl set EASE-VM --nested-virt on --pmu-virt on
```

**USB passthrough issues**
```bash
# Disable USB 3.0 for problematic adapters
prlctl set EASE-VM --device-set usb0 --enable off
prlctl set EASE-VM --device-add usb --enable
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

```bash
# Fork and clone
git clone https://github.com/yourusername/ease-parallels.git
cd ease-parallels

# Create feature branch
git checkout -b feature/awesome-feature

# Test your changes
./ease-parallels.sh install --verbose
./ease-parallels.sh test

# Submit pull request
```

### Testing

Before submitting changes, please test with:

```bash
# Test on clean system
./ease-parallels.sh remove --force
./ease-parallels.sh install --verbose

# Test different configurations
./ease-parallels.sh install --memory 1024 --cpus 1
./ease-parallels.sh install --memory 8192 --cpus 8
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Intuitibits](https://www.intuitibits.com/) for the original EASE project and WiFi Explorer Pro
- [Parallels](https://www.parallels.com/) for excellent M1 Mac virtualization
- The open-source community for wireless drivers and tools

## 📚 Related Projects

- [Original EASE](https://github.com/intuitibits/ease) - VirtualBox-based version
- [WiFi Explorer Pro](https://www.intuitibits.com/products/wifi-explorer-pro/) - Professional Wi-Fi scanner
- [Airtool 2](https://www.intuitibits.com/products/airtool/) - Wi-Fi packet capture tool
- [WiFi Explorer Sensor](https://github.com/intuitibits/wifiexplorer-sensor) - Remote sensor implementation

## 📞 Support

- 📖 [Documentation](https://github.com/yourusername/ease-parallels/wiki)
- 🐛 [Issue Tracker](https://github.com/yourusername/ease-parallels/issues)
- 💬 [Discussions](https://github.com/yourusername/ease-parallels/discussions)
- 📧 Email: support@yourproject.com

---

**Made with ❤️ for the WiFi professional community**
